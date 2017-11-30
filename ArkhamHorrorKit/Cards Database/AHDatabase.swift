//
//  CardsDatabase.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 18/10/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

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
}

public final class AHDatabase {
    public private(set) var dbQueue: DatabaseQueue
    
    private var _cardCycles: [String: CardCycle]?
    private var _cardPacks: [String: CardPack]?
    private var _traits: Set<String>?
    private var _investigators: [Int: Investigator]?
    
    public private(set) var cardStore: CardsStore!
    public private(set) var deckStore: DeckStore!
    
    public init(path: String) throws {
        dbQueue = try DatabaseQueue(path: path)
        
        try migrateToLastVersion()
    }
    
    /// Creates an in-memory database
    ///
    /// - Throws: AHDatabaseError
    public init() throws {
        dbQueue = DatabaseQueue()
        
        try migrateToLastVersion()
    }
    
    public func updateDatabaseFromJSONFilesInDirectory(url: URL) throws {
        var files = try FileManager.default.contentsOfDirectory(atPath: url.path)
        
        // Try loading cycles first if exists
        if let index = files.index(of: "cycles.json") {
            try loadCyclesFromJSON(at: url.appendingPathComponent("cycles.json"))
            
            files.remove(at: index)
        }
        
        // Try loading cycles first if exists
        if let index = files.index(of: "packs.json") {
            try loadPacksFromJSON(at: url.appendingPathComponent("packs.json"))
            
            files.remove(at: index)
        }
        
        // Load all files (ignore files that don't contain cards)
        for file in files {
            do {
                try loadCardsAndInvestigatorsFromJSON(at: url.appendingPathComponent(file))
            } catch CardRecord.CardError.jsonDoesNotContainCards {
                continue
            } catch {
                throw error
            }
        }
    }
    
    public func loadCyclesFromJSON(at url: URL) throws {
        try loadJSON(at: url, handler: { (db, json) in
            try CardCycleRecord.loadJSONRecords(json: json, into: db)
        })
    }
    
    public func loadPacksFromJSON(at url: URL) throws {
        try loadJSON(at: url, handler: { (db, json) in
            try CardPackRecord.loadJSONRecords(json: json, into: db)
        })
    }
    
    /// Loads cards and investigators from a json file
    ///
    /// *Note*: Throws an error when trying to load a card from a pack that doesn't exist.
    /// Please make sure to load packs.json first.
    /// - Parameter url: JSON url
    /// - Throws: error
    public func loadCardsAndInvestigatorsFromJSON(at url: URL) throws {
        try loadJSON(at: url) { (db, json) in
            try InvestigatorRecord.loadJSONRecords(json: json, into: db)
            try CardRecord.loadJSONRecords(json: json, into: db)
        }
    }
    
    private func updateStores() throws {
        // Invalidate cached values
        _cardCycles = nil
        _cardPacks = nil
        _traits = nil
        _investigators = nil
        
        cardStore = CardsStore(dbWriter: dbQueue,
                               cycles: try cardCyclesDictionary(),
                               packs: try cardPacksDictionary(),
                               traits: try traitsSet(),
                               investigators: try investigatorsDictionary())
        deckStore = DeckStore(dbWriter: dbQueue, cardStore: cardStore)
    }
    
    private func migrateToLastVersion() throws {
        try AHDatabaseMigrator().migrate(database: dbQueue)
        
        try updateStores()
    }
    
    // MARK:- CardCycle
    public func cardCyclesDictionary() throws -> [String: CardCycle] {
        if _cardCycles == nil {
            _cardCycles = try dbQueue.read({ (db) -> [String: CardCycle] in
                let records = try CardCycleRecord.fetchAll(db)
                
                var cycles = [String: CardCycle]()
                
                records.forEach({ (record) in
                    let cycle = CardCycle(id: record.id,
                                          name: record.name,
                                          position: record.position,
                                          size: record.size)
                    
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
                    
                    let pack = CardPack(id: record.id,
                                        name: record.name,
                                        position: record.position,
                                        size: record.size,
                                        cycle: cycle)
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
                    
                    let cardRecords = try CardRecord.fetchAll(db: db, ids: requiredIds.keys.sorted())
                    
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
    private func loadJSON(at url: URL, handler: (Database, JSON) throws -> ()) throws {
        var shouldUpdateStores = false
        
        try dbQueue.inTransaction { (db) -> Database.TransactionCompletion in
            let data = try Data(contentsOf: url)
            let dataChecksum = CryptoHelper.sha256Hex(data: data)
            
            let filename = url.lastPathComponent
            
            guard filename.count > 0 else { return Database.TransactionCompletion.rollback }
            
            if let record = try FileChecksumRecord.fetchOne(db: db, filename: filename) {
                // Don't load the json file if checksums are equal
                if record.hex == dataChecksum {
                    return Database.TransactionCompletion.rollback
                }
            }
            
            let json = JSON(data: data)
            
            try handler(db, json)
            
            let record = FileChecksumRecord(filename: filename, hex: dataChecksum)
            try record.save(db)
            
            shouldUpdateStores = true
            
            return Database.TransactionCompletion.commit
        }
        
        if shouldUpdateStores {
            try updateStores()
        }
    }
}
