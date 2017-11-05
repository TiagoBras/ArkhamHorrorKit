//
//  CardCycle.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 19/04/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

public struct CardCycle: Hashable {
    public var id: String
    public var name: String
    public var position: Int
    public var size: Int
    
    public var hashValue: Int {
        return position
    }
    
    public static func ==(lhs: CardCycle, rhs: CardCycle) -> Bool {
        return lhs.id == rhs.id
    }
}
