//
//  DeckCard.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 01/06/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

public struct DeckCard: Hashable, Comparable {
    public static func <(lhs: DeckCard, rhs: DeckCard) -> Bool {
        if lhs.card.id == rhs.card.id {
            return lhs.quantity < rhs.quantity
        } else {
            return lhs.card.id < rhs.card.id
        }
    }
    
    public var card: Card
    public var quantity: Int

    public var hashValue: Int {
        var finalHash = 5381
        finalHash = ((finalHash << 5) &+ finalHash) &+ card.id.hashValue
        finalHash = ((finalHash << 5) &+ finalHash) &+ quantity.hashValue

        return finalHash
    }
    
    public init(card: Card, quantity: Int) {
        self.card = card
        self.quantity = quantity
    }

    public static func ==(lhs: DeckCard, rhs: DeckCard) -> Bool {
        guard lhs.card.id == rhs.card.id else { return false }
        
        return lhs.quantity == rhs.quantity
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
