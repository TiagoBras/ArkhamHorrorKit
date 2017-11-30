//
//  Investigator.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 31/05/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import TBSwiftKit

public struct Investigator: Equatable {
    class Dummy {}
    
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
    public var requiredCards: [DeckCard]
    
    public static func ==(lhs: Investigator, rhs: Investigator) -> Bool {
        return lhs.id == rhs.id
    }

    public var deckSize: Int {
        if id == 3003 {
            return 33
        } else if id == 3006 {
            return 35
        } else {
            return 30
        }
    }
    
    public var availableFactions: [CardFaction] {
        var factions: [CardFaction] = [.neutral]
        
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
        case 3001:
            factions.append(contentsOf:
                [.guardian, .seeker, .mystic, .rogue, .survivor])
        case 3002:
            factions.append(contentsOf: [.seeker, .survivor])
        case 3003:
            factions.append(contentsOf: [.rogue, .mystic])
        case 3004:
            factions.append(contentsOf:
                [.guardian, .seeker, .mystic, .rogue, .survivor])
        case 3005:
            factions.append(contentsOf: [.survivor, .guardian])
        case 3006:
            factions.append(contentsOf:
                [.guardian, .seeker, .mystic, .rogue, .survivor])
        default:
            factions.append(contentsOf:
                [.guardian, .seeker, .mystic, .rogue, .survivor])
        }
        
        return factions
    }
    
    public var availableCardsFilter: CardFilter {
        var filter = CardFilter()
        
        let allFactions = Set<CardFaction>(CardFaction.allValues)

        switch id {
        case 1001:
            filter = CardFilter(factions: [.guardian, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: [.seeker], fromLevel: 0, toLevel: 2))
        case 1002:
            filter = CardFilter(factions: [.seeker, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: [.mystic], fromLevel: 0, toLevel: 2))
        case 1003:
            filter = CardFilter(factions: [.rogue, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: [.guardian], fromLevel: 0, toLevel: 2))
        case 1004:
            filter = CardFilter(factions: [.mystic, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: [.survivor], fromLevel: 0, toLevel: 2))
        case 1005:
            filter = CardFilter(factions: [.survivor, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: [.rogue], fromLevel: 0, toLevel: 2))
        case 2001:
            filter = CardFilter(factions: [.guardian, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: Array(allFactions.subtracting(filter.factions)), level: 0))
        case 2002:
            filter = CardFilter(factions: [.seeker, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: Array(allFactions.subtracting(filter.factions)), level: 0))
        case 2003:
            filter = CardFilter(factions: [.rogue, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: Array(allFactions.subtracting(filter.factions)), level: 0))
        case 2004:
            filter = CardFilter(factions: [.mystic, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: Array(allFactions.subtracting(filter.factions)), level: 0))
        case 2005:
            filter = CardFilter(factions: [.survivor, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: Array(allFactions.subtracting(filter.factions)), level: 0))
        case 3001:
            filter = CardFilter(factions: [.guardian, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(traits: ["Tactic"], level: 0))
        case 3002:
            filter = CardFilter(factions: [.seeker, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: [.survivor], fromLevel: 0, toLevel: 2))
        case 3003:
            filter = CardFilter(factions: [.rogue, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: [.mystic], fromLevel: 0, toLevel: 2))
        case 3004:
            filter = CardFilter(factions: [.mystic, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(usesCharges: true, fromLevel: 0, toLevel: 4))
        case 3005:
            filter = CardFilter(factions: [.survivor, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: [.guardian], fromLevel: 0, toLevel: 2))
        case 3006:
            filter = CardFilter(
                factions: Array(allFactions.subtracting([CardFaction.neutral])),
                fromLevel: 0,
                toLevel: 3)
            filter.or(CardFilter(factions: [.neutral], fromLevel: 0, toLevel: 5))
        default: break
        }
        
        return filter
    }
    
    typealias CardId = Int
    typealias CardQuantity = Int
    
    static func requiredCardsIds(investigatorId: Int) -> [CardId: CardQuantity] {
        switch investigatorId {
        case 1001:  return [1006: 1, 1007: 1]
        case 1002:  return [1008: 1, 1009: 1]
        case 1003:  return [1010: 1, 1011: 1]
        case 1004:  return [1012: 1, 1013: 1]
        case 1005:  return [1014: 1, 1015: 1]
        case 2001:  return [2006: 1, 2007: 1]
        case 2002:  return [2008: 1, 2009: 1]
        case 2003:  return [2010: 1, 2011: 1]
        case 2004:  return [2012: 1, 2013: 1]
        case 2005:  return [2014: 1, 2015: 1]
        case 3001:  return [3007: 1, 3008: 1, 3009: 1]
        case 3002:  return [3010: 1, 3011: 1]
        case 3003:  return [3012: 3, 3013: 1]
        case 3004:  return [3014: 1, 3015: 1]
        case 3005:  return [3016: 1, 3017: 1]
        case 3006:  return [3018: 2, 3019: 2]
        default: return [:]
        }
    }
    
    public var avatar: Image {
        let bundle = Bundle(for: Investigator.Dummy.self)
        switch id {
        case 1001: return Image.inBundle("roland_banks_the_fed", bundle)
        case 1002: return Image.inBundle("daisy_walker_the_librarian", bundle)
        case 1003: return Image.inBundle("skids_o_toole_the_ex_con", bundle)
        case 1004: return Image.inBundle("agnes_baker_the_waitress", bundle)
        case 1005: return Image.inBundle("wendy_adams_the_urchin", bundle)
        case 2001: return Image.inBundle("zoey_samaras_the_chef", bundle)
        case 2002: return Image.inBundle("rex_murphy_the_reporter", bundle)
        case 2003: return Image.inBundle("jenny_barnes_the_dilettante", bundle)
        case 2004: return Image.inBundle("jim_culver_the_musician", bundle)
        case 2005: return Image.inBundle("ashcan_pete_the_drifter", bundle)
        case 3001: return Image.inBundle("mark_harrigan_the_soldier", bundle)
        case 3002: return Image.inBundle("minh_thi_phan_the_secretary", bundle)
        case 3003: return Image.inBundle("sefina_rousseau_the_painter", bundle)
        case 3004: return Image.inBundle("akachi_onyele_the_shaman", bundle)
        case 3005: return Image.inBundle("william_yorick_the_gravedigger", bundle)
        case 3006: return Image.inBundle("lola_hayes_the_actress", bundle)
        default: return Image.inBundle("unknown", bundle)
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
