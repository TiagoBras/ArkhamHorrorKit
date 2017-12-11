//  Copyright © 2017 Tiago Bras. All rights reserved.
import Foundation
import GRDB
import SwiftyJSON
import TBSwiftKit

public final class AHDatabaseMigrator {
    public var lastVersion: MigrationVersion {
        let sortedMigrations = migrations.sorted(by: { $0.version.rawValue < $1.version.rawValue })
        
        return sortedMigrations.last!.version
    }
    
    private var migrations: [Migration] {
        let v1 = Migration(version: .v1, migrate: AHDatabaseMigrator.v1)
        
        // !!! Insert migrations here !!!
        
        return [v1]
    }
    
    public init() {
        migrations.forEach { (migration) in
            migration.register(with: &migrator)
        }
    }
    
    public func migrate(database: DatabaseWriter, upTo migration: MigrationVersion? = nil) throws  {
        if let version = migration {
            try migrator.migrate(database, upTo: version.stringValue)
        } else {
            try migrator.migrate(database)
        }
    }
    
    // MARK:- Private fields
    private var migrator = DatabaseMigrator()
    
    private static func v1(_ db: Database) throws {
        let thisBundle = Bundle(for: self)
        
        guard let schemaSQL = thisBundle.url(forResource: "schema_v1", withExtension: "sql") else {
            throw CardsDatabaseMigratorError.fileNotFound("schema_v1.sql")
        }
        
        let sql = try String(contentsOf: schemaSQL)
        
        // Create schema
        try db.execute(AHDatabaseMigrator.cleanUp(sql: sql))
        
        // Load cycles.json
        guard let cyclesURL = thisBundle.url(forResource: "cycles", withExtension: "json") else {
            throw CardsDatabaseMigratorError.fileNotFound("cycles.json")
        }
        let cyclesData = try Data(contentsOf: cyclesURL)
        try CardCycleRecord.loadJSONRecords(json: JSON(data: cyclesData), into: db)
        
        // Add a new entry in Database for cycles' file and its checksum
        let cyclesChecksum = CryptoHelper.sha256Hex(data: cyclesData)
        try FileChecksumRecord(filename: "cycles.json", hex: cyclesChecksum).save(db)
        
        // Load packs.json
        guard let packsURL = thisBundle.url(forResource: "packs", withExtension: "json") else {
            throw CardsDatabaseMigratorError.fileNotFound("packs.json")
        }
        let packsData = try Data(contentsOf: packsURL)
        let packs = try CardPackRecord.loadJSONRecords(json: JSON(data: packsData), into: db)
        
        // Add a new entry in Database for packs' file and its checksum
        let packsChecksum = CryptoHelper.sha256Hex(data: packsData)
        try FileChecksumRecord(filename: "packs.json", hex: packsChecksum).save(db)
        
        for pack in packs {
            let ignoreFiles = Set<String>(["cotr"])
            
            guard !ignoreFiles.contains(pack.id) else { return }
            
            guard let url = thisBundle.url(forResource: pack.id, withExtension: "json") else {
                throw CardsDatabaseMigratorError.fileNotFound("\(pack.id).json in '\(String(describing: thisBundle.bundleIdentifier))'")
            }
            
            let data = try Data(contentsOf: url)
            let json = JSON(data: data)
            
            try InvestigatorRecord.loadJSONRecords(json: json, into: db)
            try CardRecord.loadJSONRecords(json: json, into: db)
            
            let fileChecksum = CryptoHelper.sha256Hex(data: data)
            
            try FileChecksumRecord(filename: "\(pack.id).json", hex: fileChecksum).save(db)
        }
    }
    
    private static func cleanUp(sql: String) -> String {
        return sql.components(separatedBy: CharacterSet.newlines)
            .map({ $0.trimmingCharacters(in: CharacterSet.whitespaces) })
            .filter({ !$0.isEmpty && !$0.hasPrefix("--") })
            .joined(separator: "\n")
    }
    
    // MARK:- Internal Structs & Enums
    struct Files {
        private init() { }
        
        struct Basename {
            let stem: String
            let ext: String
            let bundle: Bundle
            
            var name: String { return "\(stem).\(ext)"}
            
            init(stem: String, ext: String, bundle: Bundle) {
                self.stem = stem
                self.ext = ext
                self.bundle = bundle
            }
            
            func url() throws -> URL {
                guard let url = bundle.url(forResource: stem, withExtension: ext) else {
                    throw CardsDatabaseMigratorError.fileNotFound(name)
                }
                
                return url
            }
            
            func data() throws -> Data {
                let url = try self.url()
                
                return try Data(contentsOf: url)
            }
        }
        
        struct Schemas {
            private init() { }
            
            static let bundle = Bundle(for: AHDatabaseMigrator.self)

            static let v1 = Basename(stem: "schema_v1", ext: "sql", bundle: Schemas.bundle)
        }
        
        struct BaseData {
            static let bundle = Bundle(for: AHDatabaseMigrator.self)

            private init() { }
            static let cycles = Basename(stem: "cycles", ext: "json", bundle: BaseData.bundle)
            static let packs = Basename(stem: "packs", ext: "json", bundle: BaseData.bundle)
            
            static let core = Basename(stem: "core", ext: "json", bundle: BaseData.bundle)
            static let dwl = Basename(stem: "dwl", ext: "json", bundle: BaseData.bundle)
            
            static let bota = Basename(stem: "bota", ext: "json", bundle: BaseData.bundle)
            static let eotp = Basename(stem: "eotp", ext: "json", bundle: BaseData.bundle)
            static let litas = Basename(stem: "litas", ext: "json", bundle: BaseData.bundle)
            static let promo = Basename(stem: "promo", ext: "json", bundle: BaseData.bundle)
            static let ptc = Basename(stem: "ptc", ext: "json", bundle: BaseData.bundle)
            static let tece = Basename(stem: "tece", ext: "json", bundle: BaseData.bundle)
            static let tmm = Basename(stem: "tmm", ext: "json", bundle: BaseData.bundle)
            static let tuo = Basename(stem: "tuo", ext: "json", bundle: BaseData.bundle)
            static let uau = Basename(stem: "uau", ext: "json", bundle: BaseData.bundle)
            static let wda = Basename(stem: "wda", ext: "json", bundle: BaseData.bundle)
        }
    }
    
    public enum MigrationVersion: Int {
        case v1 = 1
        
        public var stringValue: String {
            return "v\(rawValue).0"
        }
    }
    
    private struct Migration {
        var version: MigrationVersion
        var migrate: (Database) throws -> ()
        var disableForeignKeysCheck: Bool
        
        init(version: MigrationVersion, migrate: @escaping (Database) throws -> ()) {
            self.init(version: version, disableForeignKeysCheck: false, migrate: migrate)
        }
        
        init(version: MigrationVersion, disableForeignKeysCheck: Bool,
             migrate: @escaping (Database) throws -> ()) {
            self.version = version
            self.migrate = migrate
            self.disableForeignKeysCheck = disableForeignKeysCheck
        }
        
        func register(with migrator: inout DatabaseMigrator) {
            if disableForeignKeysCheck {
                migrator.registerMigrationWithDeferredForeignKeyCheck(version.stringValue, migrate: migrate)
            } else {
                migrator.registerMigration(version.stringValue, migrate: migrate)
            }
        }
    }
    
    enum CardsDatabaseMigratorError: Error {
        case fileNotFound(String)
    }
}
