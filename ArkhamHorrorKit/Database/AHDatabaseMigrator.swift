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

class AHDatabaseMigrator {
    var lastVersion: MigrationVersion {
        let sortedMigrations = migrations.sorted(by: { $0.version.rawValue < $1.version.rawValue })
        
        return sortedMigrations.last!.version
    }
    
    private var migrations: [Migration] {
        let v1 = Migration(version: .v1, migrate: AHDatabaseMigrator.v1)
        
        // !!! Insert migrations here !!!
        
        return [v1]
    }
    
    init() {
        migrations.forEach { (migration) in
            migration.register(with: &migrator)
        }
    }
    
    func migrate(database: DatabaseWriter, upTo migration: MigrationVersion? = nil) throws  {
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
            
            init(stem: String, ext: String, bundle: Bundle = Bundle.main) {
                self.stem = stem
                self.ext = ext
                self.bundle = bundle
            }
            
            func url() throws -> URL {
                guard let url = Bundle.main.url(forResource: stem, withExtension: ext) else {
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
            
            static let v1 = Basename(stem: "schema_v1", ext: "sql")
        }
        
        struct BaseData {
            private init() { }
            static let cycles = Basename(stem: "base_cycles", ext: "json")
            static let packs = Basename(stem: "base_packs", ext: "json")
            
            static let core = Basename(stem: "base_core", ext: "json")
            static let dwl = Basename(stem: "base_dwl", ext: "json")
            
            static let apot = Basename(stem: "base_apot", ext: "json")
            static let bota = Basename(stem: "base_bota", ext: "json")
            static let eotp = Basename(stem: "base_eotp", ext: "json")
            static let litas = Basename(stem: "base_litas", ext: "json")
            static let promo = Basename(stem: "base_promo", ext: "json")
            static let ptc = Basename(stem: "base_ptc", ext: "json")
            static let tece = Basename(stem: "base_tece", ext: "json")
            static let tmm = Basename(stem: "base_tmm", ext: "json")
            static let tuo = Basename(stem: "base_tuo", ext: "json")
            static let uau = Basename(stem: "base_uau", ext: "json")
            static let wda = Basename(stem: "base_wda", ext: "json")
        }
    }
    
    enum MigrationVersion: Int {
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
