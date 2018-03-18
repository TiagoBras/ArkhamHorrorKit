//
//  DatabaseServerTests.swift
//  ArkhamHorrorKit
//
//  Created by Tiago Bras on 19/01/2018.
//  Copyright © 2018 Tiago Bras. All rights reserved.
//

import XCTest
import ArkhamHorrorKit

func getEnvironmentVar(_ name: String) -> String? {
    if let rawValue = getenv(name) {
        return String(utf8String: rawValue)
    }
    
    return nil
}

class DatabaseServerTests: XCTestCase {
    let fm = FileManager.default
    let domain = URL(string: "https://bitmountains.herokuapp.com")!
    let userDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    lazy var defaultJsonChecksums: [String: String] = {
        return try! (try! AHDatabase()).getAllJsonFilesChecksums()
    }()
    
    func testGetEnvironmentVar() {
        if let value = getEnvironmentVar("TEST_VARIABLE") {
            XCTAssertEqual(value, "HelloWorld")
        } else {
            XCTFail("TEST_VARIABLE environment variable does not exist")
        }
    }
    
    func testDatabaseServerWithWrongPath() {
        let url = URL(string: "https://www.example.com")!
        
        let server = DatabaseServer(domain: url, authenticationToken: "")
        
        let promise1 = expectation(description: "That error is not nil - 1")
        let promise2 = expectation(description: "That error is not nil - 1")
        let promise3 = expectation(description: "That error is not nil - 1")
        
        server.checkUpdates(jsonChecksum: "", imagesChecksum: "") { (_, error) in
            if error == nil {
                XCTFail("Error should be nil")
            }
            promise1.fulfill()
        }
        
        server.checkMissingImages(imagesDirectory: Bundle.main.bundleURL) { (_, error) in
            if error == nil {
                XCTFail("Error should be nil")
            }
            promise2.fulfill()
        }
        
        server.checkUpdatedJsonFiles(jsonFilesChecksums: defaultJsonChecksums) { (_, error) in
            if error == nil {
                XCTFail("Error should be nil")
            }
            promise3.fulfill()
        }
        
        wait(for: [promise1, promise2, promise3], timeout: 30)
    }
    
    func testDatabaseServerWithWrongAuthenticationToken() {
        let server = DatabaseServer(domain: domain, authenticationToken: "")
        
        let promise1 = expectation(description: "That error is not nil - 1")
        let promise2 = expectation(description: "That error is not nil - 2")
        let promise3 = expectation(description: "That error is not nil - 3")
        
        server.checkUpdates(jsonChecksum: "", imagesChecksum: "") { (_, error) in
            if let error = error {
                if case let DatabaseServer.DatabaseServerError.httpStatusCode(code) = error {
                    XCTAssertEqual(code, 401)
                } else {
                    XCTFail("Error should be httpStatusCode, not \(error.localizedDescription)")
                }
            } else {
                XCTFail("Error should not be nil")
            }

            promise1.fulfill()
        }
        
        server.checkMissingImages(imagesDirectory: Bundle.main.bundleURL) { (_, error) in
            if let error = error {
                if case let DatabaseServer.DatabaseServerError.httpStatusCode(code) = error {
                    XCTAssertEqual(code, 401)
                } else {
                    XCTFail("Error should be httpStatusCode, not \(error.localizedDescription)")
                }
            } else {
                XCTFail("Error should not be nil")
            }
            
            promise2.fulfill()
        }
        
        server.checkUpdatedJsonFiles(jsonFilesChecksums: defaultJsonChecksums) { (_, error) in
            if let error = error {
                if case let DatabaseServer.DatabaseServerError.httpStatusCode(code) = error {
                    XCTAssertEqual(code, 401)
                } else {
                    XCTFail("Error should be httpStatusCode, not \(error.localizedDescription)")
                }
            } else {
                XCTFail("Error should not be nil")
            }
            
            promise3.fulfill()
        }
        
        wait(for: [promise1, promise2, promise3], timeout: 30)
    }
    
