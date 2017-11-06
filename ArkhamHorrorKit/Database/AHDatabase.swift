//
//  CardsDatabase.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 18/10/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import GRDB

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
    public private(set) var dbWriter: DatabaseWriter
    
    private var _cardCycles: [String: CardCycle]?
    private var _cardPacks: [String: CardPack]?
    private var _investigators: [Int: Investigator]?
    
    public private(set) var cardStore: CardsStore!
    public private(set) var deckStore: DeckStore!
    
    public init(path: String) throws {
        dbWriter = try DatabaseQueue(path: path)
        
        try migrateToLastVersion()
    }
    
    
    /// Creates an in-memory database
    ///
    /// - Throws: AHDatabaseError
    public init() throws {
        dbWriter = DatabaseQueue()
        
        try migrateToLastVersion()
    }
    
    private func updateStores() throws {
        cardStore = CardsStore(dbWriter: dbWriter,
                               cycles: try cardCyclesDictionary(),
                               packs: try cardPacksDictionary(),
                               investigators: try investigatorsDictionary())
        deckStore = DeckStore(dbWriter: dbWriter, cardStore: cardStore)
    }
    
    private func migrateToLastVersion() throws {
        try AHDatabaseMigrator().migrate(database: dbWriter)
        
        // Invalidate cached values
        _cardCycles = nil
        _cardPacks = nil
        _investigators = nil
        
        try updateStores()
    }
    
    // MARK:- CardCycle
    public func cardCyclesDictionary() throws -> [String: CardCycle] {
        if _cardCycles == nil {
            _cardCycles = try dbWriter.read({ (db) -> [String: CardCycle] in
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
            
            _cardPacks = try dbWriter.read({ (db) -> [String: CardPack] in
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
    
    // MARK:- Investigator
    public func investigatorsDictionary() throws -> [Int: Investigator] {
        if _investigators == nil {
            var packs = try cardPacksDictionary()
            
            _investigators = try dbWriter.read({ (db) -> [Int: Investigator] in
                let records = try InvestigatorRecord.fetchAll(db)
                
                var investigators = [Int: Investigator]()
                
                try records.forEach({ (record) in
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
                                                    illustrator: record.illustrator)
                    
                    investigators[investigator.id] = investigator
                })
                
                return investigators
            })
        }
        
        return _investigators!
    }
    
    public func investigators() throws -> [Investigator] {
        return Array(try investigatorsDictionary().values)
    }
}
