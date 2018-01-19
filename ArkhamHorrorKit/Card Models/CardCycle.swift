//  Copyright © 2017 Tiago Bras. All rights reserved.

public struct CardCycle: Hashable, Comparable {
    public var id: String
    public var name: String
    public var position: Int
    public var size: Int
    public var cardsCount: Int
    
    public var hashValue: Int {
        let hashables: [AnyHashable] = [id, name, position, size]
        
        return hashables.hashValue
    }
    
    public static func ==(lhs: CardCycle, rhs: CardCycle) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    public static func <(lhs: CardCycle, rhs: CardCycle) -> Bool {
        return lhs.position < rhs.position
    }
}
