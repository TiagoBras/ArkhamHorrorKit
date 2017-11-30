//
//  CreateDatabaseInDocumentsTests.swift
//  ArkhamHorrorKit
//
//  Created by Tiago Bras on 30/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import XCTest
@testable import ArkhamHorrorKit

class CreateDatabaseInDocumentsTests: XCTestCase {
    func testExample() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("ah.db")
        
        if FileManager.default.fileExists(atPath: url.path) {
            try! FileManager.default.removeItem(at: url)
        }
        
        _ = try! AHDatabase(path: url.path)
    }
}
