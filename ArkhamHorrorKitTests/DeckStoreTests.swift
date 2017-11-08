//
//  DeckStoreTests.swift
//  ArkhamHorrorKit
//
//  Created by Tiago Bras on 06/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import XCTest

@testable import ArkhamHorrorKit

class DeckStoreTests: XCTestCase {
    var database: AHDatabase!
    
    override func setUp() {
        super.setUp()
        
        database = try! AHDatabase()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    var roland: Investigator {
        return (try! database.investigatorsDictionary())[1001]!
    }
    
    func testRolandIsReallyRoland() {
        XCTAssertEqual(roland.name, "Roland Banks")
    }
    
    func testCreateDeck() {
        var deck = DatabaseTestsHelper.createDeck(name: "The God Killer",
                                                  investigator: roland,
                                                  in: database)
        
        XCTAssertEqual(deck.name, "The God Killer")
        XCTAssertEqual(deck.numberOfCards, 0)
        
        deck = DatabaseTestsHelper.update(deck: deck, cardId: 1010, quantity: 2, in: database)
        deck = DatabaseTestsHelper.update(deck: deck, cardId: 1011, quantity: 1, in: database)
        
        XCTAssertEqual(deck.numberOfCards, 3)
    
        let recordsCountBeforeDelete = try! database.dbQueue.read { (db) -> Int in
            return try DeckCardRecord.fetchCount(db)
        }
        
        XCTAssertEqual(recordsCountBeforeDelete, 2)
        
        try! database.deckStore.deleteDeck(deck)
        
        let recordsCountAfterDelete = try! database.dbQueue.read { (db) -> Int in
            return try DeckCardRecord.fetchCount(db)
        }
        
        XCTAssertEqual(recordsCountAfterDelete, 0)
    }
}
