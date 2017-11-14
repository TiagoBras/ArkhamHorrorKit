//
//  DBCardCycle.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 21/10/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation
import GRDB
import SwiftyJSON

final class CardCycleRecord: Record {
    var id: String
    var name: String
    var position: Int
    var size: Int
    
    override class var databaseTableName: String {
        return "Cycle"
    }
    
    override class var persistenceConflictPolicy: PersistenceConflictPolicy {
        return PersistenceConflictPolicy(
            insert: .replace,
            update: .replace)
    }
    
    required init(row: Row) {
        id = row["id"]
        name = row["name"]
        position = row["position"]
        size = row["size"]
        
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["name"] = name
        container["position"] = position
        container["size"] = size
     }
    
    class func fetchOne(db: Database, id: String) throws -> CardCycleRecord? {
        return try CardCycleRecord.fetchOne(db, key: ["id": id])
    }
    
    class func loadJSONRecords(json: JSON, into db: Database) throws {
        for obj in json.arrayValue {
            var dict = [String: DatabaseValueConvertible?]()
            dict["id"] = obj["code"].stringValue
            dict["name"] = obj["name"].stringValue
            dict["position"] = obj["position"].intValue
            dict["size"] = obj["size"].intValue
            dict["cycle_id"] = obj["cycle_code"].stringValue
            
            let pack = CardCycleRecord(row: Row(dict))
            
            try pack.save(db)
        }
    }
}
