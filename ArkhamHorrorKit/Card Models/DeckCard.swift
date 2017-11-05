//
//  DeckCard.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 01/06/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

public struct DeckCard: Hashable {
    public let card: Card
    public let quantity: Int

    public var hashValue: Int {
        return card.id
    }
    
    public init(card: Card, quantity: Int) {
        self.card = card
        self.quantity = quantity
    }

    public static func ==(lhs: DeckCard, rhs: DeckCard) -> Bool {
        return lhs.card.id == rhs.card.id
    }
    
    enum DeckCardError: Error {
        case cardNotFound(Int)
    }
}
