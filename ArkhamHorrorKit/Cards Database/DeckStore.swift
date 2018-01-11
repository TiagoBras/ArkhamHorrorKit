//  Copyright © 2017 Tiago Bras. All rights reserved.

import GRDB

public final class DeckStore {
    private let dbWriter: DatabaseWriter
    private let cardStore: CardsStore
    
    public init(dbWriter: DatabaseWriter, cardStore: CardsStore) {
        self.dbWriter = dbWriter
        self.cardStore = cardStore
    }
    
    func createDeck(name: String, investigatorId: Int) throws -> Deck {
        return try dbWriter.write({ (db) -> Deck in
            let record = DeckRecord(investigatorId: investigatorId, name: name, version: 1)
            
            try record.save(db)
            
            return try makeDeck(record: record, deckCards: Set())
        })
    }
    
    public func createDeck(name: String, investigator: Investigator) throws -> Deck {
        return try createDeck(name: name, investigatorId: investigator.id)
    }
    
    public func createDeck(name: String, investigator: Investigator, completion: @escaping (Deck?, Error?) -> ()) {
        DispatchQueue.global().async { [weak self] in
            do {
                if let output = try self?.createDeck(name: name, investigator: investigator) {
                    DispatchQueue.main.async {
                        completion(output, nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }

    public func createDeck(name: String, from deck: Deck) throws -> Deck {
        return try dbWriter.write({ (db) -> Deck in
            guard let oldRecord = try DeckRecord.fetchOne(db: db, id: deck.id) else {
                throw AHDatabaseError.deckNotFound(deck.id)
            }

            let record = DeckRecord(investigatorId: deck.investigator.id,
                                    name: name,
                                    version: oldRecord.version + 1)
            record.previousVersionDeckId = oldRecord.id
            try record.save(db)

            oldRecord.nextVersionDeckId = record.id

            if oldRecord.hasPersistentChangedValues {
                try oldRecord.save(db)
            }

            return try makeDeck(record: record, deckCards: Set())
        })
    }
    
    public func createDeck(name: String, from deck: Deck, completion: @escaping (Deck?, Error?) -> ()) {
        DispatchQueue.global().async { [weak self] in
            do {
                if let output = try self?.createDeck(name: name, from: deck) {
                    DispatchQueue.main.async {
                        completion(output, nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }
    
    public func deleteDeck(_ deck: Deck) throws {
        try dbWriter.write({ (db) in
            guard let record = try DeckRecord.fetchOne(db: db, id: deck.id) else {
                throw AHDatabaseError.deckNotFound(deck.id)
            }
            
            try record.delete(db)
        })
    }
    
    public func deleteDeck(_ deck: Deck, completion: @escaping (Error?) -> ()) {
        DispatchQueue.global().async { [weak self] in
            do {
                try self?.deleteDeck(deck)
                
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }
    
    public func fetchDeck(id: Int) throws -> Deck? {
        guard let record = try dbWriter.read({ (db) -> DeckRecord? in
            return try DeckRecord.fetchOne(db: db, id: id)
        }) else { return nil }
        
        let deckCards = try fetchAllDeckCards(forDeckId: record.id!)
        
        return try makeDeck(record: record, deckCards: deckCards)
    }
    
    public func fetchDeck(id: Int, completion: @escaping (Deck?, Error?) -> ()) {
        DispatchQueue.global().async { [weak self] in
            do {
                if let output = try self?.fetchDeck(id: id) {
                    DispatchQueue.main.async {
                        completion(output, nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }
    
    public func fetchAllDecks() throws -> [Deck] {
        let records = try dbWriter.read({ (db) -> [DeckRecord] in
            return try DeckRecord.fetchAll(db)
        })
        
        let decks = try records.map({ (record) -> Deck in
            let deckCards = try fetchAllDeckCards(forDeckId: record.id!)
            
            let deck = try makeDeck(record: record, deckCards: deckCards)
            
            return deck
        })
        
        return decks
    }
    
    public func fetchAllDeck(completion: @escaping ([Deck]?, Error?) -> ()) {
        DispatchQueue.global().async { [weak self] in
            do {
                if let output = try self?.fetchAllDecks() {
                    DispatchQueue.main.async {
                        completion(output, nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }
    
    func fetchAllDeckCards(forDeckId id: Int) throws -> Set<DeckCard> {
        let records = try dbWriter.read({ (db) -> [DeckCardRecord] in
            return try DeckCardRecord.fetchAll(db: db, deckId: id)
        })
        
        let deckCards = try records.map { (record) -> DeckCard in
            let card = try cardStore.fetchCard(id: record.cardId)
            
            return DeckCard(card: card, quantity: record.quantity)
        }
        
        return Set<DeckCard>(deckCards)
    }
    
    public func changeDeckName(deck: Deck, to name: String) throws -> Deck {
        var updatedDeck = deck
        
        return try dbWriter.write({ (db) -> Deck in
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
    
    public func changeDeckName(deck: Deck, to name: String, completion: @escaping (Deck?, Error?) -> ()) {
        DispatchQueue.global().async { [weak self] in
            do {
                if let output = try self?.changeDeckName(deck: deck, to: name) {
                    DispatchQueue.main.async {
                        completion(output, nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
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
    
    public func changeCardQuantity(deck: Deck,
                                   card: Card,
                                   quantity: Int,
                                   completion: @escaping (Deck?, Error?) -> ())  {
        DispatchQueue.global().async { [weak self] in
            do {
                if let output = try self?.changeCardQuantity(deck: deck, card: card, quantity: quantity) {
                    DispatchQueue.main.async {
                        completion(output, nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
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
                    updateDate: record.updateDate,
                    version: record.version,
                    prevDeckVersionId: record.previousVersionDeckId,
                    nextDeckVersionId: record.nextVersionDeckId)
    }
}
