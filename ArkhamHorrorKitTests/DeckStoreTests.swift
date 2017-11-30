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
    typealias CardPair = DatabaseTestsHelper.CardIdQuantityPair
    
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
    
    func testFetchDeck() {
        let deck = DatabaseTestsHelper.createDeck(name: "Roland Shotguns",
                                                  investigator: roland,
                                                  in: database)
        
        let deckId = try! database.dbQueue.read({ (db) -> Int in
            return try DeckRecord.fetchAll(db).first!.id!
        })
        
        let fetchedDeck = try! database.deckStore.fetchDeck(id: deckId)!
        
        XCTAssertEqual(fetchedDeck.name, deck.name)
    }
    
    func testFetchAllDecks() {
        let cardIdQuantities: [CardPair] = [
            CardPair(1021, 2), CardPair(1022, 1), CardPair(1023, 2), CardPair(1024, 2)
        ]
        
        for i in 0..<10 {
            DatabaseTestsHelper.createDeck(
                name: "Roland Nr: \(i)",
                investigator: roland,
                cards: cardIdQuantities,
                in: database)
        }
        
        let decks = try! database.deckStore.fetchAllDecks()
        
        XCTAssertEqual(decks.count, 10)
    }
    
    func testChangeDeckName() {
        let deck = DatabaseTestsHelper.createDeck(name: "Roland Shotguns",
                                                  investigator: roland,
                                                  in: database)
        
        _ = try! database.deckStore.changeDeckName(deck: deck, to: "Zombie Killer")
        
        let fetchedDeck = try! database.deckStore.fetchDeck(id: deck.id)!
        
        XCTAssertEqual(fetchedDeck.name, "Zombie Killer")
    }
}
