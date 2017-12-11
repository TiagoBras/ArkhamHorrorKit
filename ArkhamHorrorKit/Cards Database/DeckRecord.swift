//  Copyright © 2017 Tiago Bras. All rights reserved.

import GRDB

final class DeckRecord: Record {
    var id: Int?
    var name: String
    var investigatorId: Int
    var creationDate: Date
    var updateDate: Date
    
    override class var databaseTableName: String {
        return "Deck"
    }
    
    init(investigatorId: Int, name: String) {
        self.name = name
        self.investigatorId = investigatorId
        self.creationDate = Date()
        self.updateDate = creationDate
        
        super.init()
    }
    
    required init(row: Row) {
        id = row["id"]
        investigatorId = row["investigator_id"]
        name = row["name"]
        creationDate = row["creation_date"]
        updateDate = row["update_date"]
        
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["investigator_id"] = investigatorId
        container["name"] = name
        container["creation_date"] = creationDate
        container["update_date"] = updateDate
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = Int(rowID)
    }
    
    class func fetchOne(db: Database, id: Int) throws -> DeckRecord? {
        return try DeckRecord.fetchOne(db, key: ["id": id])
    }
    
    func update(_ db: Database) throws {
        self.updateDate = Date()
        
        try super.update(db)
    }
}
