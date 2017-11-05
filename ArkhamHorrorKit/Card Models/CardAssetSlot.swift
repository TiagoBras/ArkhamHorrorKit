//
//  CardAssetSlot.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 27/04/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

public enum CardAssetSlot: Int {
    case hand = 1, hand2, ally, body, accessory, arcane, arcane2

    public static var allValues: [CardAssetSlot] = [.ally, .body, .accessory, .hand, .hand2, .arcane, .arcane2]
    
    public var id: Int {
        return rawValue
    }
    
    public var name: String {
        switch self {
        case .hand2: return "2Hands"
        case .arcane2: return "2Arcane"
        default: return String(describing: self).capitalized
        }
    }
    
    public init?(code: String) {
        let codes: [String: CardAssetSlot] = [
            "Hand": .hand,
            "Hand x2": .hand2,
            "Ally": .ally,
            "Body": .body,
            "Accessory": .accessory,
            "Arcane": .arcane,
            "Arcane x2": .arcane2,
        ]
        
        guard let value = codes[code]?.rawValue else { return nil }
        
        self.init(rawValue: value)
    }
}
