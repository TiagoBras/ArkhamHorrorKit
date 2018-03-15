//  Copyright © 2017 Tiago Bras. All rights reserved.

import Foundation
import GRDB

final class DeckCardRecord: Record {
    var cardId: Int
    var deckId: Int
    var quantity: Int
    
    override class var databaseTableName: String {
        return "DeckCard"
    }
    
    init(deckId: Int, cardId: Int, quantity: Int) {
        self.deckId = deckId
        self.cardId = cardId
        self.quantity = quantity
        
        super.init()
    }
    
    required init(row: Row) {
        cardId = row["card_id"]
        deckId = row["deck_id"]
        quantity = row["quantity"]
        
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container["card_id"] = cardId
        container["deck_id"] = deckId
        container["quantity"] = quantity
    }
    
    class func fetchOne(db: Database, deckId: Int, cardId: Int) throws -> DeckCardRecord? {
        let key: [String: DatabaseValueConvertible?] = ["deck_id": deckId, "card_id": cardId]
        
        return try DeckCardRecord.fetchOne(db, key: key)
    }
    
    class func fetchAll(db: Database, deckId: Int) throws -> [DeckCardRecord] {
        return try DeckCardRecord.fetchAll(db,
                                           "SELECT * FROM \(databaseTableName) WHERE deck_id = ?",
                                           arguments: [deckId],
                                           adapter: nil)
    }
}
