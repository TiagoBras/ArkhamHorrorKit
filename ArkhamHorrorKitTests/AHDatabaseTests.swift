//
//  AHDatabaseTests.swift
//  ArkhamHorrorKit
//
//  Created by Tiago Bras on 07/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import XCTest

@testable import ArkhamHorrorKit

class AHDatabaseTests: XCTestCase {
    var db: AHDatabase!
    let server = URL(string: "https://bitmountains.herokuapp.com")!
    let userDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fm = FileManager.default
    let authToken = getEnvironmentVar("MAGIC_TOKEN")!
    
    override func setUp() {
        super.setUp()
        db = try! AHDatabase()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testLoadingAModifiedJSONFile() {
        let url = Bundle(for: type(of: self)).url(forResource: "base_core_updated", withExtension: "json")!
        
        var roland = db.cardStore.investigators[1001]
        
        XCTAssert(roland != nil)
        XCTAssertEqual(roland!.name, "Roland Banks")
        
        try! db.loadCardsAndInvestigatorsFromJSON(at: url)
        
        roland = db.cardStore.investigators[1001]
        
        XCTAssertNotNil(roland)
        XCTAssertEqual(roland!.name, "Roland Banks Master")
    }
    
    func testLoadingUpdatedPacksFile() {
        let url = Bundle(for: type(of: self)).url(forResource: "packs_update", withExtension: "json")!
        
        let pack = try! db.cardPacksDictionary()["dp"]
        
        XCTAssertNil(pack)
        
        try! db.loadPacksFromJSON(at: url)
        
        let updatedPack = try! db.cardPacksDictionary()["dp"]!
        
        XCTAssertEqual(updatedPack.name, "Dummy Pack")
    }
    
    func testUpdateDatabaseFromJSONFilesAtDirectory() {
        // First lest's create the directory in documents and copy a couple of files
        let documentsDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filesDir = documentsDir.appendingPathComponent("ah_files")
        
        if fm.fileExists(atPath: filesDir.path) {
            try! fm.removeItem(at: filesDir)
        }
        
        try! fm.createDirectory(atPath: filesDir.path,
                                withIntermediateDirectories: false,
                                attributes: nil)
        
        let bundleCycles = Bundle(for: type(of: self)).url(forResource: "cyclesV1", withExtension: "json")!
        let bundlePacks = Bundle(for: type(of: self)).url(forResource: "packsV1", withExtension: "json")!
        let bundleTuo = Bundle(for: type(of: self)).url(forResource: "eotpV1", withExtension: "json")!
        
        try! fm.copyItem(at: bundleCycles, to: filesDir.appendingPathComponent("cycles.json"))
        try! fm.copyItem(at: bundlePacks, to: filesDir.appendingPathComponent("packs.json"))
        try! fm.copyItem(at: bundleTuo, to: filesDir.appendingPathComponent("eotp.json"))
        
        XCTAssertNil(try! db.cardCyclesDictionary()["ttd"])
        XCTAssertNil(try! db.cardPacksDictionary()["tmd"])
        XCTAssertEqual(try! db.cardStore.fetchCard(id: 3111).sanity, 1)
        
        let promise = expectation(description: "testUpdateDatabaseFromJSONFilesAtDirectory")
        db.updateDatabaseFromJSONFilesInDirectory(url: filesDir, completion: { (error) in
            XCTAssert(error == nil)
            XCTAssertEqual(try! self.db.cardCyclesDictionary()["ttd"]!.name, "The Test Dummy")
            XCTAssertEqual(try! self.db.cardPacksDictionary()["tmd"]!.name, "The Master Dummy")
            XCTAssertEqual(try! self.db.cardStore.fetchCard(id: 3111).sanity, 4)
            
            promise.fulfill()
        })

        wait(for: [promise], timeout: 30.0)
    }
    
    func testInvestigators() {
        let investigators = try! db.investigators()
        
        XCTAssertEqual(investigators.count, 17)
    }
    
    func testInvestigatorRequiredCards() {
        testRequiredCards(for: 1001, requiredCards: [1006: 1, 1007: 1])
        testRequiredCards(for: 1002, requiredCards: [1008: 1, 1009: 1])
        testRequiredCards(for: 1003, requiredCards: [1010: 1, 1011: 1])
        testRequiredCards(for: 1004, requiredCards: [1012: 1, 1013: 1])
        testRequiredCards(for: 1005, requiredCards: [1014: 1, 1015: 1])
        testRequiredCards(for: 2001, requiredCards: [2006: 1, 2007: 1])
        testRequiredCards(for: 2002, requiredCards: [2008: 1, 2009: 1])
        testRequiredCards(for: 2003, requiredCards: [2010: 1, 2011: 1])
        testRequiredCards(for: 2004, requiredCards: [2012: 1, 2013: 1])
        testRequiredCards(for: 2005, requiredCards: [2014: 1, 2015: 1])
        testRequiredCards(for: 3001, requiredCards: [3007: 1, 3008: 1, 3009: 1])
        testRequiredCards(for: 3002, requiredCards: [3010: 1, 3011: 1])
        testRequiredCards(for: 3003, requiredCards: [3012: 3, 3013: 1])
        testRequiredCards(for: 3004, requiredCards: [3014: 1, 3015: 1])
        testRequiredCards(for: 3005, requiredCards: [3016: 1, 3017: 1])
        testRequiredCards(for: 3006, requiredCards: [3018: 2, 3019: 2])
        testRequiredCards(for: 99001, requiredCards: [99002: 1, 99003: 1])
    }
    
    func testInvestigatorsImages() {
        let investigators = try! db.investigators()
        
        XCTAssertEqual(investigators.count, 17)
        
        for investigator in investigators {
            #if os(iOS) || os(watchOS) || os(tvOS)
                XCTAssert(investigator.avatar.uiImage != nil)
                XCTAssert(investigator.frontImage.uiImage != nil)
                XCTAssert(investigator.backImage.uiImage != nil)
            #elseif os(OSX)
                XCTAssert(investigator.avatar.nsImage != nil)
                XCTAssert(investigator.frontImage.nsImage != nil)
                XCTAssert(investigator.backImage.nsImage != nil)
            #endif
        }
    }
    
    func testCheckIfUpdateIsAvailable() {
        let promise = expectation(description: "Is Update Available")
        let database = try! AHDatabase()
        
        database.isUpdateAvailable(serverDomain: server, authenticationToken: authToken) { (bool, error) in
            if error != nil {
                XCTFail("Error should be nil")
            }
            
            if let bool = bool {
                XCTAssertTrue(bool)
            } else {
                XCTFail("Boolean should not be nil")
            }
            
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 20)
    }
    
    func testUpdateDatabase() {
        let promise = expectation(description: "Update Database")
        let database = try! AHDatabase()
        let expectedChecksum = "ffbb536c348a15da3d666e90bcec3edba1dbdb820489b72f2fb78627f6fbd7a1"
        
        database.updateDatabase(serverDomain: server,
                          authenticationToken: authToken,
                          jsonLocalDirectory: FileManager.default.temporaryDirectory) { (error) in
                            if error != nil {
                                print(error!)
                                XCTFail("Error should be nil")
                            }
                            
                            let checksum = try! database.generalInfoJsonChecksum()
                            
                            let sums = try! database.getAllJsonFilesChecksums()
                            
                            print(sums)
                            
                            XCTAssertEqual(checksum, expectedChecksum)
                            
                            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 30)
    }
    
    private func testRequiredCards(for investigatorId: Int, requiredCards: [Int: Int]) {
        let investigators = try! db.investigatorsDictionary()
        
        let investigator = investigators[investigatorId]!
        let expected = requiredCards.map { (id, quantity) -> DeckCard in
            let card = DatabaseTestsHelper.fetchCard(id: id, in: db)
            
            return DeckCard(card: card, quantity: quantity)
        }.sorted()

        XCTAssertEqual(investigator.requiredCards.sorted(), expected)
    }
}
