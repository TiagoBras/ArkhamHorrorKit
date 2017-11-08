//
//  DatabaseTestsHelper.swift
//  ArkhamHorrorCompanionTests
//
//  Created by Tiago Bras on 22/10/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation

@testable import ArkhamHorrorKit
@testable import GRDB

final class DatabaseTestsHelper {
    static func inReadOnly(dbVersion: AHDatabaseMigrator.MigrationVersion?,  _ handler: (Database) throws -> ()) rethrows {
        let dbQueue = DatabaseQueue()
        
        try! AHDatabaseMigrator().migrate(database: dbQueue, upTo: dbVersion)
        
        try! dbQueue.read({ (db) in
            try handler(db)
        })
    }
    
    typealias CardIdQuantityPair = (cardId: Int, quantity: Int)
    
    static func createDeck(name: String, investigator: Investigator,  in database: AHDatabase) -> Deck {
        return try! database.deckStore.createDeck(name: "The God Killer", investigator: investigator)
    }
    
    static func createDeck(name: String, investigator: Investigator, cards: [CardIdQuantityPair], in database: AHDatabase) -> Deck {
        var deck = DatabaseTestsHelper.createDeck(name: name, investigator: investigator, in: database)
        
        for (cardId, quantity) in cards {
            let card = try! database.cardStore.fetchCard(id: cardId)
            
            deck = try! database.deckStore.changeCardQuantity(deck: deck, card: card, quantity: quantity)
        }
        
        return deck
    }
    
    static func fetchCard(id: Int, in database: AHDatabase) -> Card {
        return try! database.cardStore.fetchCard(id: id)
    }
    
    static func update(deck: Deck, cardId: Int, quantity: Int, in database: AHDatabase) -> Deck {
        return try! database.deckStore.changeCardQuantity(
            deck: deck,
            card: DatabaseTestsHelper.fetchCard(id: cardId, in: database),
            quantity: quantity)
    }
}
