//
//  CardsDatabase.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 18/10/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import GRDB

enum AHDatabaseError: Error {
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

// TODO: put all models and database related classes into its own module
final class AHDatabase {
    private(set) var dbPool: DatabasePool
    
    private var _cardCycles: [String: CardCycle]?
    private var _cardPacks: [String: CardPack]?
    private var _investigators: [Int: Investigator]?
    
    private(set) var cardStore: CardsStore!
    private(set) var deckStore: DeckStore!
    
    init(path: String) throws {
        dbPool = try DatabasePool(path: path)
        
        try updateStores()
    }
    
    private func updateStores() throws {
        cardStore = CardsStore(dbPool: dbPool,
                                 cycles: try cardCyclesDictionary(),
                                 packs: try cardPacksDictionary(),
                                 investigators: try investigatorsDictionary())
        deckStore = DeckStore(dbPool: dbPool, cardStore: cardStore)
    }
    
    func migrateToLastVersion() throws {
        try AHDatabaseMigrator().migrate(database: dbPool)
        
        // Invalidate cached values
        _cardCycles = nil
        _cardPacks = nil
        _investigators = nil
        
        try updateStores()
    }
    
    // MARK:- CardCycle
    func cardCyclesDictionary() throws -> [String: CardCycle] {
        if _cardCycles == nil {
            _cardCycles = try dbPool.read({ (db) -> [String: CardCycle] in
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
    
    func cardCycles() throws -> [CardCycle] {
        return Array(try cardCyclesDictionary().values)
    }
    
    // MARK:- CardPack
    func cardPacksDictionary() throws -> [String: CardPack] {
        if _cardPacks == nil {
            var cycles = try cardCyclesDictionary()
            
            _cardPacks = try dbPool.read({ (db) -> [String: CardPack] in
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
    
    func cardPacks() throws -> [CardPack] {
        return Array(try cardPacksDictionary().values)
    }
    
    // MARK:- Investigator
    func investigatorsDictionary() throws -> [Int: Investigator] {
        if _investigators == nil {
            var packs = try cardPacksDictionary()
            
            _investigators = try dbPool.read({ (db) -> [Int: Investigator] in
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
    
    func investigators() throws -> [Investigator] {
        return Array(try investigatorsDictionary().values)
    }
}
