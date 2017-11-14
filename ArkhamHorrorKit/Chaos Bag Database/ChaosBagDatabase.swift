//
//  ChaosBagDatabase.swift
//  ArkhamHorrorKit iOS
//
//  Created by Tiago Bras on 10/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import GRDB
import SwiftyJSON

public class ChaosBagDatabase {
    public private(set) var dbQueue: DatabaseQueue
    
    public init(path: String) throws {
        dbQueue = try DatabaseQueue(path: path)
        
        try migrateToLastVersion()
    }
    
    /// Creates an in-memory database
    ///
    /// - Throws: AHDatabaseError
    public init(version: ChaosBagDatabaseMigrator.MigrationVersion? = nil) throws {
        dbQueue = DatabaseQueue()
        
        if let version = version {
            try migrateTo(version: version)
        } else {
            try migrateToLastVersion()
        }
    }
    
    public func migrateToLastVersion() throws {
        try ChaosBagDatabaseMigrator().migrate(database: dbQueue)
    }
    
    public func migrateTo(version: ChaosBagDatabaseMigrator.MigrationVersion) throws {
        try ChaosBagDatabaseMigrator().migrate(database: dbQueue, upTo: version)
    }
    
    public func campaignFetchAll() throws -> [Campaign] {
        let records = try dbQueue.read { (db) -> [CampaignRecord] in
            return try CampaignRecord.fetchAll(db)
        }
        
        return try records.map({ (campaignRecord) -> Campaign in
            let scenarios = try fetchScenarios(campaignId: campaignRecord.id!)
            
            return makeCampaign(record: campaignRecord, scenarios: scenarios)
        })
    }
    
    public func fetchCampaign(id: Int) throws -> Campaign {
        guard let record = try dbQueue.read({ (db) -> CampaignRecord? in
            return try CampaignRecord.fetchOne(db, key: ["id": id])
        }) else {
            throw ChaosBagDatabaseError.campaignNotFound(id)
        }
        
        let scenarios = try fetchScenarios(campaignId: record.id!)
        
        return makeCampaign(record: record, scenarios: scenarios)
    }
    
