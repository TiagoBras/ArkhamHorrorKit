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
        let fm = FileManager.default
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
        
        try! db.updateDatabaseFromJSONFilesInDirectory(url: filesDir)

        XCTAssertEqual(try! db.cardCyclesDictionary()["ttd"]!.name, "The Test Dummy")
        XCTAssertEqual(try! db.cardPacksDictionary()["tmd"]!.name, "The Master Dummy")
        XCTAssertEqual(try! db.cardStore.fetchCard(id: 3111).sanity, 4)
        
        try! fm.removeItem(at: filesDir)
    }
}
