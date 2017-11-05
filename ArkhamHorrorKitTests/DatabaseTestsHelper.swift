//
//  DatabaseTestsHelper.swift
//  ArkhamHorrorCompanionTests
//
//  Created by Tiago Bras on 22/10/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation

@testable import ArkhamHorrorKit
@testable import GRDB

final class DatabaseTestsHelper {
    static func inReadOnly(dbVersion: AHDatabaseMigrator.MigrationVersion?,  _ handler: (Database) throws -> ()) rethrows {
        let dbQueue = DatabaseQueue()
        
        try! AHDatabaseMigrator().migrate(database: dbQueue, upTo: dbVersion)
        
        try! dbQueue.read({ (db) in
            try handler(db)
        })
    }
}
