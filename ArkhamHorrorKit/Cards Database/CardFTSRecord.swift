//  Copyright © 2017 Tiago Bras. All rights reserved.

import Foundation
import GRDB

final class CardFTSRecord: Record {
    var id: Int
    var name: String
    var type: String
    var faction: String
    var traits: String
    var slot: String
    var keywords: String
    var cardText: String
    
    override class var databaseTableName: String {
        return "CardFTS"
    }
    
    init(id: Int, name: String, type: String, faction: String,
         traits: String, slot: String, keywords: String, cardText: String) {
        self.id = id
        self.name = name
        self.type = type
        self.faction = faction
        self.traits = traits
        self.slot = slot
        self.keywords = keywords
        self.cardText = cardText
        
        super.init()
    }
    
    required init(row: Row) {
        id = row["id"]
        name = row["name"]
        type = row["type"]
        faction = row["faction"]
        traits = row["traits"]
        slot = row["slot"]
        keywords = row["keywords"]
        cardText = row["card_text"]
        
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["name"] = name
        container["type"] = type
        container["faction"] = faction
        container["traits"] = traits
        container["slot"] = slot
        container["keywords"] = keywords
        container["card_text"] = cardText
    }
}
