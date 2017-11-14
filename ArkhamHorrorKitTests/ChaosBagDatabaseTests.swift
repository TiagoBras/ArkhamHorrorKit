//
//  ChaosBagDatabaseTests.swift
//  ArkhamHorrorKit iOSTests
//
//  Created by Tiago Bras on 10/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import XCTest

@testable import ArkhamHorrorKit
@testable import GRDB

class ChaosBagDatabaseTests: XCTestCase {
    var db: ChaosBagDatabase!
    
    override func setUp() {
        super.setUp()
        
        db = try! ChaosBagDatabase()
    }
    
    func testMigrationV1() {
        db = try! ChaosBagDatabase(
            version: ChaosBagDatabaseMigrator.MigrationVersion.v1)
        
        db.dbQueue.read { (db) in
            let tables = ["Campaign", "Scenario", "ChaosBag", "ScenarioChaosBag"]
            
            for table in tables {
                let info = tableInfo(db, tableName: table)
                
                XCTAssert(info != nil, "\(table) doesn't not exist")
            }
        }
    }
    
    func testLoadJSON() {
        let url = Bundle(for: type(of: self)).url(forResource: "chaos_bags", withExtension: "json")!
        
        try! db.updateDatabase(jsonURL: url)
        
        let campaigns = try! db.campaignFetchAll()
        
        XCTAssertEqual(campaigns.count, 2)
        
        XCTAssertEqual(campaigns[0].scenarios.count, 1)
        XCTAssertEqual(campaigns[0].scenarios[0].name, "Night of the Zealot")
        
        XCTAssertEqual(campaigns[1].scenarios.count, 2)
        XCTAssertEqual(campaigns[1].scenarios[0].name, "Dunwich Legacy")
        XCTAssertEqual(campaigns[1].scenarios[1].name, "Miskatonic Museum Standalone")
        
        let scenarios = try! db.fetchScenarios(campaignId: campaigns[1].id)
        
        XCTAssertEqual(scenarios.count, 2)
        XCTAssertEqual(scenarios[0].name, "Dunwich Legacy")
        XCTAssertEqual(scenarios[1].name, "Miskatonic Museum Standalone")
    }
    
    func testCreateChaosBag() {
        var tokens = [ChaosToken: Int]()
        tokens[ChaosToken.p1] = 1
        tokens[ChaosToken.zero] = 2
        tokens[ChaosToken.m1] = 3
        tokens[ChaosToken.m2] = 4
        tokens[ChaosToken.m3] = 5
        tokens[ChaosToken.m4] = 6
        tokens[ChaosToken.m5] = 7
        tokens[ChaosToken.m6] = 8
        tokens[ChaosToken.m7] = 9
        tokens[ChaosToken.m8] = 10
        tokens[ChaosToken.skull] = 11
        tokens[ChaosToken.autofail] = 12
        tokens[ChaosToken.tablet] = 13
        tokens[ChaosToken.cultist] = 14
        tokens[ChaosToken.eldersign] = 15
        tokens[ChaosToken.elderthing] = 16
        
        var bag = try! db.createChaosBag(tokens: tokens)
        
        XCTAssertEqual(bag.tokensDictionary, tokens)
        
        bag = try! db.fetchChaosBag(id: bag.id)
        
        XCTAssertEqual(bag.tokensDictionary, tokens)
    }
    
    func testCreateCampaign() {
        let campaign = try! db.createCampaign(name: "Custom Campaigns")
        
        let fetchedCampaign = try! db.fetchCampaign(id: campaign.id)
        
        XCTAssertEqual(fetchedCampaign.name, "Custom Campaigns")
        XCTAssertEqual(fetchedCampaign.scenarios.count, 0)
    }
    
    func testCreateCampaignWhenNameAlreadyExists() {
        let name = "Custom Campaigns"
        _ = try! db.createCampaign(name: name)
        
        XCTAssertThrowsError(
        try db.createCampaign(name: "Custom Campaigns"),
        "Should throw that name already exists") { (error) in
            if case let ChaosBagDatabaseError.campaignNameAlreadyExists(aName) = error {
                XCTAssertEqual(name, aName)
            } else {
                XCTFail()
            }
        }
    }
    
    func testSaveChaosBag() {
        
    }
    
    func testFetchNonScenarioChaosBags() {
        var nonScenarioCount = try! db.fetchChaosBags(scenarioId: nil).count
        
        XCTAssertEqual(nonScenarioCount, 0)
        
        _ = try! db.createChaosBag(tokens: [:])
        _ = try! db.createChaosBag(tokens: [:])
        _ = try! db.createChaosBag(tokens: [:])
        _ = try! db.createChaosBag(tokens: [:])
        let bag = try! db.createChaosBag(
            tokens: [ChaosToken.cultist: 23])
        _ = try! db.createChaosBag(tokens: [:])
        _ = try! db.createChaosBag(tokens: [:])
        _ = try! db.createChaosBag(tokens: [:])
        
        nonScenarioCount = try! db.fetchChaosBags(scenarioId: nil).count
        
        XCTAssertEqual(nonScenarioCount, 8)
        
        let fetchedBag = try! db.fetchChaosBag(id: bag.id)
        
        XCTAssertEqual(fetchedBag, bag)
    }
    
    private func tableInfo(_ db: Database, tableName: String) -> TableInfo? {
        guard let rows = try? Row.fetchAll(db, "pragma table_info(\(tableName))"), rows.count > 0 else {
            return nil
        }
        
        return TableInfo(rows: rows)
    }
}
