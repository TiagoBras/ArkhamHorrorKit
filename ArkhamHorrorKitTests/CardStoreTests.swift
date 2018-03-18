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
    
    typealias CardPair = DatabaseTestsHelper.CardIdQuantityPair
    
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
        XCTAssertEqual(card.traits.sorted(), ["Ghoul", "Humanoid", "Monster"])
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
        
        XCTAssertEqual(cards.count, 269)
    }
    
    func testFetchAllCards() {
        let result = database.cardStore.fetchCards(filter: nil, sorting: nil, groupResults: false)
        
        XCTAssertNotNil(result)
        
        XCTAssertEqual(result!.sectionsNames.count, 0)
        XCTAssertEqual(result!.numberOfCards(inSection: 0), 269)
    }
    
    func testFetchAllCardsThatBelongToADeck() {
        
        let cardIdQuantities: [CardPair] = [
            CardPair(1021, 2), CardPair(1022, 1), CardPair(1023, 2)
        ]
        var filter = CardFilter()
        filter.deckId = DatabaseTestsHelper.createDeck(
            name: "Roland",
            investigator: try! database.investigatorsDictionary()[1001]!,
            cards: cardIdQuantities, in: database).id
        let result = database.cardStore.fetchCards(filter: filter, sorting: nil, groupResults: false)
        
        XCTAssertNotNil(result)
        
        XCTAssertEqual(result!.numberOfCards(inSection: 0), 3)
    }
    
    func testFetchCardsUsingFTS() {
        var filter = CardFilter()
        filter.fullTextSearchMatch = "45"
        let cards1 = database.cardStore.fetchCards(filter: filter, sorting: nil)
        XCTAssertEqual(cards1.count, 2)
        
        filter = CardFilter()
        filter.fullTextSearchMatch = "faction:seeker"
        let cards2 = database.cardStore.fetchCards(filter: filter, sorting: nil)
        XCTAssertEqual(cards2.count, 39)
        
        filter = CardFilter()
        filter.fullTextSearchMatch = "Percep"
        let cards3 = database.cardStore.fetchCards(filter: filter, sorting: nil)
        XCTAssertEqual(cards3.count, 1)
    }
    
    func testFetchCardsUsingSubFilters() {
        var filter = CardFilter()
        filter.factions.insert(.guardian)
        
        let cards1 = database.cardStore.fetchCards(filter: filter, sorting: nil)
        XCTAssertEqual(cards1.count, 39)
        
        // This should return all cards because subfilter = ... WHERE (..) OR 1
        filter.or(CardFilter())
        let cards2 = database.cardStore.fetchCards(filter: filter, sorting: nil)
        XCTAssertEqual(cards2.count, 269)
    }
    
    func testFetchingOnlyWeaknesses() {
        var filter = CardFilter.basicWeaknesses()
        
        let cards1 = database.cardStore.fetchCards(filter: filter, sorting: nil)
        XCTAssertEqual(cards1.count, 14)
        
        filter.subtypes = Set([CardSubtype.weakness])
        filter.hideRestrictedCards = false
        let cards2 = database.cardStore.fetchCards(filter: filter, sorting: nil)
        XCTAssertEqual(cards2.count, 17)
    }
    
    func testFetchingSubFiltersWithFTS() {
        var filter1 = CardFilter(factions: [.seeker], fromLevel: 0, toLevel: 5)
        filter1.and(CardFilter(fullSearchText: "hunc"))
        
        let cards1 = database.cardStore.fetchCards(filter: filter1, sorting: nil)
        XCTAssertEqual(cards1.count, 1)
        XCTAssertEqual(cards1[0].name, "Working a Hunch")
        
        var filter2 = CardFilter(factions: [.mystic], fromLevel: 0, toLevel: 5)
        filter2.and(CardFilter(fullSearchText: "hunc"))
        
        let cards2 = database.cardStore.fetchCards(filter: filter2, sorting: nil)
        XCTAssertEqual(cards2.count, 0)
    }
    
    func testFetchingOnlyInvestigatorsCards() {
        let filter1 = CardFilter(investigatorId: 1001)
        let cards1 = database.cardStore.fetchCards(filter: filter1, sorting: nil)
        
        XCTAssertEqual(cards1.count, 2)
    }
    
    func testFetchingWithDeckId() {
        let deck = DatabaseTestsHelper.createDeck(
            name: "James Knife",
            investigatorId: 1001,
            cards: [CardPair(1020, 2), CardPair(1021, 1), CardPair(1022, 2)],
            in: database)
        
        let filter1 = CardFilter(deckId: deck.id)
        let cards1 = database.cardStore.fetchCards(filter: filter1, sorting: nil)
        
        XCTAssertEqual(cards1.count, 3)
    }
    
    func testFetchingWithMultiplesSubFiltersAndFTS() {
        let roland = try! database.investigatorsDictionary()[1001]!
        
        var mainFilter = CardFilter(fullSearchText: "beat")
        mainFilter.hideWeaknesses = true
        mainFilter.hideRestrictedCards = true
        mainFilter.and(roland.availableCardsFilter)
        
        let cards1 = database.cardStore.fetchCards(filter: mainFilter, sorting: nil)
        
        XCTAssertEqual(cards1.count, 2)
    }
    
    func testFetchingCardsThatUsesCharges() {
        let filter = CardFilter(usesCharges: true, fromLevel: 0, toLevel: 5)
        
        let cards = database.cardStore.fetchCards(filter: filter, sorting: nil)
        
        XCTAssertEqual(cards.count, 9)
    }
    
    func testFilterWithTraitOccultLevelZero() {
        let filter = CardFilter(traits: ["Occult"], level: 0)
        let cards = database.cardStore.fetchCards(filter: filter, sorting: nil)
        
        XCTAssertEqual(cards.count, 1)
    }
    
    func testFilteringByPack() {
        var filter = CardFilter()
        filter.packs = [CardPack(id: "dwl",
                                 name: "",
                                 position: 1,
                                 size: 1,
                                 cycle: CardCycle(id: "dwl", name: "", position: 1, size: 1, cardsCount: 0), cardsCount: 0)]
        
        let cards = database.cardStore.fetchCards(filter: filter, sorting: nil)
        
        XCTAssertEqual(cards.count, 34)
    }
    
    func testProhibitedTraits() {
        var fortuneCards = Set<Card>()
        
        for card in database.cardStore.fetchCards(filter: nil, sorting: nil) {
            if card.traits.contains("Fortune") {
                fortuneCards.insert(card)
            }
        }
        
        XCTAssertTrue(fortuneCards.count > 0)
        
        let filter = CardFilter(prohibitedTraits: ["Fortune"])
        
        for card in database.cardStore.fetchCards(filter: filter, sorting: nil) {
            if card.traits.contains("Fortune") {
                XCTFail("\(card.name) has Fortune trait")
            }
        }
    }
}