    func testCheckUpdates() {
        let server = DatabaseServer(domain: domain,
                                    authenticationToken: getEnvironmentVar("MAGIC_TOKEN")!)
        
        let promise0 = expectation(description: "Check updates - 0")
        let promise1 = expectation(description: "Check updates - 1")
        let promise2 = expectation(description: "Check updates - 2")
        let promise3 = expectation(description: "Check updates - 3")
        
        server.checkUpdates(jsonChecksum: nil, imagesChecksum: nil) { (report, error) in
            if error != nil {
                XCTFail("Error should be nil")
            }
            
            XCTAssertEqual(report!.jsonFilesUpdateAvailable, false)
            XCTAssertEqual(report!.imagesUpdateAvailable, false)
            
            promise0.fulfill()
        }
        
        server.checkUpdates(jsonChecksum: "", imagesChecksum: nil) { (report, error) in
            if error != nil {
                XCTFail("Error should be nil")
            }
            
            XCTAssertEqual(report!.jsonFilesUpdateAvailable, true)
            XCTAssertEqual(report!.imagesUpdateAvailable, false)
            
            promise1.fulfill()
        }
        
        server.checkUpdates(jsonChecksum: nil, imagesChecksum: "") { (report, error) in
            if error != nil {
                XCTFail("Error should be nil")
            }
            
            XCTAssertEqual(report!.jsonFilesUpdateAvailable, false)
            XCTAssertEqual(report!.imagesUpdateAvailable, true)
            
            promise2.fulfill()
        }
        
        server.checkUpdates(jsonChecksum: "", imagesChecksum: "") { (report, error) in
            if error != nil {
                XCTFail("Error should be nil")
            }
            
            XCTAssertEqual(report!.jsonFilesUpdateAvailable, true)
            XCTAssertEqual(report!.imagesUpdateAvailable, true)
            
            promise3.fulfill()
        }
        
        wait(for: [promise0, promise1, promise2, promise3], timeout: 30)
    }
    
    func testCheckMissingImages() {
        let server = DatabaseServer(domain: domain,
                                    authenticationToken: getEnvironmentVar("MAGIC_TOKEN")!)
        
        let localDir = userDir.appendingPathComponent("card_images_local_v3")
        
        if fm.fileExists(atPath: localDir.path) {
            try! fm.removeItem(at: localDir)
        }
        
        try! fm.createDirectory(at: localDir, withIntermediateDirectories: false, attributes: nil)
        
        let promise1 = expectation(description: "Check Missing Images - 1")
        let promise2 = expectation(description: "Check Missing Images - 2")
        
        server.checkMissingImages(imagesDirectory: localDir) { (urls, error) in
            XCTAssertEqual(urls!.count, 339)

            promise1.fulfill()
            
            let sourceURL = Bundle(for: CardImageStoreTests.self).url(
                forResource: "01043", withExtension: "jpeg")!
            
            try! self.fm.copyItem(at: sourceURL, to: localDir.appendingPathComponent("01043.jpeg"))
            
            server.checkMissingImages(imagesDirectory: localDir, completion: { (urls, error) in
                XCTAssertEqual(urls!.count, 339)
                
                promise2.fulfill()
            })
        }
        
        wait(for: [promise1, promise2], timeout: 30)
    }
    
    func testUpdatedJsonFilesWithZeroChecksumsSent() {
        let server = DatabaseServer(domain: domain,
                                    authenticationToken: getEnvironmentVar("MAGIC_TOKEN")!)

        let promise = expectation(description: "Updated JSON Files")
        
        server.checkUpdatedJsonFiles(jsonFilesChecksums: [String: String]()) { (urls, error) in
            let files = ["apot.json", "bota.json", "bsr.json", "core.json", "cycles.json", "dca.json", "dwl.json", "eotp.json", "litas.json", "packs.json", "promo.json", "ptc.json",
                "tece.json", "tmm.json", "tpm.json", "tuo.json", "uau.json", "wda.json"].sorted()
            
            let expectedUrls = files.map({ self.domain.appendingPathComponent("json/\($0)") })
            
            self.assertURLs(urls!, rhs: expectedUrls)
            
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 20)
    }
    
    func testUpdateJsonFilesWithOneChecksumSent() {
        let server = DatabaseServer(domain: domain,
                                    authenticationToken: getEnvironmentVar("MAGIC_TOKEN")!)
        
        let promise = expectation(description: "Updated JSON Files")
        let checksums = ["uau.json": "34bd8243f3459d3021d6c2d8dc48b4617f9405460a0d7980badf3d26c3a79606"]
        
        server.checkUpdatedJsonFiles(jsonFilesChecksums: checksums) { (urls, error) in
            if urls!.map({ $0.lastPathComponent }).index(of: "uau.json") != nil {
                XCTFail("Index should be nil")
            }
            
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 20)
    }
    
    // MARK :- Helper functions
    func assertURLs(_ lhs: [URL], rhs: [URL]) {
        let leftSorted = lhs.sorted(by: { $0.path < $1.path })
        let rightSorted = rhs.sorted(by: { $0.path < $1.path })
        
        XCTAssertEqual(leftSorted, rightSorted)
    }
}
