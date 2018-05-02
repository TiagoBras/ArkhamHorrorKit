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
                                withIntermediateDirectories: true,
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
        requiredCardsTest(for: 1001, requiredCards: [1006: 1, 1007: 1])
        requiredCardsTest(for: 1002, requiredCards: [1008: 1, 1009: 1])
        requiredCardsTest(for: 1003, requiredCards: [1010: 1, 1011: 1])
        requiredCardsTest(for: 1004, requiredCards: [1012: 1, 1013: 1])
        requiredCardsTest(for: 1005, requiredCards: [1014: 1, 1015: 1])
        requiredCardsTest(for: 2001, requiredCards: [2006: 1, 2007: 1])
        requiredCardsTest(for: 2002, requiredCards: [2008: 1, 2009: 1])
        requiredCardsTest(for: 2003, requiredCards: [2010: 1, 2011: 1])
        requiredCardsTest(for: 2004, requiredCards: [2012: 1, 2013: 1])
        requiredCardsTest(for: 2005, requiredCards: [2014: 1, 2015: 1])
        requiredCardsTest(for: 3001, requiredCards: [3007: 1, 3008: 1, 3009: 1])
        requiredCardsTest(for: 3002, requiredCards: [3010: 1, 3011: 1])
        requiredCardsTest(for: 3003, requiredCards: [3012: 3, 3013: 1])
        requiredCardsTest(for: 3004, requiredCards: [3014: 1, 3015: 1])
        requiredCardsTest(for: 3005, requiredCards: [3016: 1, 3017: 1])
        requiredCardsTest(for: 3006, requiredCards: [3018: 2, 3019: 2])
        requiredCardsTest(for: 99001, requiredCards: [99002: 1, 99003: 1])
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
        let expectedChecksum = "ea059854ab5a2e38d89f847be69fd067337428bb322f273379bd10c8c7b47fe9"
        
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
    
    func testCleanUp() {
        let investigator = try! db.investigators().first!
        let cards = db.cardStore.fetchCards(filter: nil, sorting: nil)
        
        XCTAssertGreaterThan(cards.count, 10)
        
        let deck = try! db.deckStore.createDeck(name: "Roland Shotguns", investigator: investigator)
        
        try! db.dbQueue.write { dbConn in
            for i in 0..<4 {
                let record = DeckCardRecord(deckId: deck.id, cardId: cards[i].id, quantity: 1)
                try record.save(dbConn)
            }
            
            for i in 4..<10 {
                let record = DeckCardRecord(deckId: deck.id, cardId: cards[i].id, quantity: 0)
                try record.save(dbConn)
            }
        }
        
        var (zeroQuantity, oneQuantity) = deckCardQuantityCounter(for: deck, database: db)
        
        XCTAssertEqual(zeroQuantity, 6)
        XCTAssertEqual(oneQuantity, 4)
        
        try! db.cleanUp()
        
        (zeroQuantity, oneQuantity) = deckCardQuantityCounter(for: deck, database: db)
        
        XCTAssertEqual(zeroQuantity, 0)
        XCTAssertEqual(oneQuantity, 4)
    }
    
    func testLolaInvestigatorAdditionalRequirements() {
        var deck = DatabaseTestsHelper.createDeck(
            name: "Jack-of-all-trades",
            investigatorId: Investigator.InvestigatorId.lolaHayesTheActress.rawValue,
            in: db)
        
        XCTAssertEqual(deck.validateDeck().isValid, false)

        var neutralCards = db.cardStore.fetchCards(filter: CardFilter(faction: .neutral), sorting: nil)
        var guardianCards = db.cardStore.fetchCards(filter: CardFilter(faction: .guardian), sorting: nil)
        var seekerCards = db.cardStore.fetchCards(filter: CardFilter(faction: .seeker), sorting: nil)
        var rogueCards = db.cardStore.fetchCards(filter: CardFilter(faction: .rogue), sorting: nil)
        var survivorCards = db.cardStore.fetchCards(filter: CardFilter(faction: .survivor), sorting: nil)
        
        func filterOutWeaknesses(_ cards: inout [Card]) {
            cards = cards.filter({ !$0.isWeakness })
        }
        
        filterOutWeaknesses(&neutralCards)
        filterOutWeaknesses(&guardianCards)
        filterOutWeaknesses(&seekerCards)
        filterOutWeaknesses(&rogueCards)
        filterOutWeaknesses(&survivorCards)
        
        // 11
        deck.changeQuantity(of: neutralCards[0], quantity: 2)
        deck.changeQuantity(of: neutralCards[1], quantity: 2)
        deck.changeQuantity(of: neutralCards[2], quantity: 2)
        deck.changeQuantity(of: neutralCards[3], quantity: 2)
        deck.changeQuantity(of: neutralCards[4], quantity: 2)
        deck.changeQuantity(of: neutralCards[5], quantity: 1)
        
        // 11 + 6 = 17
        deck.changeQuantity(of: guardianCards[0], quantity: 2)
        deck.changeQuantity(of: guardianCards[1], quantity: 2)
        deck.changeQuantity(of: guardianCards[2], quantity: 2)

        // 17 + 6 = 23
        deck.changeQuantity(of: seekerCards[0], quantity: 2)
        deck.changeQuantity(of: seekerCards[1], quantity: 2)
        deck.changeQuantity(of: seekerCards[2], quantity: 2)
        
        // 23 + 6 = 29
        deck.changeQuantity(of: rogueCards[0], quantity: 2)
        deck.changeQuantity(of: rogueCards[1], quantity: 2)
        deck.changeQuantity(of: rogueCards[2], quantity: 2)
        
        // 29 + 6 = 35
        deck.changeQuantity(of: survivorCards[0], quantity: 2)
        deck.changeQuantity(of: survivorCards[1], quantity: 2)
        deck.changeQuantity(of: survivorCards[2], quantity: 2)
        
        XCTAssertEqual(deck.numberOfCards(ignorePermanentCards: true), 35)
        XCTAssertEqual(deck.validateDeck().isValid, false)
        XCTAssertEqual(deck.validateDeck().message, "Check deck aditional requirements")
        
        deck.changeQuantity(of: survivorCards[0], quantity: 1)  // -1
        deck.changeQuantity(of: survivorCards[1], quantity: 1)  // -1
        deck.changeQuantity(of: guardianCards[3], quantity: 1)  // +1
        deck.changeQuantity(of: seekerCards[3], quantity: 1)    // +1
        XCTAssertEqual(deck.validateDeck().isValid, false)
        XCTAssertEqual(deck.validateDeck().message, "Check deck aditional requirements")
        
        deck.changeQuantity(of: survivorCards[0], quantity: 0)  // -1
        deck.changeQuantity(of: rogueCards[3], quantity: 1)     // +1
        
        XCTAssertEqual(deck.validateDeck().isValid, true)
    }
    
    private func deckCardQuantityCounter(for deck: Deck,
                                         database: AHDatabase) -> (zeroQuantity: Int, oneQuantity: Int) {
        return try! database.dbQueue.read({ (db) -> (zeroQuantity: Int, oneQuantity: Int) in
            let deckCards = try DeckCardRecord.fetchAll(db: db, deckId: deck.id)
            
            var zeroQuantity = 0
            var oneQuantity = 0
            
            for deckCard in deckCards {
                if deckCard.quantity == 0 {
                    zeroQuantity += 1
                } else if deckCard.quantity == 1 {
                    oneQuantity += 1
                }
            }
            
            return (zeroQuantity, oneQuantity)
        })
    }
    
    private func requiredCardsTest(for investigatorId: Int, requiredCards: [Int: Int]) {
        let investigators = try! db.investigatorsDictionary()
        
        let investigator = investigators[investigatorId]!
        let expected = requiredCards.map { (id, quantity) -> DeckCard in
            let card = DatabaseTestsHelper.fetchCard(id: id, in: db)
            
            return DeckCard(card: card, quantity: quantity)
            }.sorted()
        
        XCTAssertEqual(investigator.requiredCards.sorted(), expected)
    }
}
