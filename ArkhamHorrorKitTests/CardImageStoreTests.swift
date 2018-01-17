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
        
        XCTAssertEqual(try! imageStore.missingImages(for: cards).count, 5)
        
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
    
    func testDownloadMissingImagesFromHeroku() {
        let localDir = userDir.appendingPathComponent("card_images_local_v2")
        
        if fm.fileExists(atPath: localDir.path) {
            try! fm.removeItem(at: localDir)
        }
        
        try! fm.createDirectory(at: localDir, withIntermediateDirectories: false, attributes: nil)
        
        let sourceURL = Bundle(for: CardImageStoreTests.self).url(
            forResource: "01043", withExtension: "jpeg")!
        
        
        let server = URL(string: "https://bitmountains.herokuapp.com")!
        
        let imageStore = try! CardImageStore(serverHost: server,
                                             localDir: localDir,
                                             authToken: "48pvZOZWny8LcmEJBP5YgVwpt7Kux58KKqUSW",
                                             cacheSize: 20)
        
        let promise = expectation(description: "Download Missing Images Heroku - 1")
        try! imageStore.missingImages(completion: { (urls, error) in
            XCTAssert(error == nil)
            XCTAssertEqual(urls!.count, 316)
            
            promise.fulfill()
        })
        
        try! fm.copyItem(at: sourceURL, to: localDir.appendingPathComponent("01043.jpeg"))
        
        let promise2 = expectation(description: "Download Missing Images Heroku - 2")
        let promise3 = expectation(description: "Download Missing Images Heroku - 3")
        try! imageStore.missingImages(completion: { (urls, error) in
            XCTAssert(error == nil)
            XCTAssertEqual(urls!.count, 315)
            
            promise2.fulfill()
            
            var first5Urls = Array(urls!.prefix(5))
            first5Urls.append(imageStore.serverDir!.appendingPathComponent("images/xxxxx.jpeg"))
            
            print(first5Urls)
            
            try! imageStore.downloadMissingImages(
                urls: first5Urls,
                progress: nil,
                completion: { (report, error) in
                    if let error = error {
                        print(error)
                        XCTFail()
                    }
                    
                    XCTAssertEqual(report.filesDownloaded.count, 5)
                    XCTAssertEqual(report.filesNotDownloaded.count, 1)
                    promise3.fulfill()
            })
        })
        
        wait(for: [promise, promise2, promise3], timeout: 200.0)
    }
}
