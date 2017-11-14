//
//  ChaosBag.swift
//  ArkhamHorrorKit
//
//  Created by Tiago Bras on 10/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation
import GRDB
import TBSwiftKit

class ChaosBagRecord: Record {
    var id: Int?
    var p1: Int = 0
    var zero: Int = 0
    var m1: Int = 0
    var m2: Int = 0
    var m3: Int = 0
    var m4: Int = 0
    var m5: Int = 0
    var m6: Int = 0
    var m7: Int = 0
    var m8: Int = 0
    var skull: Int = 0
    var autofail: Int = 0
    var tablet: Int = 0
    var cultist: Int = 0
    var eldersign: Int = 0
    var elderthing: Int = 0
    
    var protected: Bool
    
    override class var databaseTableName: String {
        return "ChaosBag"
    }
    
    typealias ChaosTokenQuantity = Int
    
    func updateTokens(dictionary: [ChaosToken: ChaosTokenQuantity]) {
        p1 = dictionary[ChaosToken.p1] ?? 0
        zero = dictionary[ChaosToken.zero] ?? 0
        m1 = dictionary[ChaosToken.m1] ?? 0
        m2 = dictionary[ChaosToken.m2] ?? 0
        m3 = dictionary[ChaosToken.m3] ?? 0
        m4 = dictionary[ChaosToken.m4] ?? 0
        m5 = dictionary[ChaosToken.m5] ?? 0
        m6 = dictionary[ChaosToken.m6] ?? 0
        m7 = dictionary[ChaosToken.m7] ?? 0
        m8 = dictionary[ChaosToken.m8] ?? 0
        skull = dictionary[ChaosToken.skull] ?? 0
        autofail = dictionary[ChaosToken.autofail] ?? 0
        tablet = dictionary[ChaosToken.tablet] ?? 0
        cultist = dictionary[ChaosToken.cultist] ?? 0
        eldersign = dictionary[ChaosToken.eldersign] ?? 0
        elderthing = dictionary[ChaosToken.elderthing] ?? 0    }
    
    init(tokens: [ChaosToken: ChaosTokenQuantity], protected: Bool) {
        self.protected = protected
        
        super.init()
        
        updateTokens(dictionary: tokens)
    }
    
    required init(row: Row) {
        id = row["id"]
        p1 = row["p1"]
        zero = row["zero"]
        m1 = row["m1"]
        m2 = row["m2"]
        m3 = row["m3"]
        m4 = row["m4"]
        m5 = row["m5"]
        m6 = row["m6"]
        m7 = row["m7"]
        m8 = row["m8"]
        skull = row["skull"]
        autofail = row["autofail"]
        tablet = row["tablet"]
        cultist = row["cultist"]
        eldersign = row["eldersign"]
        elderthing = row["elderthing"]
        protected = row["protected"]
        
        super.init(row: row)
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = Int(rowID)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["p1"] = p1
        container["zero"] = zero
        container["m1"] = m1
        container["m2"] = m2
        container["m3"] = m3
        container["m4"] = m4
        container["m5"] = m5
        container["m6"] = m6
        container["m7"] = m7
        container["m8"] = m8
        container["skull"] = skull
        container["autofail"] = autofail
        container["tablet"] = tablet
        container["cultist"] = cultist
        container["eldersign"] = eldersign
        container["elderthing"] = elderthing
        
        container["protected"] = protected
    }
}
