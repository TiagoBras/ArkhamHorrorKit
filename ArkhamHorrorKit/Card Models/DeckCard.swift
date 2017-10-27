//
//  DeckCard.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 01/06/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

struct DeckCard: Hashable {
    let card: Card
    let quantity: Int

    var hashValue: Int {
        return card.id
    }
    
    init(card: Card, quantity: Int) {
        self.card = card
        self.quantity = quantity
    }

    static func ==(lhs: DeckCard, rhs: DeckCard) -> Bool {
        return lhs.card.id == rhs.card.id
    }
    
    enum DeckCardError: Error {
        case cardNotFound(Int)
    }
}
