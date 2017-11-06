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
        var deck = try! database.deckStore.createDeck(name: "The God Killer", investigator: roland)
        
        XCTAssertEqual(deck.name, "The God Killer")
        XCTAssertEqual(deck.numberOfCards, 0)
        
        deck = update(deck: deck, cardId: 1010, quantity: 2)
        deck = update(deck: deck, cardId: 1011, quantity: 1)
        
        XCTAssertEqual(deck.numberOfCards, 3)
    
        let recordsCountBeforeDelete = try! database.dbWriter.read { (db) -> Int in
            return try DeckCardRecord.fetchCount(db)
        }
        
        XCTAssertEqual(recordsCountBeforeDelete, 2)
        
        try! database.deckStore.deleteDeck(deck)
        
        let recordsCountAfterDelete = try! database.dbWriter.read { (db) -> Int in
            return try DeckCardRecord.fetchCount(db)
        }
        
        XCTAssertEqual(recordsCountAfterDelete, 0)
    }
    
    // MARK:- Helper functions
    private func fetchCard(id: Int) -> Card {
        return try! database.cardStore.fetchCard(id: id)
    }
    
    private func update(deck: Deck, cardId: Int, quantity: Int) -> Deck {
        return try! database.deckStore.changeCardQuantity(deck: deck,
                                                          card: fetchCard(id: cardId),
                                                          quantity: quantity)
    }
}
