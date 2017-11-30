//
//  CardFiltersTests.swift
//  ArkhamHorrorKit
//
//  Created by Tiago Bras on 30/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import XCTest
@testable import ArkhamHorrorKit

class CardFiltersTests: XCTestCase {
    func testSetHideWeakness() {
        var filter = CardFilter()
        filter.and(CardFilter())
        
        XCTAssert(filter.hideWeaknesses == nil)
        XCTAssert(filter.subfilters[0].filter.hideWeaknesses == nil)
        
        filter.setHideWeaknesses(false, applyToSubFilters: false)
        XCTAssert(filter.hideWeaknesses! == false)
        XCTAssert(filter.subfilters[0].filter.hideWeaknesses == nil)
        
        filter.setHideWeaknesses(true, applyToSubFilters: true)
        XCTAssert(filter.hideWeaknesses! == true)
        XCTAssert(filter.subfilters[0].filter.hideWeaknesses! == true)
    }
    
    func testSetFullTextSearch() {
        var filter = CardFilter()
        filter.and(CardFilter())
        
        XCTAssert(filter.fullTextSearchMatch == nil)
        XCTAssert(filter.subfilters[0].filter.fullTextSearchMatch == nil)
        
        filter.setFullTextSearchMatch("necro", applyToSubFilters: false)
        XCTAssert(filter.fullTextSearchMatch! == "necro")
        XCTAssert(filter.subfilters[0].filter.fullTextSearchMatch == nil)
        
        filter.setFullTextSearchMatch("hide", applyToSubFilters: true)
        XCTAssert(filter.fullTextSearchMatch! == "hide")
        XCTAssert(filter.subfilters[0].filter.fullTextSearchMatch! == "hide")
    }
}
