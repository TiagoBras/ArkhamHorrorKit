//
//  FileChecksumRecord.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 21/10/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation
import GRDB

class FileChecksumRecord: Record {
    var filename: String
    var hex: String
    
    override class var databaseTableName: String {
        return "FileChecksum"
    }
    
    init(filename: String, hex: String) {
        self.filename = filename
        self.hex = hex
        
        super.init()
    }
    
    required init(row: Row) {
        filename = row["filename"]
        hex = row["hex"]
        
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container["filename"] = filename
        container["hex"] = hex
    }
    
    class func fetchOne(db: Database, filename: String) throws -> FileChecksumRecord? {
        return try FileChecksumRecord.fetchOne(db, key: ["filename": filename])
    }
}