    public func createCampaign(name: String, iconName: String? = nil) throws -> Campaign {
        do {
            return try dbQueue.write({ (db) -> Campaign in
                let record = CampaignRecord(
                    name: name,
                    iconName: iconName,
                    protected: false)
                
                try record.insert(db)
                
                return makeCampaign(record: record, scenarios: [])
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
    
    public func fetchScenarios(campaignId: Int) throws -> [Scenario] {
        let records = try dbQueue.read({ (db) -> [ScenarioRecord] in
            return try ScenarioRecord.fetchAll(
                db,
                "SELECT * FROM \(ScenarioRecord.databaseTableName) WHERE campaign_id = ?",
                arguments: [campaignId],
                adapter: nil)
        })
        
        return try records.map { (scenarioRecord) -> Scenario in
            let bags = try fetchChaosBags(scenarioId: scenarioRecord.id!)
            
            return makeScenario(record: scenarioRecord, chaosBags: bags)
        }
    }
    
    public func fetchScenario(id: Int) throws -> Scenario {
        guard let record = try dbQueue.read({ (db) -> ScenarioRecord? in
            return try ScenarioRecord.fetchOne(db, key: ["id": id])
        }) else {
            throw ChaosBagDatabaseError.scenarioNotFound(id)
        }
        
        let bags = try fetchChaosBags(scenarioId: record.id!)
        
        return makeScenario(record: record, chaosBags: bags)
    }
    
    public func createScenario(
        name: String,
        campaign: Campaign,
        iconName: String? = nil) throws -> Scenario {
        return try dbQueue.write({ (db) -> Scenario in
            let record = ScenarioRecord(name: name,
                                        iconName: iconName,
                                        campaignId: campaign.id,
                                        protected: false)
            try record.insert(db)
            
            return makeScenario(record: record, chaosBags: [])
        })
    }
    
    public func fetchChaosBags(scenarioId: Int? = nil) throws -> [ChaosBag] {
        return try dbQueue.read({ (db) -> [ChaosBag] in
            let args: String = scenarioId != nil ? "= \(scenarioId!)" : "IS NULL"
            let sql: String = """
            SELECT C.* FROM \(ChaosBagRecord.databaseTableName) AS C
            LEFT JOIN \(ScenarioChaosBagRecord.databaseTableName) AS S ON S.chaos_bag_id = C.id
            WHERE S.scenario_id \(args)
            """
            
            let records = try ChaosBagRecord.fetchAll(db, sql)
            
            return records.map({ makeChaosBag(record: $0) })
        })
    }
    
    public func createChaosBag(tokens: [ChaosToken: Int]) throws -> ChaosBag {
        let record = ChaosBagRecord(tokens: tokens, protected: false)
        
        return try dbQueue.write { (db) -> ChaosBag in
            try record.insert(db)
            
            return makeChaosBag(record: record)
        }
    }
    
    public func saveChaosBag(tokens: [ChaosToken: Int],
                             scenario: Scenario,
                             difficulty: ChaosBagDifficulty) throws -> Scenario {
        let updatedBag: ChaosBag
        
        if let record = try dbQueue.read({ (db) -> ScenarioChaosBagRecord? in
            return try ScenarioChaosBagRecord.fetchOne(
                db, key: ["scenario_id": scenario.id, "difficulty": difficulty.rawValue])
        }) {
            // Update Bag
            updatedBag = try dbQueue.write({ (db) -> ChaosBag in
                let bag = try ChaosBagRecord.fetchOne(
                    db, key: ["id": record.chaosBagId])!
                
                bag.updateTokens(dictionary: tokens)
                
                if bag.hasPersistentChangedValues {
                    try bag.update(db)
                }
                
                return makeChaosBag(record: bag)
            })
        } else {
            updatedBag = try createChaosBag(tokens: tokens)

            // Add bag to scenario
            try dbQueue.write({ (db) in
                let record = ScenarioChaosBagRecord(
                    chaosBagId: updatedBag.id,
                    scenarioId: scenario.id,
                    difficulty: difficulty)
                
                try record.insert(db)
            })
        }
        
        // Update scenario
        var updatedScenario = scenario
        
        // Remove old bag if it exist
        if let index = updatedScenario.chaosBags.index(where: { $0.id == updatedBag.id }) {
            updatedScenario.chaosBags.remove(at: index)
        }
        updatedScenario.chaosBags.append(updatedBag)
        
        return updatedScenario
    }
    
    public func fetchChaosBag(id: Int) throws -> ChaosBag {
        return try dbQueue.read({ (db) -> ChaosBag in
            guard let record = try ChaosBagRecord.fetchOne(db, key: ["id": id]) else {
                throw ChaosBagDatabaseError.chaosBagNotFound(id)
            }
            
            return makeChaosBag(record: record)
        })
    }
    
    // MARK:- Transform Records into its respective Model
    func makeCampaign(record: CampaignRecord, scenarios: [Scenario]) -> Campaign {
        return Campaign(id: record.id!,
                        name: record.name,
                        iconName: record.iconName,
                        protected: record.protected,
                        scenarios: scenarios)
    }
    
    func makeScenario(record: ScenarioRecord, chaosBags: [ChaosBag]) -> Scenario {
        return Scenario(id: record.id!,
                        name: record.name,
                        iconName: record.iconName,
                        protected: record.protected,
                        chaosBags: chaosBags)
    }
    
    func makeChaosBag(record: ChaosBagRecord) -> ChaosBag {
        return ChaosBag(id: record.id!,
                        p1: record.p1,
                        zero: record.zero,
                        m1: record.m1,
                        m2: record.m2,
                        m3: record.m3,
                        m4: record.m4,
                        m5: record.m5,
                        m6: record.m6,
                        m7: record.m7,
                        m8: record.m8,
                        skull: record.skull,
                        autofail: record.autofail,
                        tablet: record.tablet,
                        cultist: record.cultist,
                        eldersign: record.eldersign,
                        elderthing: record.elderthing)
    }
    
    public func updateDatabase(jsonURL: URL) throws {
        let data = try Data(contentsOf: jsonURL)
        let json = JSON(data: data)
        
        try dbQueue.write({ (db) in
            for campaignJson in json.arrayValue {
                let name = campaignJson["name"].stringValue
                let iconName = campaignJson["icon_name"].string
                
                let campaignId: Int
                
                if let record = try CampaignRecord.fetchOne(db, key: ["name": name]) {
                    campaignId = record.id!
                    record.iconName = iconName
                    
                    if record.hasPersistentChangedValues {
                        try record.update(db)
                    }
                } else {
                    let record = CampaignRecord(name: name, iconName: iconName, protected: true)
                    try record.insert(db)
                    
                    campaignId = record.id!
                }
                
                for scenarioJson in campaignJson["scenarios"].arrayValue {
                    let name = scenarioJson["name"].stringValue
                    let iconName = scenarioJson["icon_name"].stringValue
                    
                    let scenarioId: Int
                   
                    let sql = """
                    SELECT *
                    FROM \(ScenarioRecord.databaseTableName)
                    WHERE name = ? AND campaign_id = ?
                    """
                    
                    if let record = try ScenarioRecord.fetchOne(
                        db,
                        sql,
                        arguments: [name, campaignId],
                        adapter: nil) {
                        
                        if record.hasPersistentChangedValues {
                            try record.update(db)
                        }
                        
                        scenarioId = record.id!
                    } else {
                        let record = ScenarioRecord(name: name,
                                                    iconName: iconName,
                                                    campaignId: campaignId,
                                                    protected: true)
                        try record.insert(db)
                        
                        scenarioId = record.id!
                    }
                    
                    for difficulty in ChaosBagDifficulty.allValues {
                        guard let bag = scenarioJson[difficulty.rawValue].dictionaryObject as? [String: Int],
                            bag.count > 0 else {
                                continue
                        }
                        
                        // Build tokens dictionary
                        var tokens: [ChaosToken: Int] = [:]
                        try bag.forEach({ (tokenRawValue, quantity) in
                            guard let token = ChaosToken(rawValue: tokenRawValue) else {
                                throw ChaosBagDatabaseError.unknownToken(tokenRawValue)
                            }
                            
                            tokens[token] = quantity
                        })
                        
                        // Get ChaosBag.id or create a new ChaosBag
                        let chaosBagId: Int
                        if let record = try ScenarioChaosBagRecord.fetchOne(
                            db,
                            key: ["scenario_id": scenarioId, "difficulty": difficulty.rawValue]) {
                            chaosBagId = record.chaosBagId
                            
                            let bagRecord = try ChaosBagRecord.fetchOne(db, key: ["id": chaosBagId])!
                            bagRecord.updateTokens(dictionary: tokens)
                            
                            if bagRecord.hasPersistentChangedValues {
                                try bagRecord.update(db)
                            }
                        } else {
                            let record = ChaosBagRecord(tokens: tokens, protected: true)
                            try record.insert(db)
                            
                            chaosBagId = record.id!
                            
                            // Create new record
                            let scenarioBagRecord = ScenarioChaosBagRecord(chaosBagId: chaosBagId,
                                                                           scenarioId: scenarioId,
                                                                           difficulty: difficulty)
                            try scenarioBagRecord.insert(db)
                        }
                        
                    }
                }
            }
        })
    }
}

public enum ChaosBagDatabaseError: Error {
    case unknownToken(String)
    case campaignNotFound(Int)
    case scenarioNotFound(Int)
    case chaosBagNotFound(Int)
    case scenarioChaosBagNotFound(Int, Int, ChaosBagDifficulty)
    case campaignNameAlreadyExists(String)
}

