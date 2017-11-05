//
//  CardType.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 19/04/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

public enum CardType: Int {
    case asset = 1, event, skill, treachery, enemy
    
    public var id: Int {
        return rawValue
    }
    
    public var name: String {
        return String(describing: self).capitalized
    }
    
    public static var allValues: [CardType] {
        return [.asset, .event, .skill, .treachery, .enemy]
    }
    
    public init?(code: String) {
        let codes: [String: CardType] = [
            "asset": .asset,
            "event": .event,
            "skill": .skill,
            "treachery": .treachery,
            "enemy": .enemy
        ]
        
        guard let value = codes[code]?.rawValue else { return nil }
        
        self.init(rawValue: value)
    }
}
