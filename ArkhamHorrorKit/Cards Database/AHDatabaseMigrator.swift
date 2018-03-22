//  Copyright © 2017 Tiago Bras. All rights reserved.
import Foundation
import GRDB
import SwiftyJSON
import TBSwiftKit

public final class AHDatabaseMigrator {
    public var currentVersion: MigrationVersion?
    public var lastAvailableVersion: MigrationVersion {
        let sortedMigrations = migrations.sorted(by: { $0.version.rawValue < $1.version.rawValue })
        
        return sortedMigrations.last!.version
    }
    
    private var migrations: [Migration] {
        let v1 = Migration(version: .v1, migrate: AHDatabaseMigrator.v1)
        let v2 = Migration(version: .v2, migrate: AHDatabaseMigrator.v2)
        
        // !!! Insert migrations here !!!
        
        return [v1, v2]
    }
    
    public init() {
        migrations.forEach { (migration) in
            migration.register(with: &migrator)
        }
    }
    
    public func migrate(database: DatabaseWriter, upTo migration: MigrationVersion? = nil) throws  {
        if let version = migration {
            try migrator.migrate(database, upTo: version.stringValue)
            currentVersion = version
        } else {
            try migrator.migrate(database)
            currentVersion = lastAvailableVersion
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
        
        try loadBaseData(db, cardRecordClass: CardRecord.self)
    }
    
    public static func v2(_ db: Database) throws {
        // Add 'permanent' & 'fromEncounterDeck' columns to Card model
        let newColumns: [String] = [
            CardRecord.RowKeys.isPermanent.rawValue,
            CardRecord.RowKeys.isEarnable.rawValue
        ]
        
        let tableName = CardRecord.databaseTableName
        for column in newColumns {
            let sql = "ALTER TABLE \(tableName) ADD COLUMN \(column) INTEGER NOT NULL DEFAULT 0"
            
            try db.execute(sql)
        }
        
        // Reload base data
        try loadBaseData(db, cardRecordClass: CardRecordV2.self)
    }
    
    private static func loadBaseData(_ db: Database, cardRecordClass: CardRecord.Type) throws {
        let thisBundle = Bundle(for: self)
        var jsonLoaderResults = [JSONLoader.JSONLoaderResults]()
        
        // Load cycles.json
        let cyclesRes = try JSONLoader.load(bundle: thisBundle, filename: "cycles.json")
        try CardCycleRecord.loadJSONRecords(json: cyclesRes.json, into: db)
        try FileChecksumRecord(filename: "cycles.json", hex: cyclesRes.checksum).save(db)
        jsonLoaderResults.append(cyclesRes)
        
        // Load packs.json
        let packsRes = try JSONLoader.load(bundle: thisBundle, filename: "packs.json")
        let packs = try CardPackRecord.loadJSONRecords(json: packsRes.json, into: db)
        try FileChecksumRecord(filename: "packs.json", hex: packsRes.checksum).save(db)
        jsonLoaderResults.append(packsRes)
        
        for pack in packs {
            let cycleRecords = try CardCycleRecord.fetchAll(db)
            
            guard cycleRecords.index(where: { $0.id == pack.cycleId }) != nil else {
                continue
            }
            
            guard let url = thisBundle.url(forResource: pack.id, withExtension: "json") else {
                continue
            }
            
            let loadResults = try JSONLoader.load(url: url)
            
            var skipChecksum = true
            
            do {
                try InvestigatorRecord.loadJSONRecords(json: loadResults.json, into: db)
                try FileChecksumRecord(filename: "\(pack.id).json", hex: loadResults.checksum).save(db)
                jsonLoaderResults.append(loadResults)
                
            } catch CardRecord.CardError.jsonDoesNotContainCards {
                skipChecksum = false
            } catch {
                throw error
            }
            
            do {
                if cardRecordClass == CardRecordV2.self {
                    try CardRecordV2.loadJSONRecords(json: loadResults.json, into: db)
                } else {
                    try CardRecord.loadJSONRecords(json: loadResults.json, into: db)
                }

                if !skipChecksum {
                    try FileChecksumRecord(filename: "\(pack.id).json", hex: loadResults.checksum).save(db)
                    jsonLoaderResults.append(loadResults)
                }
            } catch CardRecord.CardError.jsonDoesNotContainCards {
                continue
            } catch {
                throw error
            }
        }
        
        // Update GeneralInfo
        let concatenatedChecksum = jsonLoaderResults.sorted().map({ $0.checksum }).joined(separator: "")
        
        guard let checksum = CryptoHelper.sha256Hex(string: concatenatedChecksum) else {
            throw CardsDatabaseMigratorError.couldNotCalculateHashOfString(concatenatedChecksum)
        }
        
        let generalInfo = try GeneralInfo.fetchUniqueRow(db: db)
        generalInfo.jsonFilesChecksum = checksum
        
        try generalInfo.save(db)
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
        case v1 = 1, v2 = 2
        
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
        case couldNotCalculateHashOfString(String)
    }
}
