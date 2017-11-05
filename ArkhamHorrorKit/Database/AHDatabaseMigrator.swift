//
//  AHDatabaseMigrator.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 18/10/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

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
        let url = try Files.Schemas.v1.url()
        
        let sql = try String(contentsOf: url)
        
        // Create schema
        try db.execute(AHDatabaseMigrator.cleanUp(sql: sql))
        
        // Load cycles_v1.json
        let cyclesData = try Files.BaseData.cycles.data()
        try CardCycleRecord.loadJSONRecords(json: JSON(data: cyclesData), into: db)
        
        // Add a new entry in Database for cycles' file and its checksum
        let cyclesChecksum = CryptoHelper.sha256Hex(data: cyclesData)
        try FileChecksumRecord(filename: Files.BaseData.cycles.name, hex: cyclesChecksum).insert(db)
        
        // Load packs_v1.json
        let packsData = try Files.BaseData.packs.data()
        try CardPackRecord.loadJSONRecords(json: JSON(data: packsData), into: db)
        
        // Add a new entry in Database for packs' file and its checksum
        let packsChecksum = CryptoHelper.sha256Hex(data: packsData)
        try FileChecksumRecord(filename: Files.BaseData.packs.name, hex: packsChecksum).insert(db)
        
        let cardsAndInvestigatorsFiles: [Files.Basename] = [
            Files.BaseData.core, Files.BaseData.dwl, Files.BaseData.ptc, Files.BaseData.promo
        ]
        
        for file in cardsAndInvestigatorsFiles {
            let fileData = try file.data()
            let json = JSON(data: fileData)
            
            try InvestigatorRecord.loadJSONRecords(json: json, into: db)
            try CardRecord.loadJSONRecords(json: json, into: db)
        }
        
        let onlyCardsFiles: [Files.Basename] = [
            Files.BaseData.apot, Files.BaseData.bota, Files.BaseData.eotp, Files.BaseData.litas,
            Files.BaseData.tece, Files.BaseData.tmm, Files.BaseData.tuo,
            Files.BaseData.uau, Files.BaseData.wda
        ]
        
        for file in onlyCardsFiles {
            let fileData = try file.data()

            try CardRecord.loadJSONRecords(json: JSON(data: fileData), into: db)
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
            
            #if os(iOS) || os(watchOS) || os(tvOS)
            static let bundle = Bundle(identifier: "com.bitmountains.ArkhamHorrorKit-iOS")!
            #elseif os(OSX)
            static let bundle = Bundle(identifier: "com.bitmountains.ArkhamHorrorKit-macOS")!
            #endif
            
            static let v1 = Basename(stem: "schema_v1", ext: "sql", bundle: Schemas.bundle)
        }
        
        struct BaseData {
            #if os(iOS) || os(watchOS) || os(tvOS)
            static let bundle = Bundle(identifier: "com.bitmountains.ArkhamHorrorKit-iOS")!
            #elseif os(OSX)
            static let bundle = Bundle(identifier: "com.bitmountains.ArkhamHorrorKit-macOS")!
            #endif
            private init() { }
            static let cycles = Basename(stem: "base_cycles", ext: "json", bundle: BaseData.bundle)
            static let packs = Basename(stem: "base_packs", ext: "json", bundle: BaseData.bundle)
            
            static let core = Basename(stem: "base_core", ext: "json", bundle: BaseData.bundle)
            static let dwl = Basename(stem: "base_dwl", ext: "json", bundle: BaseData.bundle)
            
            static let apot = Basename(stem: "base_apot", ext: "json", bundle: BaseData.bundle)
            static let bota = Basename(stem: "base_bota", ext: "json", bundle: BaseData.bundle)
            static let eotp = Basename(stem: "base_eotp", ext: "json", bundle: BaseData.bundle)
            static let litas = Basename(stem: "base_litas", ext: "json", bundle: BaseData.bundle)
            static let promo = Basename(stem: "base_promo", ext: "json", bundle: BaseData.bundle)
            static let ptc = Basename(stem: "base_ptc", ext: "json", bundle: BaseData.bundle)
            static let tece = Basename(stem: "base_tece", ext: "json", bundle: BaseData.bundle)
            static let tmm = Basename(stem: "base_tmm", ext: "json", bundle: BaseData.bundle)
            static let tuo = Basename(stem: "base_tuo", ext: "json", bundle: BaseData.bundle)
            static let uau = Basename(stem: "base_uau", ext: "json", bundle: BaseData.bundle)
            static let wda = Basename(stem: "base_wda", ext: "json", bundle: BaseData.bundle)
        }
    }
    
    public enum MigrationVersion: Int {
        case v1 = 1
        
        var stringValue: String {
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
