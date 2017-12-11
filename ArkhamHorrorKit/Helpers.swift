//
//  Helpers.swift
//  ArkhamHorrorKit
//
//  Created by Tiago Bras on 11/12/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation

extension Array where Element == AnyHashable {
    var hashValue: Int {
        var finalHash = 5381
        
        for element in self {
            finalHash = ((finalHash << 5) &+ finalHash) &+ element.hashValue
        }
        
        return finalHash
    }
}
