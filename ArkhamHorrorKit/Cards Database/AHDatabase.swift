//  Copyright © 2017 Tiago Bras. All rights reserved.

import GRDB
import SwiftyJSON
import TBSwiftKit

public enum AHDatabaseError: Error {
    case cardNotFound(Int)
    case cycleNotFound(String)
    case assetSlotNotFound(Int)
    case typeNotFound(Int)
    case subtypeNotFound(Int)
    case investigatorNotFound(Int)
    case packNotFound(String)
    case invalidCardFactionId(Int)
    case couldNotMakeCardFromRecord(Int)
    case deckNotFound(Int)
    case couldNotHashJSONFiles
    case couldNotHashImages
    case invalidChecksums
    case invalidURLTaskData
    case httpStatusCode(Int)
    case couldNotChecksum
    case invalidReport
    case invalidUrls
    case deckHasNoDefinedId
    case databaseVersionNotDefined
}

public final class AHDatabase {
    public private(set) var dbQueue: DatabaseQueue
    
    private var _cardCycles: [String: CardCycle]?
    private var _cardPacks: [String: CardPack]?
    private var _traits: Set<String>?
    private var _investigators: [Int: Investigator]?
    
    public private(set) var cardStore: CardsStore!
    public private(set) var deckStore: DeckStore!
    
    public private(set) var dbVersion: AHDatabaseMigrator.MigrationVersion = .v1
    
    var RightCardRecord: CardRecord.Type {
        if dbVersion == .v2 {
            return CardRecordV2.self
        } else {
            return CardRecord.self
        }
    }
    
    public init(path: String, upToVersion version: AHDatabaseMigrator.MigrationVersion? = nil) throws {
        dbQueue = try DatabaseQueue(path: path)
        
        try setup(version: version)
    }
    
    /// Creates an in-memory database
    ///
    /// - Throws: AHDatabaseError
    public init(upToVersion version: AHDatabaseMigrator.MigrationVersion? = nil) throws {
        dbQueue = DatabaseQueue()
        
        try setup(version: version)
    }
    
    private func setup(version: AHDatabaseMigrator.MigrationVersion? = nil) throws {
        let migrator = AHDatabaseMigrator()
        
        if let version = version {
            try migrator.migrate(database: dbQueue, upTo: version)
        } else {
            try migrator.migrate(database: dbQueue)
        }
        
        guard let version = migrator.currentVersion else {
            throw AHDatabaseError.databaseVersionNotDefined
        }
        
        dbVersion = version
        
        try updateStores()
    }
    
    
    /// Cleans up unnecessary rows, for instance, DeckCardRecords with quantity = 0
    ///
    /// - Throws: Error
    func cleanUp() throws {
        try dbQueue.write { db in
            try db.execute("DELETE FROM \(DeckCardRecord.databaseTableName) WHERE quantity = 0")
        }
    }
    
    public func getAllJsonFilesChecksums() throws -> [String: String] {
        return try dbQueue.read { (db) -> [String: String] in
            let records = try FileChecksumRecord.fetchAll(db)
            
            var checksumMap = [String: String]()
            
            records.forEach({ (record) in
                checksumMap[record.filename] = record.hex
            })
            
            return checksumMap
        }
    }
    
