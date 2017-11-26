//
//  CardImageStoreTests.swift
//  ArkhamHorrorKit
//
//  Created by Tiago Bras on 26/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import XCTest

@testable import ArkhamHorrorKit

class CardImageStoreTests: XCTestCase {
    func testExample() {
        let promise = expectation(description: "Card Image Download")
        let serverDir = URL(string: "https://appassets.nyc3.digitaloceanspaces.com/ahassets/images")!
        let userDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let localDir = userDir.appendingPathComponent("card_images")
        
        let fm = FileManager.default
        try! fm.createDirectory(at: localDir, withIntermediateDirectories: true, attributes: nil)
        
        let imageStore = try! CardImageStore(serverDir: serverDir, localDir: localDir, cacheSize: 10)
        let card = DatabaseTestsHelper.fetchCard(id: 1032, in: try! AHDatabase())

        try! imageStore.getFrontImage(card: card) { (image, error) in
            XCTAssert(error == nil)
            XCTAssert(image != nil)
            
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 20.0)
        
        imageStore.cache.clear()
        
        let promise2 = expectation(description: "Card Image Download (local)")
        
        try! imageStore.getFrontImage(card: card) { (image, error) in
            XCTAssert(error == nil)
            XCTAssert(image != nil)
            
            promise2.fulfill()
        }
        
        wait(for: [promise2], timeout: 20.0)
        
        try! fm.removeItem(at: localDir)
    }
}
