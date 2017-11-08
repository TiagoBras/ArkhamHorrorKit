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
    
    func testFetchAllCards() {
        let result = database.cardStore.fetchCards(filter: nil, sorting: nil, groupResults: false)
        
        XCTAssertNotNil(result)
        
        XCTAssertEqual(result!.numberOfCards(inSection: 0), 251)
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
