//
//  Deck.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 01/06/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

protocol DeckOption {
    func isDeckValid(_ deck: Deck) -> DeckValidationResult
}

extension Set where Element == DeckCard {
    func index(of element: Card) -> Set<DeckCard>.Index? {
        return index(where: { $0.card.id == element.id })
    }
}

struct Deck: Equatable {
    var id: Int
    var investigator: Investigator
    var name: String
    var cards: Set<DeckCard> {
        return Set(Array(_cards.values))
    }
    var creationDate: Date
    var updateDate: Date
    
    private var _cards: [Int: DeckCard]
    
    init(id: Int, investigator: Investigator, name: String, cards: Set<DeckCard>, creationDate: Date, updateDate: Date) {
        self.id = id
        self.investigator = investigator
        self.name = name
        
        self.creationDate = creationDate
        self.updateDate = updateDate
        
        _cards = [:]
        
        cards.forEach { (deckCard) in
            _cards[deckCard.card.id] = deckCard
        }
    }
    
    var stats: DeckStats {
        return DeckStats.fromDeck(self)
    }
    
    var numberOfCards: Int {
        return cards.reduce(0, { $0 + $1.quantity })
    }
    
    func deckCard(withId id: Int) -> DeckCard? {
        return _cards[id]
    }
    
    func quantity(of card: Card) -> Int? {
        return _cards[card.id]?.quantity
    }
    
    func validateDeck() -> DeckValidationResult {
        for option in investigator.deckOptions {
            let result = option.isDeckValid(self)
            
            if !result.isValid {
                return result
            }
        }
        
        switch numberOfCards {
        case Int.min..<investigator.deckSize:
            return DeckValidationResult(isValid: false, message: "Deck hasn't enough cards")
        case let count where count > investigator.deckSize:
            return DeckValidationResult(isValid: false, message: "Deck has too many cards")
        default:
            return DeckValidationResult(isValid: true, message: "Deck is valid")
        }
    }
    
    mutating func changeQuantity(of card: Card, quantity: Int) {
        _cards[card.id] = DeckCard(card: card, quantity: quantity)
    }
    
    static func ==(lhs: Deck, rhs: Deck) -> Bool {
        return lhs.id == rhs.id
    }
    
    struct DeckValidationResult {
        var isValid: Bool
        var message: String?
    }
}
