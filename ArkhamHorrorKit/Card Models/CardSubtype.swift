//
//  CardSubtype.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 19/04/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

public enum CardSubtype: Int {
    case weakness = 1, basicweakness = 2
    
    public var id: Int {
        return rawValue
    }
    
    public var name: String {
        switch self {
        case .weakness: return "Weakness"
        case .basicweakness: return "Basic Weakness"
        }
    }
    
    public init?(code: String) {
        let codes: [String: CardSubtype] = [
            "weakness": .weakness,
            "basicweakness": .basicweakness,
        ]
        
        guard let value = codes[code]?.rawValue else { return nil }
        
        self.init(rawValue: value)
    }
}
