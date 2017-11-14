//
//  Campaign.swift
//  ArkhamHorrorKit
//
//  Created by Tiago Bras on 10/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation

public struct Campaign {
    public let id: Int
    public var name: String
    public var iconName: String?
    public var protected: Bool
    public internal(set) var scenarios: [Scenario]
    
    public func update(_ database: ChaosBagDatabase) throws {
        try database.dbQueue.write({ (db) in
            guard let record = try CampaignRecord
                .fetchOne(db, key: ["id": id]) else {
                    throw ChaosBagDatabaseError.campaignNotFound(id)
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
            guard let record = try CampaignRecord.fetchOne(
                db, key: ["id": id]) else {
                    throw ChaosBagDatabaseError.campaignNotFound(id)
            }
            
            try record.delete(db)
        })
    }
    
    public static func create(
        _ database: ChaosBagDatabase,
        name: String,
        iconName: String? = nil,
        protected: Bool) throws -> Campaign {
        do {
            return try database.dbQueue.write({ (db) -> Campaign in
                let record = CampaignRecord(
                    name: name,
                    iconName: iconName,
                    protected: protected)
                
                try record.insert(db)
                
                return Campaign.makeCampaign(record: record, scenarios: [])
            })
        } catch {
            let msg = "UNIQUE constraint failed: Campaign.name"
            if error.localizedDescription.contains(msg) {
                throw ChaosBagDatabaseError.campaignNameAlreadyExists(name)
            } else {
                throw error
            }
        }
    }
    
    public mutating func addScenario(
        _ database: ChaosBagDatabase,
        name: String,
        campaignId: Int,
        iconName: String? = nil,
        protected: Bool,
        chaosBags: [ChaosBag]? = nil) throws {
        let scenario = try database.dbQueue.write({ (db) -> Scenario in
            let record = ScenarioRecord(name: name,
                                        iconName: iconName,
                                        campaignId: campaignId,
                                        protected: false)
            try record.insert(db)
            
            return Scenario.makeScenario(
                record: record,
                chaosBags: chaosBags ?? [])
        })
        
        scenarios.append(scenario)
    }
    
    public mutating func removeScenario(
        _ database: ChaosBagDatabase,
        scenario: Scenario) throws {
        guard let index = scenarios.index(where: { $0.id == scenario.id }) else {
            throw ChaosBagDatabaseError.scenarioNotFound(scenario.id)
        }
        scenarios.remove(at: index)
        
        try database.dbQueue.write({ (db) in
            guard let record = try ScenarioRecord.fetchOne(
                db, key: ["id": scenario.id]) else {
                    throw ChaosBagDatabaseError.scenarioNotFound(scenario.id)
            }
            
            try record.delete(db)
        })
    }
    
    public mutating func replaceScenarios() {
        
    }
    
    static func makeCampaign(record: CampaignRecord, scenarios: [Scenario]) -> Campaign {
        return Campaign(id: record.id!,
                        name: record.name,
                        iconName: record.iconName,
                        protected: record.protected,
                        scenarios: scenarios)
    }
}
