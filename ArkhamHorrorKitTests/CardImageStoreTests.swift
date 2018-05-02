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
    let server = URL(string: "https://bitmountains.herokuapp.com")!
    let userDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fm = FileManager.default
    let authToken = getEnvironmentVar("MAGIC_TOKEN")!
    
    func testDownloadingOneCardImage() {
        let promise = expectation(description: "Download Front Image")
        let localDir = userDir.appendingPathComponent("card_images")
        
        try! fm.createDirectory(at: localDir, withIntermediateDirectories: true, attributes: nil)
        
        let imageStore = try! CardImageStore(serverDomain: server,
                                             localDir: localDir,
                                             authToken: authToken,
                                             cacheSize: 20)
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
        
        wait(for: [promise2], timeout: 50.0)
        
        try! fm.removeItem(at: localDir)
    }
    
    func testDownloadMissingImagesFromHeroku() {
        let localDir = userDir.appendingPathComponent("card_images_local_v2")
        
        if fm.fileExists(atPath: localDir.path) {
            try! fm.removeItem(at: localDir)
        }
        
        try! fm.createDirectory(at: localDir, withIntermediateDirectories: false, attributes: nil)
        
        let sourceURL = Bundle(for: CardImageStoreTests.self).url(
            forResource: "01043", withExtension: "jpeg")!
        
        let imageStore = try! CardImageStore(serverDomain: server,
                                             localDir: localDir,
                                             authToken: authToken,
                                             cacheSize: 20)
        
        let promise = expectation(description: "Download Missing Images Heroku - 1")
        let promise2 = expectation(description: "Download Missing Images Heroku - 2")
        let promise3 = expectation(description: "Download Missing Images Heroku - 3")
        let promise4 = expectation(description: "Download Missing Images Heroku - 4")
        
        imageStore.missingImages(completion: { (urls, error) in
            if error != nil {
                XCTFail("Error should not be nil")
            }

            XCTAssertEqual(urls!.count, 353)
            
            promise.fulfill()
            
            try! self.fm.copyItem(at: sourceURL, to: localDir.appendingPathComponent("01043.jpeg"))
            
            imageStore.missingImages(completion: { (urls, error) in
                XCTAssert(error == nil)
                XCTAssertEqual(urls!.count, 352)
                
                promise2.fulfill()
                
                var first5Urls = Array(urls!.prefix(5))
                first5Urls.append(imageStore.serverDir!.appendingPathComponent("images/xxxxx.jpeg"))
                
                imageStore.downloadImages(
                    urls: first5Urls,
                    start: { (_) in promise3.fulfill() },
                    progress: nil,
                    completion: { (report, error) in
                        if let error = error {
                            XCTFail(error.localizedDescription)
                        }
                        XCTAssert(report != nil)
                        
                        XCTAssertEqual(report!.filesDownloaded.count, 5)
                        XCTAssertEqual(report!.filesNotDownloaded.count, 1)
                        promise4.fulfill()
                })
            })
        })
        
        wait(for: [promise, promise2, promise3, promise4], timeout: 50.0)
    }
}
