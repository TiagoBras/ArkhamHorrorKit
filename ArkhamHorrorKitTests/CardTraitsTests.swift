//
//  CardTraitsTests.swift
//  ArkhamHorrorKit
//
//  Created by Tiago Bras on 29/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import XCTest
@testable import ArkhamHorrorKit

class CardTraitsTests: XCTestCase {
    var db: AHDatabase!
    override func setUp() {
        super.setUp()
        
        db = try! AHDatabase()
    }
    
    func testCardTraits() {
        let card = try! db.cardStore.fetchCard(id: 2020)
        let expectedTraits = Set<String>(["Ally", "Miskatonic", "Science"])
        
        XCTAssertEqual(card.traits.count, 3)
        XCTAssertEqual(Set<String>(card.traits), expectedTraits)
    }
}
