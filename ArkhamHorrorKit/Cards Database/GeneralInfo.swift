import Foundation
import GRDB

final class GeneralInfo: Record {
    var jsonFilesChecksum: String
    var imagesChecksum: String
    
    override class var databaseTableName: String {
        return "GeneralInfo"
    }
    
    init(jsonFilesChecksum: String, imagesChecksum: String) {
        self.jsonFilesChecksum = jsonFilesChecksum
        self.imagesChecksum = imagesChecksum
        
        super.init()
    }
    
    required init(row: Row) {
        jsonFilesChecksum = row["json_files_checksum"]
        imagesChecksum = row["images_checksum"]
        
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container["id"] = 0
        container["json_files_checksum"] = jsonFilesChecksum
        container["images_checksum"] = imagesChecksum
    }
    
    class func fetchUniqueRow(db: Database) throws -> GeneralInfo {
        if let record = try GeneralInfo.fetchOne(db, key: ["id": 0]) {
            return record
        }
        
        return GeneralInfo(jsonFilesChecksum: "", imagesChecksum: "")
    }
}
