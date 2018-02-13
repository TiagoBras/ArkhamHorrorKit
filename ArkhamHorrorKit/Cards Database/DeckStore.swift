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
        let newDeck = try duplicateDeck(deck)
        
        return try dbWriter.write({ (db) -> Deck in
            guard let oldRecord = try DeckRecord.fetchOne(db: db, id: deck.id) else {
                throw AHDatabaseError.deckNotFound(deck.id)
            }
            
            guard let newRecord = try DeckRecord.fetchOne(db: db, id: newDeck.id) else {
                throw AHDatabaseError.deckNotFound(newDeck.id)
            }

            newRecord.previousVersionDeckId = oldRecord.id
            newRecord.version = oldRecord.version + 1
            try newRecord.save(db)

            oldRecord.nextVersionDeckId = newRecord.id
            try oldRecord.save(db)

            return try makeDeck(record: newRecord, deckCards: newDeck.cards)
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
    
    public func duplicateDeck(_ deck: Deck) throws -> Deck {
        let deckId = try dbWriter.write({ (db) -> Int in
            let record = DeckRecord(investigatorId: deck.investigator.id,
                                    name: deck.name,
                                    version: 1)
            
            try record.save(db)
            
            guard let deckId = record.id else {
                throw AHDatabaseError.deckHasNoDefinedId
            }
            
            for deckCard in deck.cards {
                let record = DeckCardRecord(deckId: deckId,
                                            cardId: deckCard.card.id,
                                            quantity: deckCard.quantity)
                try record.save(db)
            }
            
            return deckId
        })
        
        guard let deck = try fetchDeck(id: deckId) else {
            throw AHDatabaseError.deckNotFound(deckId)
        }
        
        return deck
    }
    
    public func duplicateDeck(_ deck: Deck, completion: @escaping (Deck?, Error?) -> ()) {
        DispatchQueue.global().async { [weak self] in
            do {
                let deck = try self?.duplicateDeck(deck)
                
                DispatchQueue.main.async {
                    completion(deck, nil)
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
            let record = DeckCardRecord(deckId: deck.id, cardId: card.id, quantity: quantity)
            
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
    
    private func genDeckFetchStatement(filter: DeckFilter?,
                                       sortingDescriptors: [Deck]?) -> String {
        var sql = "SELECT * FROM \(DeckRecord.databaseTableName)"
        
        var joinsClause = [String]()
        var whereClause = [String]()
        var sortClause = [String]()
        
        if let factions = filter?.factions, factions.count > 0 {
            let t = InvestigatorRecord.databaseTableName
  
            joinsClause.append("INNER JOIN \(t) ON \(t).id = investigator_id")
            
            let ids = factions.map({ String($0.id) }).joined(separator: ", ")
            
            whereClause.append("\(t).faction_id IN (\(ids))")
        }
        
        if let ids = filter?.investigatorsIds?.map({ String($0) }), ids.count > 0 {
            whereClause.append("investigator_id IN (\(ids.joined(separator: ", ")))")
        }
        
        if let descriptors = sortingDescriptors, descriptors.count > 0 {
            func orderStmt(_ descriptor: DeckSortingDescriptor) -> String {
                let mod: String = descriptor.ascending ? "ASC" : "DESC"
                
                switch descriptor.column {
//                case .name: return "name \(mod)"
//                case .faction: return "faction_id \(mod)"
//                case .pack: return "pack_id \(mod)"
//                case .type: return "type_id \(mod)"
//                case .level: return "level \(mod)"
//                case .assetSlot: return "asset_slot_id IS NULL, asset_slot_id \(mod)"
//                case .favoriteStatus: return "favorite \(mod)"
                case .name: return "name \(mod)"
                case .updateDate: return "update_date \(mod)"
                case .creationDate: return "creation_date \(mod)"
                case .faction: return "\(InvestigatorRecord.databaseTableName).faction_id \(mod)"
                case .investigator: return "investigator_id \(mod)"
                }
            }
            
//            return descriptors
//                .map({ orderStmt($0) })
//                .joined(separator: ", ")
        } else {
            sortClause.append("id DESC")
        }
        
        return ""
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
