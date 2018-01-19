//  Copyright © 2017 Tiago Bras. All rights reserved.

import Foundation
import GRDB

final class FileChecksumRecord: Record, Comparable {
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
    
    static func <(lhs: FileChecksumRecord, rhs: FileChecksumRecord) -> Bool {
        return lhs.filename < rhs.filename
    }
    
    static func ==(lhs: FileChecksumRecord, rhs: FileChecksumRecord) -> Bool {
        guard lhs.filename == lhs.filename else { return false }
        
        return lhs.hex == rhs.hex
    }
}
