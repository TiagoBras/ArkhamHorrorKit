//
//  Investigator.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 31/05/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import TBSwiftKit

public struct Investigator: Equatable {
    public var id: Int
    public var name: String
    public var subname: String
    public var faction: CardFaction
    public var health: Int
    public var sanity: Int
    public var frontText: String
    public var backText: String
    public var pack: CardPack
    public var agility: Int
    public var combat: Int
    public var intellect: Int
    public var willpower: Int
    public var position: Int
    public var traits: String
    public var frontFlavor: String
    public var backFlavor: String
    public var illustrator: String
    
    public static func ==(lhs: Investigator, rhs: Investigator) -> Bool {
        return lhs.id == rhs.id
    }

    public var deckSize: Int {
        return 30
    }
    
    // FIXME: find another way of doing this
    // TODO: add 2nd expansion investigators
    public var availableFactions: [CardFaction] {
        var factions: [CardFaction] = []
        
        switch id {
        case 1001:
            factions.append(contentsOf: [.guardian, .seeker])
        case 1002:
            factions.append(contentsOf: [.seeker, .mystic])
        case 1003:
            factions.append(contentsOf: [.rogue, .guardian])
        case 1004:
            factions.append(contentsOf: [.mystic, .survivor])
        case 1005:
            factions.append(contentsOf: [.survivor, .rogue])
        case 2001...2005:
            factions.append(contentsOf:
                [.guardian, .seeker, .mystic, .rogue, .survivor])
        default:
            factions.append(contentsOf:
                [.guardian, .seeker, .mystic, .rogue, .survivor])
        }
        
        factions.append(.neutral)
        
        return factions
    }
    
    public var avatar: Image {
        switch id {
        case 1001: return Image.inMainBundle("roland_banks_the_fed")
        case 1002: return Image.inMainBundle("daisy_walker_the_librarian")
        case 1003: return Image.inMainBundle("skids_o_toole_the_ex_con")
        case 1004: return Image.inMainBundle("agnes_baker_the_waitress")
        case 1005: return Image.inMainBundle("wendy_adams_the_urchin")
        case 2001: return Image.inMainBundle("zoey_samaras_the_chef")
        case 2002: return Image.inMainBundle("rex_murphy_the_reporter")
        case 2003: return Image.inMainBundle("jenny_barnes_the_dilettante")
        case 2004: return Image.inMainBundle("jim_culver_the_musician")
        case 2005: return Image.inMainBundle("ashcan_pete_the_drifter")
        default: return Image.inMainBundle("unknown")
        }
    }
    
    public var deckOptions: [DeckOption] {
        var options: [DeckOption] = []
        var factions: [CardFaction] = []
        
        func genCoreDeckOptions(mainFaction: CardFaction,
                                secondaryFaction: CardFaction) -> [DeckOption] {
            return [
                DeckOptionAllowedFactions([mainFaction, .neutral]),
                DeckOptionAllowedFactions([secondaryFaction], levels: Array(0...2), maxQuantity: Int.max)
            ]
        }
        
        func genDunwichDeckOptions(mainFaction: CardFaction) -> [DeckOption] {
            let allFactions: [CardFaction] = [.guardian, .seeker, .mystic, .rogue, .survivor]
            let allButMainFaction = allFactions.filter({ $0.id != mainFaction.id })
            
            return [
                DeckOptionAllowedFactions([mainFaction, .neutral]),
                DeckOptionAllowedFactions(allButMainFaction, levels: [0], maxQuantity: 5)
            ]
        }
        
        switch id {
        case 1001: return genCoreDeckOptions(mainFaction: .guardian, secondaryFaction: .seeker)
        case 1002: return genCoreDeckOptions(mainFaction: .seeker, secondaryFaction: .mystic)
        case 1003: return genCoreDeckOptions(mainFaction: .rogue, secondaryFaction: .guardian)
        case 1004: return genCoreDeckOptions(mainFaction: .mystic, secondaryFaction: .survivor)
        case 1005: return genCoreDeckOptions(mainFaction: .survivor, secondaryFaction: .rogue)
        case 2001: return genDunwichDeckOptions(mainFaction: .guardian)
        case 2002: return genDunwichDeckOptions(mainFaction: .seeker)
        case 2003: return genDunwichDeckOptions(mainFaction: .rogue)
        case 2004: return genDunwichDeckOptions(mainFaction: .mystic)
        case 2005: return genDunwichDeckOptions(mainFaction: .survivor)
        default:
            let factions: [CardFaction] = [.neutral, .guardian, .seeker, .mystic, .rogue, .survivor]
            
            return [DeckOptionAllowedFactions(factions)]
        }
    }
}

public struct DeckOptionAllowedFactions: DeckOption {
    public var factions: [CardFaction]
    public var maxQuantity: Int
    public var levels: [Int]
    
    public init(_ factions: [CardFaction],
         levels: [Int] = [0, 1, 2, 3, 4, 5],
         maxQuantity: Int = Int.max) {
        self.factions = factions
        self.maxQuantity = maxQuantity
        self.levels = levels
    }
    
    public func isDeckValid(_ deck: Deck) -> Deck.DeckValidationResult {
        let numOfValidCards = deck.cards.filter { (deckCard) -> Bool in
            return contains(faction: deckCard.card.faction) && levels.contains(deckCard.card.level)
        }.reduce(0) { (partialResult, deckCard) -> Int in
            return partialResult + deckCard.quantity
        }
        
        if numOfValidCards > maxQuantity {
            return Deck.DeckValidationResult(isValid: false,
                                        message: "Too many cards of limited factions")
        }

        return Deck.DeckValidationResult(isValid: true, message: "Deck is valid")
    }
    
    private func contains(faction: CardFaction) -> Bool {
        for f in factions {
            if f.id == faction.id {
                return true
            }
        }
        return false
    }
}
