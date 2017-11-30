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
    
    struct CardIdQuantityPair {
        var cardId: Int
        var quantity: Int
        
        init(_ cardId: Int, _ quantity: Int) {
            self.cardId = cardId
            self.quantity = quantity
        }
    }
    
    static func createDeck(name: String, investigatorId: Int, in database: AHDatabase) -> Deck {
        return try! database.deckStore.createDeck(name: "The God Killer", investigatorId: investigatorId)
    }
    
    static func createDeck(name: String, investigator: Investigator,  in database: AHDatabase) -> Deck {
        return createDeck(name: name, investigatorId: investigator.id, in: database)
    }
    
    @discardableResult
    static func createDeck(name: String, investigatorId: Int, cards: [CardIdQuantityPair], in database: AHDatabase) -> Deck {
        var deck = DatabaseTestsHelper.createDeck(name: name, investigatorId: investigatorId, in: database)
        
        for c in cards {
            let card = try! database.cardStore.fetchCard(id: c.cardId)
            
            deck = try! database.deckStore.changeCardQuantity(deck: deck, card: card, quantity: c.quantity)
        }
        
        return deck
    }
    
    @discardableResult
    static func createDeck(name: String, investigator: Investigator, cards: [CardIdQuantityPair], in database: AHDatabase) -> Deck {
        return createDeck(name: name, investigatorId: investigator.id, cards: cards, in: database)
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
