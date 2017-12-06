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
    let serverDir = URL(string: "https://appassets.nyc3.digitaloceanspaces.com/ahassets/images")!
    let userDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fm = FileManager.default
    
    func testDownloadingOneCardImage() {
        let promise = expectation(description: "Download Front Image")
        let localDir = userDir.appendingPathComponent("card_images")
        
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
    
    func testDownloadingMissingImages() {
        let promise = expectation(description: "Download Missing Images")
        let localDir = userDir.appendingPathComponent("card_images_local")
 
        if fm.fileExists(atPath: localDir.path) {
            try! fm.removeItem(at: localDir)
        }
        
        try! fm.createDirectory(at: localDir, withIntermediateDirectories: false, attributes: nil)
        
        let db = try! AHDatabase()
        let cards = Array(1040...1045).map({ DatabaseTestsHelper.fetchCard(id: $0, in: db) })
        let sourceURL = Bundle(for: CardImageStoreTests.self).url(
            forResource: "01043", withExtension: "jpeg")!
        
        try! fm.copyItem(at: sourceURL, to: localDir.appendingPathComponent("01043.jpeg"))
        
        let imageStore = try! CardImageStore(serverDir: serverDir, localDir: localDir, cacheSize: 10)
        try! imageStore.downloadMissingImages(for: cards, progress: nil) { (report, error) in
            XCTAssert(error == nil)
            XCTAssertEqual(report.filesDownloaded.count, 5)
            XCTAssertEqual(report.filesNotDownloaded.count, 0)
            
            let files = try! self.fm.contentsOfDirectory(atPath: localDir.path)
            XCTAssertEqual(files.count, 6)
            
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 200.0)
    }
}
