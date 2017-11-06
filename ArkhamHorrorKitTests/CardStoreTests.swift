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
    
    func testFetchCards() {
        let result = database.cardStore.fetchCards(filter: nil, sorting: nil, groupResults: false)
        
        XCTAssertNotNil(result)
        
        XCTAssertGreaterThan(result!.numberOfCards(inSection: 0), 100)
    }
}
