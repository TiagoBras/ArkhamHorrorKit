//  Copyright © 2017 Tiago Bras. All rights reserved.

import TBSwiftKit

public enum CardFaction: Int, Comparable {
    class Dummy {}
    
    case guardian = 1, seeker, rogue, mystic, survivor, neutral
    
    public static var allValues: [CardFaction] = [.guardian, .seeker, .rogue, .mystic, .survivor, .neutral]
    
    public static func <(lhs: CardFaction, rhs: CardFaction) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    public init?(code: String) {
        let codes: [String: CardFaction] = [
            "guardian": .guardian,
            "seeker": .seeker,
            "rogue": .rogue,
            "mystic": .mystic,
            "survivor": .survivor,
            "neutral": .neutral
        ]
        
        guard let value = codes[code]?.rawValue else { return nil }
        
        self.init(rawValue: value)
    }
    
    public var id: Int {
        return rawValue
    }
    
    public var name: String {
        switch self {
        case .guardian: return "Guardian"
        case .seeker: return "Seeker"
        case .rogue: return "Rogue"
        case .mystic: return "Mystic"
        case .survivor: return "Survivor"
        case .neutral: return "Neutral"
        }
    }
    
    public var color: Color {
        switch self {
        case .guardian: return Color(hexString: "598BBA")!
        case .seeker: return Color(hexString: "CC9933")!
        case .rogue: return Color(hexString: "4A854D")!
        case .mystic: return Color(hexString: "655B8F")!
        case .survivor: return Color(hexString: "ED2B30")!
        case .neutral: return Color(hexString: "AAAAAA")!
        }
    }
    
    public var lightColor: Color {
        switch self {
        case .guardian: return Color(hexString: "E1F5FE")!
        case .seeker: return Color(hexString: "FFF59D")!
        case .rogue: return Color(hexString: "DCEDC8")!
        case .mystic: return Color(hexString: "E1BEE7")!
        case .survivor: return Color(hexString: "FFCDD2")!
        case .neutral: return Color(hexString: "ECEFF1")!
        }
    }
    
    public var saturatedColor: Color {
        switch self {
        case .guardian: return Color(hexString: "448AFF")!
        case .seeker: return Color(hexString: "FFEB3B")!
        case .rogue: return Color(hexString: "4CAF50")!
        case .mystic: return Color(hexString: "651FFF")!
        case .survivor: return Color(hexString: "D32F2F")!
        case .neutral: return Color(hexString: "90A4AE")!
        }
    }
    
    public var titledButtonImage: (on: Image, off: Image) {
        let bundle = Bundle(for: CardFaction.Dummy.self)
        
        switch self {
        case .guardian: return (on: Image.inBundle("btn_factions_guardian_ON", bundle),
                                off: Image.inBundle("btn_factions_guardian_OFF", bundle))
        case .seeker: return (on: Image.inBundle("btn_factions_seeker_ON", bundle),
                              off: Image.inBundle("btn_factions_seeker_OFF", bundle))
        case .rogue: return (on: Image.inBundle("btn_factions_rogue_ON", bundle),
                             off: Image.inBundle("btn_factions_rogue_OFF", bundle))
        case .mystic: return (on: Image.inBundle("btn_factions_mystic_ON", bundle),
                              off: Image.inBundle("btn_factions_mystic_OFF", bundle))
        case .survivor: return (on: Image.inBundle("btn_factions_survivor_ON", bundle),
                                off: Image.inBundle("btn_factions_survivor_OFF", bundle))
        case .neutral: return (on: Image.inBundle("btn_factions_neutral_ON", bundle),
                               off: Image.inBundle("btn_factions_neutral_OFF", bundle))
        }
    }
}
