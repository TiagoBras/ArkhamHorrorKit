//
//  CardTestSkillIcon.swift
//  ArkhamHorrorKit iOS
//
//  Created by Tiago Bras on 26/10/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import TBSwiftKit

public enum CardSkillTestIcon: Int {
    case willpower = 1, intellect, combat, agility, wild
    
    public static var allValues: [CardSkillTestIcon] = [.willpower, .intellect, .combat, .agility, .wild]
    
    public var id: Int {
        return rawValue
    }
    
    public var name: String {
        return String(describing: self).capitalized
    }
    
    public var color: Color {
        switch self {
        case .willpower: return Color(hexString: "2196F3")!
        case .intellect: return Color(hexString: "9C27B0")!
        case .combat: return Color(hexString: "F44336")!
        case .agility: return Color(hexString: "8BC34A")!
        case .wild: return Color(hexString: "FFEB3B")!
        }
    }
}
