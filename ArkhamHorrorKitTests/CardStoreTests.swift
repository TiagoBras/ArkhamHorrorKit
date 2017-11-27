//
//  CardStoreTests.swift
//  ArkhamHorrorKit
//
//  Created by Tiago Bras on 06/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import XCTest

@testable import ArkhamHorrorKit

class CardStoreTests: XCTestCase {
    var database: AHDatabase!
    
    
    override func setUp() {
        super.setUp()
        database = try! AHDatabase()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFetchCard() {
        let card = try! database.cardStore.fetchCard(id: 3017)
        
        XCTAssertEqual(card.id, 3017)
        XCTAssertEqual(card.position, 17)
        XCTAssertEqual(card.level, 0)
        XCTAssertEqual(card.cost, 0)
        XCTAssertEqual(card.quantity, 1)
        XCTAssertEqual(card.deckLimit, 1)
        XCTAssertEqual(card.name, "Graveyard Ghouls")
        XCTAssertEqual(card.subname, "")
        XCTAssertEqual(card.isUnique, false)
        XCTAssertEqual(card.text, "<b>Prey</b> - William Yorick only.\nHunter.\nWhile Graveyard Ghouls is engaged with you, cards cannot leave your discard pile.")
        XCTAssertEqual(card.type, CardType.enemy)
        XCTAssertEqual(card.subtype!, CardSubtype.weakness)
        XCTAssertEqual(card.faction, CardFaction.neutral)
        XCTAssertEqual(card.doubleSided, false)
        
        let pack = try! database.cardPacksDictionary()["ptc"]!
        
        XCTAssertEqual(card.pack, pack)
        XCTAssertEqual(card.assetSlot, nil)
        XCTAssertEqual(card.traits, "Humanoid. Monster. Ghoul.")
        XCTAssertEqual(card.skillAgility, 0)
        XCTAssertEqual(card.skillCombat, 0)
        XCTAssertEqual(card.skillIntellect, 0)
        XCTAssertEqual(card.skillWillpower, 0)
        XCTAssertEqual(card.skillWild, 0)
        XCTAssertEqual(card.health, 0)
        XCTAssertEqual(card.sanity, 0)
        
        let investigator = try! database.investigatorsDictionary()[3005]!
        
        XCTAssertEqual(card.restrictedToInvestigator, investigator)
        XCTAssertEqual(card.flavorText, "\"Hell is empty and all the devils are here.\"\n - William Shakespeare, The Tempest")
        XCTAssertEqual(card.illustrator, "Mike Capprotti")
        XCTAssertEqual(card.enemyFight, 3)
        XCTAssertEqual(card.enemyEvade, 2)
        XCTAssertEqual(card.enemyHealth, 3)
        XCTAssertEqual(card.enemyDamage, 1)
        XCTAssertEqual(card.enemyHorror, 1)
        XCTAssertEqual(card.enemyHealthPerInvestigator, false)
        XCTAssertEqual(card.frontImageName, "03017.jpeg")
        XCTAssert(card.backImageName == nil)
    }
    
    func testFetchCards() {
        let cards = database.cardStore.fetchCards(filter: nil, sorting: nil)
        
        XCTAssertEqual(cards.count, 255)
    }
    
    func testFetchAllCards() {
        let result = database.cardStore.fetchCards(filter: nil, sorting: nil, groupResults: false)
        
        XCTAssertNotNil(result)
        
        XCTAssertEqual(result!.sectionsNames.count, 0)
        XCTAssertEqual(result!.numberOfCards(inSection: 0), 255)
    }
    
    func testFetchAllCardsThatBelongToADeck() {
        let cardIdQuantities: [DatabaseTestsHelper.CardIdQuantityPair] = [
            (1021, 2), (1022, 1), (1023, 2)
        ]
        var filter = CardFilter()
        filter.onlyDeck = DatabaseTestsHelper.createDeck(
            name: "Roland",
            investigator: try! database.investigatorsDictionary()[1001]!,
            cards: cardIdQuantities, in: database)
        let result = database.cardStore.fetchCards(filter: filter, sorting: nil, groupResults: false)

        XCTAssertNotNil(result)

        XCTAssertEqual(result!.numberOfCards(inSection: 0), 3)
    }
}
