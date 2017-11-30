//
//  Trait.swift
//  ArkhamHorrorKit iOS
//
//  Created by Tiago Bras on 29/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import GRDB

final class TraitRecord: Record {
    var name: String
    
    override class var databaseTableName: String {
        return "Trait"
    }
    
    init(name: String) {
        self.name = name
        
        super.init()
    }
    
    required init(row: Row) {
        name = row["name"]
        
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container["name"] = name
    }
    
    class func fetchOne(db: Database, name: String) throws -> TraitRecord? {
        return try TraitRecord.fetchOne(db, key: ["name": name])
    }
}
