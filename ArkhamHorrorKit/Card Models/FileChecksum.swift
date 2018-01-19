//
//  FileChecksum.swift
//  ArkhamHorrorKit iOS
//
//  Created by Tiago Bras on 17/01/2018.
//  Copyright © 2018 Tiago Bras. All rights reserved.
//

import Foundation

public struct FileChecksum {
    public let filename: String
    public let hex: String
    
    public init(filename: String, hex: String) {
        self.filename = filename
        self.hex = hex
    }
    
    init(record: FileChecksumRecord) {
        self.filename = record.filename
        self.hex = record.hex
    }
}
