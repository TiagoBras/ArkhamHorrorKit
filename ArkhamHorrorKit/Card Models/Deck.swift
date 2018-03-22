//  Copyright © 2017 Tiago Bras. All rights reserved.

public protocol DeckOption {
    func isDeckValid(_ deck: Deck) -> Deck.DeckValidationResult
}

public struct Deck: Hashable {
    public var id: Int
    public var investigator: Investigator
    public var name: String
    public var cards: Set<DeckCard> {
        return Set(Array(_cards.values))
    }
    public var creationDate: Date
    public var updateDate: Date
    public let version: Int
    public var prevDeckVersionId: Int?
    public var nextDeckVersionId: Int?
    
    private var _cards: [Int: DeckCard]
    
    public init(id: Int,
                investigator: Investigator,
                name: String,
                cards: Set<DeckCard>,
                creationDate: Date,
                updateDate: Date,
                version: Int,
                prevDeckVersionId: Int?,
                nextDeckVersionId: Int?) {
        self.id = id
        self.investigator = investigator
        self.name = name
        
        self.creationDate = creationDate
        self.updateDate = updateDate
        self.version = version
        self.prevDeckVersionId = prevDeckVersionId
        self.nextDeckVersionId = nextDeckVersionId
        
        _cards = [:]
        
        cards.forEach { (deckCard) in
            _cards[deckCard.card.id] = deckCard
        }
    }
    
    public var stats: DeckStats {
        return DeckStats.fromDeck(self)
    }
    
    public func numberOfCards(ignorePermanentCards: Bool) -> Int {
        if ignorePermanentCards {
            return cards.reduce(0, { $0 + ($1.card.isPermanent ? 0 : $1.quantity) })
        } else {
            return cards.reduce(0, { $0 + $1.quantity })
        }
    }
    
    public func deckCard(withId id: Int) -> DeckCard? {
        return _cards[id]
    }
    
    public func quantity(of card: Card) -> Int? {
        return _cards[card.id]?.quantity
    }
    
    public func validateDeck() -> DeckValidationResult {
        for option in investigator.deckOptions {
            let result = option.isDeckValid(self)
            
            if !result.isValid {
                return result
            }
        }
        
        switch numberOfCards(ignorePermanentCards: true) {
        case Int.min..<investigator.deckSize:
            return DeckValidationResult(isValid: false, message: "Deck hasn't enough cards")
        case let count where count > investigator.deckSize:
            return DeckValidationResult(isValid: false, message: "Deck has too many cards")
        default:
            return DeckValidationResult(isValid: true, message: "Deck is valid")
        }
    }
    
    public func sortedCards(sortingDescriptors: [CardsSortingDescriptor]) -> [DeckCard] {
        return cards.sorted(by: { (a, b) -> Bool in
            return a.isLessThan(deckCard: b, using: sortingDescriptors)
        })
    }
    
    public mutating func changeQuantity(of card: Card, quantity: Int) {
        // Remove card if it exists and if quantity is 0
        if deckCard(withId: card.id) != nil && quantity == 0 {
            _cards.removeValue(forKey: card.id)
        }
        
        guard quantity > 0 else { return }

        _cards[card.id] = DeckCard(card: card, quantity: quantity)
    }
    
    public static func ==(lhs: Deck, rhs: Deck) -> Bool {
        guard lhs.id == rhs.id else { return false }
        guard lhs.investigator == rhs.investigator else { return false }
        guard lhs.name == rhs.name else { return false }
        guard lhs.creationDate == rhs.creationDate else { return false }
        guard lhs.updateDate == rhs.updateDate else { return false }
        
        return lhs._cards == rhs._cards
    }

    public var hashValue: Int {
        let hashables: [AnyHashable] = [id, investigator, name,
                             creationDate, updateDate, cards]
        
        return hashables.hashValue
    }
    
    public struct DeckValidationResult {
        public var isValid: Bool
        public var message: String?
    }
    
    public struct DeckDelta {
        var cardsAdded: Set<DeckCard>
        var cardsRemoved: Set<DeckCard>
        var xp: Int
    }
    
    public func calculateDeckDelta(_ otherDeck: Deck) -> DeckDelta {
        var added = Set<DeckCard>()
        var removed = Set<DeckCard>()
        
        let otherDeckCards = otherDeck.cards
        
        for otherDeckCard in otherDeckCards {
            var match: DeckCard?
            for deckCard in cards {
                if otherDeckCard.card.id == deckCard.card.id {
                    match = deckCard
                    break
                }
            }
            
            if let match = match {
                let quantityDelta = otherDeckCard.quantity - match.quantity
                
                if quantityDelta > 0 {
                    added.insert(DeckCard(card: match.card, quantity: quantityDelta))
                } else if quantityDelta < 0 {
                    removed.insert(DeckCard(card: match.card, quantity: -quantityDelta))
                }
            } else {
                added.insert(otherDeckCard)
            }
        }
        
        for deckCard in cards {
            if !otherDeckCards.contains(where: { $0.card.id == deckCard.card.id }) {
                removed.insert(deckCard)
            }
        }
        
        let currXP = cards.reduce(0, { $0 + ($1.card.level * $1.quantity) })
        let otherXP = otherDeckCards.reduce(0, { $0 + ($1.card.level * $1.quantity) })
        
        return DeckDelta(cardsAdded: added, cardsRemoved: removed, xp: otherXP - currXP)
    }
}
