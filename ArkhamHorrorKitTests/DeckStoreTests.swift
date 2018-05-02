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
        XCTAssertEqual(deck.numberOfCards(ignorePermanentCards: true), 0)
        
        deck = DatabaseTestsHelper.update(deck: deck, cardId: 1012, quantity: 2, in: database)
        deck = DatabaseTestsHelper.update(deck: deck, cardId: 1032, quantity: 1, in: database)
        deck = DatabaseTestsHelper.update(deck: deck, cardId: 2185, quantity: 2, in: database)
        
        print(DatabaseTestsHelper.fetchCard(id: 1012, in: database).isWeakness)
        print(DatabaseTestsHelper.fetchCard(id: 1032, in: database).isWeakness)
        print(DatabaseTestsHelper.fetchCard(id: 2185, in: database).isWeakness)

        XCTAssertEqual(deck.numberOfCards(ignorePermanentCards: true), 3)
        XCTAssertEqual(deck.numberOfCards(ignorePermanentCards: false), 5)
        
        let recordsCountBeforeDelete = try! database.dbQueue.read { (db) -> Int in
            return try DeckCardRecord.fetchCount(db)
        }
        
        XCTAssertEqual(recordsCountBeforeDelete, 3)
        
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
    
    func testCreateDeckFromAnotherDeck() {
        let deckV1 = DatabaseTestsHelper.createDeck(name: "Awesome", investigator: roland, in: database)
        
        XCTAssertEqual(deckV1.version, 1)
        XCTAssert(deckV1.prevDeckVersionId == nil)
        XCTAssert(deckV1.nextDeckVersionId == nil)
        
        let deckV2 = try! database.deckStore.createDeck(name: "Awesome V2", from: deckV1)
        
        XCTAssertEqual(deckV2.version, 2)
        XCTAssertEqual(deckV2.prevDeckVersionId!, deckV1.id)
        XCTAssert(deckV2.nextDeckVersionId == nil)
        
        let updatedDeckV1 = try! database.deckStore.fetchDeck(id: deckV1.id)!
        XCTAssertEqual(updatedDeckV1.version, 1)
        XCTAssert(updatedDeckV1.prevDeckVersionId == nil)
        XCTAssertEqual(updatedDeckV1.nextDeckVersionId!, deckV2.id)
    }
    
    func testDeckDeltas() {
        typealias Pair = DatabaseTestsHelper.CardIdQuantityPair
        
        let cards1: [Pair] = [Pair(1040, 1), Pair(1041, 2), Pair(1042, 2)]
        let deck1 = DatabaseTestsHelper.createDeck(
            name: "Deck1",
            investigatorId: Investigator.InvestigatorId.rexMurphyTheReporter.rawValue,
            cards: cards1,
            in: database)
        let xp1 = deck1.cards.reduce(0, { $0 + ($1.card.level * $1.quantity) })
        
        let cards2: [Pair] = [Pair(1040, 2), Pair(1041, 1), Pair(1043, 1)]
        let deck2 = DatabaseTestsHelper.createDeck(
            name: "Deck2",
            investigatorId: Investigator.InvestigatorId.rexMurphyTheReporter.rawValue,
            cards: cards2,
            in: database)
        let xp2 = deck2.cards.reduce(0, { $0 + ($1.card.level * $1.quantity) })
        
        let delta = deck1.calculateDeckDelta(deck2)
        
        let c1040 = DatabaseTestsHelper.fetchCard(id: 1040, in: database)
        let c1041 = DatabaseTestsHelper.fetchCard(id: 1041, in: database)
        let c1042 = DatabaseTestsHelper.fetchCard(id: 1042, in: database)
        let c1043 = DatabaseTestsHelper.fetchCard(id: 1043, in: database)
        
        let addedExpected = Set([
            DeckCard(card: c1040, quantity: 1),
            DeckCard(card: c1043, quantity: 1)
            ])
        let removedExpected = Set([
            DeckCard(card: c1041, quantity: 1),
            DeckCard(card: c1042, quantity: 2)
            ])
        
        XCTAssertEqual(xp2 - xp1, delta.xp)
        XCTAssertEqual(delta.cardsAdded, addedExpected)
        XCTAssertEqual(delta.cardsRemoved, removedExpected)
    }
    
    func testChangeCardQuantity() {
        var deck = DatabaseTestsHelper.createDeck(
            name: "Spy",
            investigatorId: Investigator.InvestigatorId.rolandBanksTheFed.rawValue,
            in: database)
        
        let shotgun = DatabaseTestsHelper.fetchCard(id: 1029, in: database)
        
        _ = try! database.deckStore.changeCardQuantity(deck: deck, card: shotgun, quantity: 1)
        deck = (try! database.deckStore.fetchDeck(id: deck.id))!
        XCTAssertEqual(deck.cards.first!.quantity, 1)
        
        _ = try! database.deckStore.changeCardQuantity(deck: deck, card: shotgun, quantity: 2)
        deck = (try! database.deckStore.fetchDeck(id: deck.id))!
        XCTAssertEqual(deck.cards.first!.quantity, 2)
        
        let updatedDeck = try! database.deckStore.changeCardQuantity(deck: deck, card: shotgun, quantity: 0)
        XCTAssertEqual(updatedDeck.numberOfCards(ignorePermanentCards: true), 0)
        
        deck = (try! database.deckStore.fetchDeck(id: deck.id))!
        XCTAssertEqual(updatedDeck.numberOfCards(ignorePermanentCards: true), 0)
    }
}

