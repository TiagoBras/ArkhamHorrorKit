//
//  DeckCard.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 01/06/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

public struct DeckCard: Hashable, Comparable {
    public static func <(lhs: DeckCard, rhs: DeckCard) -> Bool {
        if lhs.card == rhs.card {
            return lhs.quantity < rhs.quantity
        } else {
            return lhs.card.id < rhs.card.id
        }
    }
    
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
    
    public func isLessThan(deckCard: DeckCard, using sorter: CardsSortingDescriptor) -> Bool {
        return sorter.isLessThan(self, deckCard)
    }
    
    public func isLessThan(deckCard: DeckCard, using sorters: [CardsSortingDescriptor]) -> Bool {
        for sorter in sorters {
            if sorter.isLessThan(self, deckCard) {
                return true
            } else if sorter.isEqual(self, deckCard) {
                continue
            } else {
                return false
            }
        }
        
        return false
    }
    
    public enum DeckCardError: Error {
        case cardNotFound(Int)
    }
}
