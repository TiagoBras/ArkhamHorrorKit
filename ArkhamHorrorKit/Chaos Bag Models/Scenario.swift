//
//  Scenario.swift
//  ArkhamHorrorKit
//
//  Created by Tiago Bras on 10/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation
import GRDB

public struct Scenario {
    public let id: Int
    public var name: String
    public var iconName: String?
    public var protected: Bool
    
    // TODO: change to private
    public internal(set) var chaosBags: [ChaosBag]
    
    public func update(_ database: ChaosBagDatabase) throws {
        try database.dbQueue.write({ (db) in
            guard let record = try ScenarioRecord
                .fetchOne(db, key: ["id": id]) else {
                    throw ChaosBagDatabaseError.scenarioNotFound(id)
            }
            
            // Update record if necessary
            record.name = name
            record.iconName = iconName
            record.protected = protected
            
            if record.hasPersistentChangedValues {
                try record.update(db)
            }
        })
    }
    
    public func delete(_ database: ChaosBagDatabase) throws {
        try database.dbQueue.write({ (db) in
            guard let record = try ScenarioRecord.fetchOne(
                db, key: ["id": id]) else {
                    throw ChaosBagDatabaseError.scenarioNotFound(id)
            }
            
            try record.delete(db)
        })
    }
    
    static func create(
        _ database: ChaosBagDatabase,
        name: String,
        campaignId: Int,
        iconName: String? = nil,
        protected: Bool,
        chaosBags: [ChaosBag]? = nil) throws -> Scenario {
        let scenario = try database.dbQueue.write({
            (db) -> Scenario in
            let record = ScenarioRecord(name: name,
                                        iconName: iconName,
                                        campaignId: campaignId,
                                        protected: protected)
            try record.insert(db)
            
            return Scenario.makeScenario(
                record: record,
                chaosBags: chaosBags ?? [])
        })
        
        return scenario
    }
    
    public mutating func addChaosBag(_ database: ChaosBagDatabase, tokens: [ChaosToken: Int], protected: Bool) throws {
        let record = ChaosBagRecord(tokens: tokens, protected: protected)
        
        let chaosBag = try database.dbQueue.write { (db) -> ChaosBag in
            try record.insert(db)
            
            return ChaosBag.makeChaosBag(record: record)
        }
        
        chaosBags.append(chaosBag)
    }
    
    public mutating func removeChaosBag(_ database: ChaosBagDatabase, chaosBag: ChaosBag) throws {
        guard let index = chaosBags.index(of: chaosBag) else { return }
        
        let removedChaosBag = chaosBags.remove(at: index)
        
        try removedChaosBag.delete(database)
    }
    
    public mutating func replaceChaosBag(
        _ database: ChaosBagDatabase,
        old: ChaosBag,
        new: ChaosBag) throws {
        guard let index = chaosBags.index(of: old) else { return }
        
        chaosBags.remove(at: index)
        chaosBags.insert(new, at: index)
    }
    
    static func makeScenario(record: ScenarioRecord, chaosBags: [ChaosBag]) -> Scenario {
        return Scenario(id: record.id!,
                        name: record.name,
                        iconName: record.iconName,
                        protected: record.protected,
                        chaosBags: chaosBags)
    }
}
