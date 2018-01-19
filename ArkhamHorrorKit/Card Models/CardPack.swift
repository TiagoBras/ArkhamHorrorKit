//  Copyright © 2017 Tiago Bras. All rights reserved.

public struct CardPack: Hashable, Comparable {
    public var id: String
    public var name: String
    public var position: Int
    public var size: Int
    public var cycle: CardCycle
    public var cardsCount: Int
    
    public var hashValue: Int {
        let hashables: [AnyHashable] = [id, name, position, size, cycle]
        
        return hashables.hashValue
    }
    
    public static func ==(lhs: CardPack, rhs: CardPack) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    public static func <(lhs: CardPack, rhs: CardPack) -> Bool {
        if lhs.cycle < rhs.cycle {
            return true
        } else if lhs.cycle == rhs.cycle {
            return lhs.position < rhs.position
        } else {
            return false
        }
    }
}
