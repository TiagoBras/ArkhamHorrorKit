//
//  ChaosBagDatabaseMigrator.swift
//  ArkhamHorrorKit
//
//  Created by Tiago Bras on 10/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import GRDB
import SwiftyJSON
import TBSwiftKit

public final class ChaosBagDatabaseMigrator {
    public var lastVersion: MigrationVersion {
        let sortedMigrations = migrations.sorted(by: { $0.version.rawValue < $1.version.rawValue })
        
        return sortedMigrations.last!.version
    }
    
    private var migrations: [Migration] {
        let v1 = Migration(version: .v1, migrate: ChaosBagDatabaseMigrator.v1)
        
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
        try db.create(table: "Campaign") { (tb) in
            tb.column("id", Database.ColumnType.integer).primaryKey()
            tb.column("name", Database.ColumnType.text).notNull().unique()
            tb.column("icon_name", Database.ColumnType.text)
            tb.column("protected", Database.ColumnType.boolean).notNull()
        }
        
        try db.create(table: "Scenario", body: { (tb) in
            tb.column("id", Database.ColumnType.integer).primaryKey()
            tb.column("name", Database.ColumnType.text).notNull()
            tb.column("icon_name", Database.ColumnType.text)
            tb.column("campaign_id", Database.ColumnType.integer)
                .references(
                    "Campaign",
                    column: "id",
                    onDelete: Database.ForeignKeyAction.cascade,
                    onUpdate: Database.ForeignKeyAction.cascade,
                    deferred: false)
            tb.column("protected", Database.ColumnType.boolean).notNull()
        })
        
        try db.create(table: "ChaosBag", body: { (tb) in
            tb.column("id", Database.ColumnType.integer).primaryKey()
            tb.column("protected", Database.ColumnType.boolean).notNull()
            tb.column("p1", Database.ColumnType.integer).notNull().defaults(to: 0)
            tb.column("zero", Database.ColumnType.integer).notNull().defaults(to: 0)
            tb.column("m1", Database.ColumnType.integer).notNull().defaults(to: 0)
            tb.column("m2", Database.ColumnType.integer).notNull().defaults(to: 0)
            tb.column("m3", Database.ColumnType.integer).notNull().defaults(to: 0)
            tb.column("m4", Database.ColumnType.integer).notNull().defaults(to: 0)
            tb.column("m5", Database.ColumnType.integer).notNull().defaults(to: 0)
            tb.column("m6", Database.ColumnType.integer).notNull().defaults(to: 0)
            tb.column("m7", Database.ColumnType.integer).notNull().defaults(to: 0)
            tb.column("m8", Database.ColumnType.integer).notNull().defaults(to: 0)
            tb.column("skull", Database.ColumnType.integer).notNull().defaults(to: 0)
            tb.column("autofail", Database.ColumnType.integer).notNull().defaults(to: 0)
            tb.column("tablet", Database.ColumnType.integer).notNull().defaults(to: 0)
            tb.column("cultist", Database.ColumnType.integer).notNull().defaults(to: 0)
            tb.column("eldersign", Database.ColumnType.integer).notNull().defaults(to: 0)
            tb.column("elderthing", Database.ColumnType.integer).notNull().defaults(to: 0)
        })
        
        try db.create(table: "ScenarioChaosBag", body: { (tb) in
            tb.column("scenario_id", Database.ColumnType.integer).references(
                "Scenario",
                column: "id",
                onDelete: Database.ForeignKeyAction.cascade,
                onUpdate: Database.ForeignKeyAction.cascade,
                deferred: false)
            tb.column("difficulty", Database.ColumnType.text)
                .check(sql: "difficulty IN ('easy', 'normal', 'hard', 'expert', 'standalone')")
            tb.column("chaos_bag_id", Database.ColumnType.integer).references(
                "ChaosBag",
                column: "id",
                onDelete: Database.ForeignKeyAction.cascade,
                onUpdate: Database.ForeignKeyAction.cascade,
                deferred: false)
            tb.primaryKey(["scenario_id", "difficulty"])
        })
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
            static let cycles = Basename(stem: "base_cycles", ext: "json", bundle: BaseData.bundle)
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
