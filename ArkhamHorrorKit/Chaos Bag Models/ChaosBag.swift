//
//  ChaosBag.swift
//  ArkhamHorrorKit
//
//  Created by Tiago Bras on 10/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation

public struct ChaosBag: Equatable {
    public let id: Int
    public var p1: Int
    public var zero: Int
    public var m1: Int
    public var m2: Int
    public var m3: Int
    public var m4: Int
    public var m5: Int
    public var m6: Int
    public var m7: Int
    public var m8: Int
    public var skull: Int
    public var autofail: Int
    public var tablet: Int
    public var cultist: Int
    public var eldersign: Int
    public var elderthing: Int
    
    subscript(token: ChaosToken) -> Int {
        get {
            switch token {
            case .p1: return p1
            case .zero: return zero
            case .m1: return m1
            case .m2: return m2
            case .m3: return m3
            case .m4: return m4
            case .m5: return m5
            case .m6: return m6
            case .m7: return m7
            case .m8: return m8
            case .skull: return skull
            case .autofail: return autofail
            case .tablet: return tablet
            case .cultist: return cultist
            case .eldersign: return eldersign
            case .elderthing: return elderthing
            }
        }
        set {
            switch token {
            case .p1: p1 = newValue
            case .zero: zero = newValue
            case .m1: m1 = newValue
            case .m2: m2 = newValue
            case .m3: m3 = newValue
            case .m4: m4 = newValue
            case .m5: m5 = newValue
            case .m6: m6 = newValue
            case .m7: m7 = newValue
            case .m8: m8 = newValue
            case .skull: skull = newValue
            case .autofail: autofail = newValue
            case .tablet: tablet = newValue
            case .cultist: cultist = newValue
            case .eldersign: eldersign = newValue
            case .elderthing: elderthing = newValue
            }
        }
    }
    
    public var tokensDictionary: [ChaosToken: Int] {
        get {
            var dict = [ChaosToken: Int]()
            
            ChaosToken.allValues.forEach { (token) in
                dict[token] = self[token]
            }
            
            return dict
        }
        set {
            for (token, quantity) in newValue {
                self[token] = quantity
            }
        }
    }
    
    public var tokens: [ChaosToken] {
        var array = [ChaosToken]()
        
        for (token, quantity) in tokensDictionary {
            guard quantity > 0 else { continue }
            
            for _ in 0..<quantity {
                array.append(token)
            }
        }
        
        return array
    }
    
    public static func ==(lhs: ChaosBag, rhs: ChaosBag) -> Bool {
        if lhs.id != rhs.id { return false }
        if lhs.p1 != rhs.p1 { return false }
        if lhs.zero != rhs.zero { return false }
        if lhs.m1 != rhs.m1 { return false }
        if lhs.m2 != rhs.m2 { return false }
        if lhs.m3 != rhs.m3 { return false }
        if lhs.m4 != rhs.m4 { return false }
        if lhs.m5 != rhs.m5 { return false }
        if lhs.m6 != rhs.m6 { return false }
        if lhs.m7 != rhs.m7 { return false }
        if lhs.m8 != rhs.m8 { return false }
        if lhs.skull != rhs.skull { return false }
        if lhs.autofail != rhs.autofail { return false }
        if lhs.tablet != rhs.tablet { return false }
        if lhs.cultist != rhs.cultist { return false }
        if lhs.eldersign != rhs.eldersign { return false }
        if lhs.elderthing != rhs.elderthing { return false }
        
        return true
    }
    
    public func update(_ database: ChaosBagDatabase) throws {
        try database.dbQueue.write({ (db) in
            guard let record = try ChaosBagRecord.fetchOne(
                db, key: ["id": id]) else {
                    throw ChaosBagDatabaseError.chaosBagNotFound(id)
            }
            
            record.updateTokens(dictionary: tokensDictionary)
            
            if record.hasPersistentChangedValues {
                try record.update(db)
            }
        })
    }
    
    public func delete(_ database: ChaosBagDatabase) throws {
        try database.dbQueue.write({ (db) in
            guard let record = try ChaosBagRecord.fetchOne(
                db, key: ["id": id]) else {
                    throw ChaosBagDatabaseError.chaosBagNotFound(id)
            }
            
            try record.delete(db)
        })
    }
    
    public static func create(_ database: ChaosBagDatabase,
                              tokens: [ChaosToken: Int],
                              protected: Bool) throws -> ChaosBag {
        let record = ChaosBagRecord(tokens: tokens, protected: protected)
        
        return try database.dbQueue.write { (db) -> ChaosBag in
            try record.insert(db)
            
            return ChaosBag.makeChaosBag(record: record)
        }
    }
    
    static func makeChaosBag(record: ChaosBagRecord) -> ChaosBag {
        return ChaosBag(id: record.id!,
                        p1: record.p1,
                        zero: record.zero,
                        m1: record.m1,
                        m2: record.m2,
                        m3: record.m3,
                        m4: record.m4,
                        m5: record.m5,
                        m6: record.m6,
                        m7: record.m7,
                        m8: record.m8,
                        skull: record.skull,
                        autofail: record.autofail,
                        tablet: record.tablet,
                        cultist: record.cultist,
                        eldersign: record.eldersign,
                        elderthing: record.elderthing)
    }
}
