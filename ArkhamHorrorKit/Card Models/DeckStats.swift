//
//  DeckStats.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 23/10/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

public class DeckStats {
    var deckSize: Int = 0
    var numberOfCardsByType = [CardType: Int]()
    var numberOfCardsByFaction = [CardFaction: Int]()
    var numberOfCardsByCost = [Int: Int]()
    var totalCardsCount = 0
    var totalXp = 0
    var totalCost = 0
    
    public subscript(key: CardType) -> Int {
        get {
            if let number = numberOfCardsByType[key] {
                return number
            } else {
                return 0
            }
        }
        set {
            numberOfCardsByType[key] = newValue
        }
    }
    
    public subscript(key: CardFaction) -> Int {
        get {
            if let number = numberOfCardsByFaction[key] {
                return number
            } else {
                return 0
            }
        }
        set {
            numberOfCardsByFaction[key] = newValue
        }
    }
    
    private func inc(cost: Int, by amount: Int) {
        numberOfCardsByCost[cost] = (numberOfCardsByCost[cost] ?? 0) + amount
    }
    
    private init() {}
    
    static func fromDeck(_ deck: Deck) -> DeckStats {
        let stats = DeckStats()
        stats.deckSize = 30
        
        for deckCard in deck.cards {
            let quantity = Int(deckCard.quantity)
            
            stats.totalCardsCount += quantity
            stats.totalXp += Int(deckCard.card.level) * quantity
            stats.totalCost += Int(deckCard.card.cost) * quantity
            stats[deckCard.card.type] += quantity
            stats[deckCard.card.faction] += quantity
            stats.inc(cost: deckCard.card.cost, by: quantity)
        }
        
        return stats
    }
}
