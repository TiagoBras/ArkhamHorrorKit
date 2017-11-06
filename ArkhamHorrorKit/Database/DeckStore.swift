//
//  DecksStore.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 23/10/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import GRDB

public final class DeckStore {
    private let dbWriter: DatabaseWriter
    private let cardStore: CardsStore
    
    public init(dbWriter: DatabaseWriter, cardStore: CardsStore) {
        self.dbWriter = dbWriter
        self.cardStore = cardStore
    }
    
    public func createDeck(name: String, investigator: Investigator) throws -> Deck {
        return try dbWriter.write({ (db) -> Deck in
            let record = DeckRecord(investigatorId: investigator.id, name: name)
            
            try record.save(db)
            
            return try makeDeck(record: record, deckCards: Set())
        })
    }
    
    public func deleteDeck(_ deck: Deck) throws {
        try dbWriter.write({ (db) in
            guard let record = try DeckRecord.fetchOne(db: db, id: deck.id) else {
                throw AHDatabaseError.deckNotFound(deck.id)
            }
            
            try record.delete(db)
        })
    }
    
    public func fetchDeck(id: Int) throws -> Deck? {
        return try dbWriter.read({ (db) -> Deck? in
            guard let record = try DeckRecord.fetchOne(db: db, id: id) else {
                return nil
            }
            
            let deckCards = try fetchAllDeckCards(forDeckId: record.id!, db: db)
            
            return try makeDeck(record: record, deckCards: deckCards)
        })
    }
    
    public func fetchAllDecks() throws -> [Deck] {
        return try dbWriter.read({ (db) -> [Deck] in
            let records = try DeckRecord.fetchAll(db)
            
            let decks = try records.map({ (record) -> Deck in
                let deckCards = try fetchAllDeckCards(forDeckId: record.id!, db: db)
                
                let deck = try makeDeck(record: record, deckCards: deckCards)
                
                return deck
            })
            
            return decks
        })
    }
    
    private func fetchAllDeckCards(forDeckId id: Int, db: Database) throws -> Set<DeckCard> {
        let records = try DeckCardRecord.fetchAll(db: db, deckId: id)
        
        let deckCards = try records.map { (record) -> DeckCard in
            let card = try cardStore.fetchCard(id: record.cardId)
            
            return DeckCard(card: card, quantity: record.quantity)
        }
        
        return Set<DeckCard>(deckCards)
    }
    
    public func changeDeckName(deck: Deck, to name: String) throws -> Deck {
        guard deck.name != name else { return deck }
        
        var updatedDeck = deck
        
        return try dbWriter.read({ (db) -> Deck in
            guard let record = try DeckRecord.fetchOne(db: db, id: deck.id) else {
                throw AHDatabaseError.deckNotFound(deck.id)
            }
            
            record.name = name
            
            if record.hasPersistentChangedValues {
                try record.save(db)
            }
            
            updatedDeck.name = name
            
            return updatedDeck
        })
    }
    
    public func changeCardQuantity(deck: Deck, card: Card, quantity: Int) throws -> Deck {
        if let deckCard = deck.deckCard(withId: card.id) {
            if deckCard.quantity == quantity {
                return deck
            }
        }
        
        var updatedDeck = deck
        
        return try dbWriter.write({ (db) -> Deck in
            let record: DeckCardRecord
            
            if let retrieved = try DeckCardRecord.fetchOne(db: db, deckId: deck.id, cardId: card.id) {
                record = retrieved
            } else {
                record = DeckCardRecord(deckId: deck.id, cardId: card.id, quantity: quantity)
            }
            
            if record.hasPersistentChangedValues {
                try record.save(db)
            }
            
            updatedDeck.changeQuantity(of: card, quantity: quantity)
            
            return updatedDeck
        })
    }
    
    private func makeDeck(record: DeckRecord, deckCards: Set<DeckCard>) throws -> Deck {
        guard let investigator = cardStore.investigators[record.investigatorId] else {
            throw AHDatabaseError.investigatorNotFound(record.investigatorId)
        }
        
        return Deck(id: record.id!,
                    investigator: investigator,
                    name: record.name,
                    cards: deckCards,
                    creationDate: record.creationDate,
                    updateDate: record.updateDate)
    }
}
