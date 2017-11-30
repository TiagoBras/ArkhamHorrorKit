//
//  CardTraitRecord.swift
//  ArkhamHorrorKit
//
//  Created by Tiago Bras on 29/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import GRDB

final class CardTraitRecord: Record {
    var cardId: Int
    var traitName: String
    
    override class var databaseTableName: String {
        return "CardTrait"
    }
    
    init(cardId: Int, traitName: String) {
        self.cardId = cardId
        self.traitName = traitName
        
        super.init()
    }
    
    required init(row: Row) {
        cardId = row["card_id"]
        traitName = row["trait_name"]
        
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container["card_id"] = cardId
        container["trait_name"] = traitName
    }
    
    class func fetchCardTraits(db: Database, cardId: Int) throws -> [CardTraitRecord] {
        let sql = "SELECT * FROM \(CardTraitRecord.databaseTableName) WHERE card_id = ?"
        
        return try CardTraitRecord.fetchAll(db, sql, arguments: [cardId], adapter: nil)
    }
}
