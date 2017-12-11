//  Copyright © 2017 Tiago Bras. All rights reserved.

import Foundation
import GRDB
import SwiftyJSON

final class CardPackRecord: Record {
    var id: String
    var name: String
    var position: Int
    var size: Int
    var cycleId: String
    
    override class var databaseTableName: String {
        return "Pack"
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
        cycleId = row["cycle_id"]
        
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["name"] = name
        container["position"] = position
        container["size"] = size
        container["cycle_id"] = cycleId
    }
    
    class func fetchOne(db: Database, id: String) throws -> CardPackRecord? {
        return try CardPackRecord.fetchOne(db, key: ["id": id])
    }
    
    @discardableResult
    class func loadJSONRecords(json: JSON, into db: Database) throws -> [CardPackRecord] {
        var packs = [CardPackRecord]()
        
        for obj in json.arrayValue {
            guard obj["date_release"].string != nil else { continue }
            
            var dict = [String: DatabaseValueConvertible?]()
            dict["id"] = obj["code"].stringValue
            dict["name"] = obj["name"].stringValue
            dict["position"] = obj["position"].intValue
            dict["size"] = obj["size"].intValue
            dict["cycle_id"] = obj["cycle_code"].stringValue
            
            let pack = CardPackRecord(row: Row(dict))
            
            try pack.save(db)
            
            packs.append(pack)
        }
        
        return packs
    }
}
