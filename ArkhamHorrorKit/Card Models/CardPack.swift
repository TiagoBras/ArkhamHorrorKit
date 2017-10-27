//
//  CardPack.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 19/04/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

public struct CardPack: Hashable {
    var id: String
    var name: String
    var position: Int
    var size: Int
    var cycle: CardCycle
    
    public var hashValue: Int {
        return (cycle.position * 1000) + position
    }
    
    public static func ==(lhs: CardPack, rhs: CardPack) -> Bool {
        return lhs.id == rhs.id
    }
}