    public func getAllJsonFilesChecksums(completion: @escaping ([String: String]?, Error?) -> ()) {
        DispatchQueue.global().async {
            do {
                let result = try self.getAllJsonFilesChecksums()
                
                completion(result, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    public func generalInfoJsonChecksum() throws -> String {
        return try dbQueue.read({ (db) -> String in
            return try GeneralInfo.fetchUniqueRow(db: db).jsonFilesChecksum
        })
    }
    
    public func deleteAllSavedFileChecksums() throws {
        try dbQueue.write { db in
            try FileChecksumRecord.deleteAll(db)
            
            // Reset general info as well
            let info = try GeneralInfo.fetchUniqueRow(db: db)
            info.jsonFilesChecksum = ""
            
            if info.hasPersistentChangedValues {
                try info.save(db)
            }
        }
    }
    
    private var server: DatabaseServer?
    public func isUpdateAvailable(serverDomain: URL,
                                  authenticationToken: String,
                                  completion: @escaping (Bool?, Error?) -> ()) {
        DispatchQueue.global().async { [weak self] in
            do {
                self?.server = DatabaseServer(domain: serverDomain, authenticationToken: authenticationToken)
                
                guard let info = try self?.dbQueue.read({ (db) -> GeneralInfo in
                    return try GeneralInfo.fetchUniqueRow(db: db)
                }) else { return }
                
                self?.server?.checkUpdates(
                    jsonChecksum: info.jsonFilesChecksum,
                    imagesChecksum: nil,
                    completion: { (report, error) in
                        if let error = error {
                            return completion(nil, error)
                        }
                        
                        guard let report = report else {
                            return completion(nil, AHDatabaseError.invalidReport)
                        }
                        
                        completion(report.jsonFilesUpdateAvailable, nil)
                })
            } catch {
                completion(nil, error)
            }
        }
    }
    
    private var fileBatchDownloader: FileBatchDownload?
    public func updateDatabase(serverDomain: URL,
                               authenticationToken: String,
                               jsonLocalDirectory: URL,
                               completion: @escaping (Error?) -> ()) {
        DispatchQueue.global().async { [weak self] in
            do {
                self?.server = DatabaseServer(domain: serverDomain, authenticationToken: authenticationToken)
                
                guard let checksums = try self?.dbQueue.read({ (db) -> [String: String] in
                    let records = try FileChecksumRecord.fetchAll(db)
                    
                    var checksums = [String: String]()
                    
                    records.forEach({ (record) in
                        checksums[record.filename] = record.hex
                    })
                    
                    return checksums
                }) else { return }
                
                self?.server?.checkUpdatedJsonFiles(jsonFilesChecksums: checksums) { (urls, error) in
                    if let error = error {
                        return completion(error)
                    }
                    
                    guard let urls = urls else {
                        return completion(AHDatabaseError.invalidUrls)
                    }
                    
                    self?.fileBatchDownloader = FileBatchDownload(
                        files: urls,
                        storeIn: jsonLocalDirectory,
                        progress: nil,
                        completion: { (report, error) in
                            if let error = error {
                                return completion(error)
                            }
                            
                            do {
                                var urls = report.filesDownloaded
                                
                                // Load cycles.json first
                                if let index = urls.index(where: { $0.lastPathComponent == "cycles.json" }) {
                                    let url = urls.remove(at: index)
                                    
                                    try self?.loadCyclesFromJSON(at: url)
                                }
                                
                                // Load packs.json second
                                if let index = urls.index(where: { $0.lastPathComponent == "packs.json" }) {
                                    let url = urls.remove(at: index)
                                    
                                    try self?.loadPacksFromJSON(at: url)
                                }

                                for url in urls {
                                    let components = url.lastPathComponent.split(separator: ".")
                                    
                                    guard components.count == 2 else { continue }
                                    
                                    let packId = String(components[0])
                                    
                                    if let packExists = try self?.dbQueue.read({ (db) -> Bool in
                                        return try CardPackRecord.fetchOne(db: db, id: packId) != nil
                                    }), packExists {
                                        try self?.loadCardsAndInvestigatorsFromJSON(at: url)
                                    }
                                }
                                
                                completion(nil)
                            } catch {
                                completion(error)
                            }
                    })
                    
                    do {
                        try self?.fileBatchDownloader?.startDownload()
                    } catch {
                        completion(error)
                    }
                }
            } catch {
                completion(error)
            }
        }
    }
    
    public func updateDatabaseFromJSONFilesInDirectory(url: URL) throws {
        let checksums = try self.getAllJsonFilesChecksums()
        var urls = FileManager.default.contentsOf(directory: url, fileExtension: "json")
        
        // Try loading cycles first if exists
        if let index = urls.index(where: { $0.lastPathComponent == "cycles.json" }) {
            let res = try JSONLoader.load(url: urls[index])
            
            if let actual = checksums["cycles.json"], actual == res.checksum {
                
            } else {
                try self.loadCyclesFromJSON(at: urls[index])
            }
            
            urls.remove(at: index)
        }
        
        // Try loading cycles first if exists
        if let index = urls.index(where: { $0.lastPathComponent == "packs.json" }) {
            let res = try JSONLoader.load(url: urls[index])
            
            if let actual = checksums["packs.json"], actual == res.checksum {
                
            } else {
                try self.loadPacksFromJSON(at: urls[index])
            }
            
            urls.remove(at: index)
        }
        
        // Load all files (ignore files that don't contain cards)
        for url in urls {
            do {
                try self.loadCardsAndInvestigatorsFromJSON(at: url)
            } catch CardRecord.CardError.jsonDoesNotContainCards {
                continue
            } catch {
                throw error
            }
        }
    }
    
    public func updateDatabaseFromJSONFilesInDirectory(url: URL, completion: @escaping (Error?) -> ()) {
        DispatchQueue.global().async { [weak self] in
            do {
                try self?.updateDatabaseFromJSONFilesInDirectory(url: url)
                
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func loadCyclesFromJSON(at url: URL) throws {
        try loadJSON(at: url, handler: { (db, res) in
            try CardCycleRecord.loadJSONRecords(json: res.json, into: db)
        })
    }
    
    public func loadPacksFromJSON(at url: URL) throws {
        try loadJSON(at: url, handler: { (db, res) in
            try CardPackRecord.loadJSONRecords(json: res.json, into: db)
        })
    }
    
    /// Loads cards and investigators from a json file
    ///
    /// *Note*: Throws an error when trying to load a card from a pack that doesn't exist.
    /// Please make sure to load packs.json first.
    /// - Parameter url: JSON url
    /// - Throws: error
    public func loadCardsAndInvestigatorsFromJSON(at url: URL) throws {
        try loadJSON(at: url) { (db, res) in
            try InvestigatorRecord.loadJSONRecords(json: res.json, into: db)
            try self.RightCardRecord.loadJSONRecords(json: res.json, into: db)
        }
    }
    
    private func updateStores() throws {
        // Invalidate cached values
        _cardCycles = nil
        _cardPacks = nil
        _traits = nil
        _investigators = nil
        
        if let cardStore = cardStore {
            cardStore.dbWriter = dbQueue
            cardStore.cardCycles = try cardCyclesDictionary()
            cardStore.cardPacks = try cardPacksDictionary()
            cardStore.traits = try traitsSet()
            cardStore.investigators = try investigatorsDictionary()
        } else {
            cardStore = CardsStore(dbWriter: dbQueue,
                                   cycles: try cardCyclesDictionary(),
                                   packs: try cardPacksDictionary(),
                                   traits: try traitsSet(),
                                   investigators: try investigatorsDictionary(),
                                   dbVersion: dbVersion)
        }
        
        if let deckStore = deckStore {
            deckStore.dbWriter = dbQueue
            deckStore.cardStore = cardStore
        } else {
            deckStore = DeckStore(dbWriter: dbQueue, cardStore: cardStore)
        }
    }
    
    // MARK:- CardCycle
    public func cardCyclesDictionary() throws -> [String: CardCycle] {
        if _cardCycles == nil {
            _cardCycles = try dbQueue.read({ (db) -> [String: CardCycle] in
                let records = try CardCycleRecord.fetchAll(db)
                
                var cycles = [String: CardCycle]()
                
                try records.forEach({ (record) in
                    let cardTable = CardRecord.databaseTableName
                    let packTable = CardPackRecord.databaseTableName
                    let sql = """
                    SELECT Count(*) FROM \(cardTable)
                    INNER JOIN \(packTable) ON \(packTable).id = \(cardTable).pack_id
                    WHERE \(packTable).cycle_id = '\(record.id)'
                    """
                    
                    let count = try Int.fetchOne(db, sql)
                    
                    let cycle = CardCycle(id: record.id,
                                          name: record.name,
                                          position: record.position,
                                          size: record.size,
                                          cardsCount: count ?? 0)
                    
                    cycles[cycle.id] = cycle
                })
                
                return cycles
            })
        }
        
        return _cardCycles!
    }
    
    public func cardCycles() throws -> [CardCycle] {
        return Array(try cardCyclesDictionary().values)
    }
    
    // MARK:- CardPack
    public func cardPacksDictionary() throws -> [String: CardPack] {
        if _cardPacks == nil {
            var cycles = try cardCyclesDictionary()
            
            _cardPacks = try dbQueue.read({ (db) -> [String: CardPack] in
                let records = try CardPackRecord.fetchAll(db)
                
                var packs = [String: CardPack]()
                
                try records.forEach({ (record) in
                    guard let cycle = cycles[record.cycleId] else {
                        throw AHDatabaseError.cycleNotFound(record.cycleId)
                    }
                    
                    let table = CardRecord.databaseTableName
                    let sql = "SELECT COUNT(*) FROM \(table) WHERE pack_id = '\(record.id)'"
                    let count = try Int.fetchOne(db, sql)
                    
                    let pack = CardPack(id: record.id,
                                        name: record.name,
                                        position: record.position,
                                        size: record.size,
                                        cycle: cycle,
                                        cardsCount: count ?? 0)
                    packs[pack.id] = pack
                })
                
                return packs
            })
        }
        
        return _cardPacks!
    }
    
    public func cardPacks() throws -> [CardPack] {
        return Array(try cardPacksDictionary().values)
    }
    
    // MARK:- Traits
    public func traitsSet() throws -> Set<String> {
        if _traits == nil {
            _traits = try dbQueue.read({ (db) -> Set<String> in
                let records = try TraitRecord.fetchAll(db)
                
                var traits = Set<String>()
                
                records.forEach({ (record) in
                    traits.insert(record.name)
                })
                
                return traits
            })
        }
        
        return _traits!
    }
    
    public func traits() throws -> [String] {
        return try traitsSet().sorted()
    }
    
    // MARK:- Investigator
    public func investigatorsDictionary() throws -> [Int: Investigator] {
        if _investigators == nil {
            var packs = try cardPacksDictionary()
            
            var investigators = try dbQueue.read({ (db) -> [Investigator] in
                let records = try InvestigatorRecord.fetchAll(db)
                
                return try records.map({ (record) in
                    guard let faction = CardFaction(rawValue: record.factionId) else {
                        throw AHDatabaseError.invalidCardFactionId(record.factionId)
                    }
                    
                    guard let pack = packs[record.packId] else {
                        throw AHDatabaseError.packNotFound(record.packId)
                    }
                    
                    let investigator = Investigator(id: record.id,
                                                    name: record.name,
                                                    subname: record.subname,
                                                    faction: faction,
                                                    health: record.health,
                                                    sanity: record.sanity,
                                                    frontText: record.frontText,
                                                    backText: record.backText,
                                                    pack: pack,
                                                    agility: record.agility,
                                                    combat: record.combat,
                                                    intellect: record.intellect,
                                                    willpower: record.willpower,
                                                    position: record.position,
                                                    traits: record.traits,
                                                    frontFlavor: record.frontFlavor,
                                                    backFlavor: record.backFlavor,
                                                    illustrator: record.illustrator,
                                                    requiredCards: [])
                    
                    return investigator
                })
            })
            
            try dbQueue.read({ (db) -> () in
                let packs = try cardPacksDictionary()
                
                for i in 0..<investigators.count {
                    let requiredIds = Investigator.requiredCardsIds(investigatorId: investigators[i].id)
                    
                    let cardRecords = try self.RightCardRecord.fetchAllCards(db: db, ids: requiredIds.keys.sorted())
                    
                    let cards = try cardRecords.flatMap({ (record) -> DeckCard? in
                        guard let pack = packs[record.packId] else {
                            throw AHDatabaseError.packNotFound(record.packId)
                        }
                        
                        let traits = try CardTraitRecord.fetchCardTraits(
                            db: db,
                            cardId: record.id).map({ $0.traitName })
                        
                        if let card = try CardsStore.makeCard(record: record,
                                                              pack: pack,
                                                              traits: traits,
                                                              investigator: investigators[i],
                                                              cardsCache: nil),
                            let quantity = requiredIds[card.id] {
                            
                            return DeckCard(card: card, quantity: quantity)
                        } else {
                            return nil
                        }
                    })
                    
                    investigators[i].requiredCards = cards
                }
                
            })
            
            _investigators = [Int: Investigator]()
            
            investigators.forEach({ (investigator) in
                _investigators![investigator.id] = investigator
            })
        }
        
        return _investigators!
    }
    
    public func investigators() throws -> [Investigator] {
        return Array(try investigatorsDictionary().values)
    }
    
    // MARK:- Private methods
    private func loadJSON(
        at url: URL,
        handler: @escaping (Database, JSONLoader.JSONLoaderResults) throws -> ()) throws {
        var shouldUpdateStores = false

        try dbQueue.inTransaction { (db) -> Database.TransactionCompletion in
            let results = try JSONLoader.load(url: url)
            
            try handler(db, results)
            
            let record = FileChecksumRecord(filename: results.filename, hex: results.checksum)
            
            if record.hasPersistentChangedValues {
                try record.save(db)
                
                shouldUpdateStores = true
                
                let combinedHash = try FileChecksumRecord.fetchAll(db)
                    .sorted()
                    .map({ r -> String in r.hex })
                    .joined(separator: "")
                
                guard let checksum = CryptoHelper.sha256Hex(string: combinedHash) else {
                    throw AHDatabaseError.couldNotChecksum
                }
                
                let info = try GeneralInfo.fetchUniqueRow(db: db)
                
                info.jsonFilesChecksum = checksum
                
                if info.hasPersistentChangedValues {
                    try info.save(db)
                }
            }

            return Database.TransactionCompletion.commit
        }
    
        if shouldUpdateStores {
            try updateStores()
        }
    }
}
