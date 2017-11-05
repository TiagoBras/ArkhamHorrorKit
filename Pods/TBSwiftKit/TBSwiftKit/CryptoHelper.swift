//
//  CryptoHelper.swift
//  TBHelpers
//
//  Created by Tiago Bras on 24/10/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation
import CommonCrypto

public final class CryptoHelper {
    private init() { }
    
    public static func sha256(data: Data) -> Data {
        var digestData = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes { digestBytes in
            data.withUnsafeBytes { messageBytes in
                CC_SHA256(messageBytes, CC_LONG(data.count), digestBytes)
            }
        }
        
        return digestData
    }
    
    public static func sha256Hex(data: Data) -> String {
        let sha256Data = CryptoHelper.sha256(data: data)
        
        return sha256Data.map({ String(format: "%02hhx", $0) }).joined()
    }
    
    public static func sha256Hex(string: String) -> String? {
        guard let data = string.data(using: String.Encoding.utf8) else { return nil }
        
        return CryptoHelper.sha256Hex(data: data)
    }
    
    public static func sha256Hex(url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        
        return CryptoHelper.sha256Hex(data: data)
    }
}

