//  Copyright © 2018 Tiago Bras. All rights reserved.

import Foundation
import GRDB
import SwiftyJSON

final class CardRecordV2: CardRecord {
    var isPermanent: Bool
    var isEarnable: Bool
    
    required init(row: Row) {
        isPermanent = row[CardRecord.RowKeys.isPermanent.rawValue]
        isEarnable = row[CardRecord.RowKeys.isEarnable.rawValue]
        
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        super.encode(to: &container)
        
        container[CardRecord.RowKeys.isPermanent.rawValue] = isPermanent
        container[CardRecord.RowKeys.isEarnable.rawValue] = isEarnable
    }
    
    override class func fetchCard(db: Database, id: Int) throws -> CardRecord? {
        return try CardRecordV2.fetchOne(db, key: ["id": id])
    }

    override class func fetchCards(db: Database, sql: String) throws -> [CardRecord] {
        return try CardRecordV2.fetchAll(db, sql)
    }

    override class func fetchAllCards(db: Database, ids: [Int]? = nil) throws -> [CardRecord] {
        guard let ids = ids, ids.count > 0 else { return try CardRecordV2.fetchAll(db) }

        let idsString = ids.map({ String($0) }).joined(separator: ", ")

        let sql = "SELECT * FROM \(CardRecord.databaseTableName) WHERE id IN (\(idsString))"

        return try CardRecordV2.fetchAll(db, sql)
    }
    
    override class func loadJSONObjectIntoDictionary(
        _ obj: JSON) throws -> [String: DatabaseValueConvertible?]? {
        
        guard var dict = try super.loadJSONObjectIntoDictionary(obj) else { return nil }
        
        dict[CardRecord.RowKeys.isPermanent.rawValue] = obj["permanent"].boolValue
        
        if let factionId = dict[CardRecord.RowKeys.factionId.rawValue] as? Int {
            // FIXME: being from encounter_code doesn't mean it's earnable
            if factionId == CardFaction.neutral.id && obj["encounter_code"].string != nil {
                dict[CardRecord.RowKeys.isEarnable.rawValue] = true
            } else {
                dict[CardRecord.RowKeys.isEarnable.rawValue] = false
            }
        }
        
        return dict
    }
    
    override class func loadJSONRecords(json: JSON, into db: Database) throws {
        for obj in json.arrayValue {
            guard let dict = try loadJSONObjectIntoDictionary(obj) else { continue }
            
            let card = CardRecordV2(row: Row(dict))
            
            try card.save(db)
            
            let keywords = extractKeywords(from: card)
            
            try updateCardFTS(db, card: card, keywords: keywords)
            
            try insertOrIgnoreTraitsIntoDatabase(db, card: card)
        }
    }
}
