//
//  CardPack.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 19/04/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

public struct CardPack: Hashable {
    public var id: String
    public var name: String
    public var position: Int
    public var size: Int
    public var cycle: CardCycle
    
    public var hashValue: Int {
        return (cycle.position * 1000) + position
    }
    
    public static func ==(lhs: CardPack, rhs: CardPack) -> Bool {
        return lhs.id == rhs.id
    }
}
