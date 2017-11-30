//
//  Investigator.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 31/05/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import TBSwiftKit

public struct Investigator: Equatable {
    public enum InvestigatorId: Int {
        case rolandBanksTheFed = 1001, daisyWalkerTheLibrarian = 1002, skidsOTooleTheExCon = 1003
        case agnesBakerTheWaitress = 1004, wendyAdamsTheUrchin = 1005, zoeySamarasTheChef = 2001
        case rexMurphyTheReporter = 2002, jennyBarnesTheDilettante = 2003, jimCulverTheMusician = 2004
        case ashcanPeteTheDrifter = 2005, markHarriganTheSoldier = 3001, minhThiPhanTheSecretary = 3002
        case sefinaRousseauThePainter = 3003, akachiOnyeleTheShaman = 3004, williamYorickTheGravedigger = 3005
        case lolaHayesTheActress = 3006
    }
    
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
        
        switch InvestigatorId(rawValue: id)! {
        case .rolandBanksTheFed:
            factions.append(contentsOf: [.guardian, .seeker])
        case .daisyWalkerTheLibrarian:
            factions.append(contentsOf: [.seeker, .mystic])
        case .skidsOTooleTheExCon:
            factions.append(contentsOf: [.rogue, .guardian])
        case .agnesBakerTheWaitress:
            factions.append(contentsOf: [.mystic, .survivor])
        case .wendyAdamsTheUrchin:
            factions.append(contentsOf: [.survivor, .rogue])
        case .markHarriganTheSoldier:
            factions.append(contentsOf:
                [.guardian, .seeker, .mystic, .rogue, .survivor])
        case .minhThiPhanTheSecretary:
            factions.append(contentsOf: [.seeker, .survivor])
        case .sefinaRousseauThePainter:
            factions.append(contentsOf: [.rogue, .mystic])
        case .akachiOnyeleTheShaman:
            factions.append(contentsOf:
                [.guardian, .seeker, .mystic, .rogue, .survivor])
        case .williamYorickTheGravedigger:
            factions.append(contentsOf: [.survivor, .guardian])
        case .lolaHayesTheActress:
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
        
        switch InvestigatorId(rawValue: id)! {
        case .rolandBanksTheFed:
            filter = CardFilter(factions: [.guardian, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: [.seeker], fromLevel: 0, toLevel: 2))
        case .daisyWalkerTheLibrarian:
            filter = CardFilter(factions: [.seeker, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: [.mystic], fromLevel: 0, toLevel: 2))
        case .skidsOTooleTheExCon:
            filter = CardFilter(factions: [.rogue, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: [.guardian], fromLevel: 0, toLevel: 2))
        case .agnesBakerTheWaitress:
            filter = CardFilter(factions: [.mystic, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: [.survivor], fromLevel: 0, toLevel: 2))
        case .wendyAdamsTheUrchin:
            filter = CardFilter(factions: [.survivor, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: [.rogue], fromLevel: 0, toLevel: 2))
        case .zoeySamarasTheChef:
            filter = CardFilter(factions: [.guardian, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: Array(allFactions.subtracting(filter.factions)), level: 0))
        case .rexMurphyTheReporter:
            filter = CardFilter(factions: [.seeker, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: Array(allFactions.subtracting(filter.factions)), level: 0))
        case .jennyBarnesTheDilettante:
            filter = CardFilter(factions: [.rogue, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: Array(allFactions.subtracting(filter.factions)), level: 0))
        case .jimCulverTheMusician:
            filter = CardFilter(factions: [.mystic, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: Array(allFactions.subtracting(filter.factions)), level: 0))
        case .ashcanPeteTheDrifter:
            filter = CardFilter(factions: [.survivor, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: Array(allFactions.subtracting(filter.factions)), level: 0))
        case .markHarriganTheSoldier:
            filter = CardFilter(factions: [.guardian, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(traits: ["Tactic"], level: 0))
        case .minhThiPhanTheSecretary:
            filter = CardFilter(factions: [.seeker, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: [.survivor], fromLevel: 0, toLevel: 2))
        case .sefinaRousseauThePainter:
            filter = CardFilter(factions: [.rogue, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: [.mystic], fromLevel: 0, toLevel: 2))
        case .akachiOnyeleTheShaman:
            filter = CardFilter(factions: [.mystic, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(usesCharges: true, fromLevel: 0, toLevel: 4))
            filter.or(CardFilter(traits: ["Occult"], level: 0))
        case .williamYorickTheGravedigger:
            filter = CardFilter(factions: [.survivor, .neutral], fromLevel: 0, toLevel: 5)
            filter.or(CardFilter(factions: [.guardian], fromLevel: 0, toLevel: 2))
        case .lolaHayesTheActress:
            filter = CardFilter(
                factions: Array(allFactions.subtracting([CardFaction.neutral])),
                fromLevel: 0,
                toLevel: 3)
            filter.or(CardFilter(factions: [.neutral], fromLevel: 0, toLevel: 5))
        }
        
        return filter
    }
    
    typealias CardId = Int
    typealias CardQuantity = Int
    
    static func requiredCardsIds(investigatorId: Int) -> [CardId: CardQuantity] {
        switch InvestigatorId(rawValue: investigatorId)! {
        case .rolandBanksTheFed:  return [1006: 1, 1007: 1]
        case .daisyWalkerTheLibrarian:  return [1008: 1, 1009: 1]
        case .skidsOTooleTheExCon:  return [1010: 1, 1011: 1]
        case .agnesBakerTheWaitress:  return [1012: 1, 1013: 1]
        case .wendyAdamsTheUrchin:  return [1014: 1, 1015: 1]
        case .zoeySamarasTheChef:  return [2006: 1, 2007: 1]
        case .rexMurphyTheReporter:  return [2008: 1, 2009: 1]
        case .jennyBarnesTheDilettante:  return [2010: 1, 2011: 1]
        case .jimCulverTheMusician:  return [2012: 1, 2013: 1]
        case .ashcanPeteTheDrifter:  return [2014: 1, 2015: 1]
        case .markHarriganTheSoldier:  return [3007: 1, 3008: 1, 3009: 1]
        case .minhThiPhanTheSecretary:  return [3010: 1, 3011: 1]
        case .sefinaRousseauThePainter:  return [3012: 3, 3013: 1]
        case .akachiOnyeleTheShaman:  return [3014: 1, 3015: 1]
        case .williamYorickTheGravedigger:  return [3016: 1, 3017: 1]
        case .lolaHayesTheActress:  return [3018: 2, 3019: 2]
        }
    }
    
    public var avatar: Image {
        let bundle = Bundle(for: Investigator.Dummy.self)
        
        switch InvestigatorId(rawValue: id)! {
        case .rolandBanksTheFed: return Image.inBundle("roland_banks_the_fed", bundle)
        case .daisyWalkerTheLibrarian: return Image.inBundle("daisy_walker_the_librarian", bundle)
        case .skidsOTooleTheExCon: return Image.inBundle("skids_o_toole_the_ex_con", bundle)
        case .agnesBakerTheWaitress: return Image.inBundle("agnes_baker_the_waitress", bundle)
        case .wendyAdamsTheUrchin: return Image.inBundle("wendy_adams_the_urchin", bundle)
        case .zoeySamarasTheChef: return Image.inBundle("zoey_samaras_the_chef", bundle)
        case .rexMurphyTheReporter: return Image.inBundle("rex_murphy_the_reporter", bundle)
        case .jennyBarnesTheDilettante: return Image.inBundle("jenny_barnes_the_dilettante", bundle)
        case .jimCulverTheMusician: return Image.inBundle("jim_culver_the_musician", bundle)
        case .ashcanPeteTheDrifter: return Image.inBundle("ashcan_pete_the_drifter", bundle)
        case .markHarriganTheSoldier: return Image.inBundle("mark_harrigan_the_soldier", bundle)
        case .minhThiPhanTheSecretary: return Image.inBundle("minh_thi_phan_the_secretary", bundle)
        case .sefinaRousseauThePainter: return Image.inBundle("sefina_rousseau_the_painter", bundle)
        case .akachiOnyeleTheShaman: return Image.inBundle("akachi_onyele_the_shaman", bundle)
        case .williamYorickTheGravedigger: return Image.inBundle("william_yorick_the_gravedigger", bundle)
        case .lolaHayesTheActress: return Image.inBundle("lola_hayes_the_actress", bundle)
        }
    }
    
    public var frontImage: Image {
        let bundle = Bundle(for: Investigator.Dummy.self)
        
        return Image.inBundle("0\(id)", bundle)
    }
    
    public var backImage: Image {
        let bundle = Bundle(for: Investigator.Dummy.self)
        
        return Image.inBundle("0\(id)b", bundle)
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
        
        switch InvestigatorId(rawValue: id)! {
        case .rolandBanksTheFed: return genCoreDeckOptions(mainFaction: .guardian, secondaryFaction: .seeker)
        case .daisyWalkerTheLibrarian: return genCoreDeckOptions(mainFaction: .seeker, secondaryFaction: .mystic)
        case .skidsOTooleTheExCon: return genCoreDeckOptions(mainFaction: .rogue, secondaryFaction: .guardian)
        case .agnesBakerTheWaitress: return genCoreDeckOptions(mainFaction: .mystic, secondaryFaction: .survivor)
        case .wendyAdamsTheUrchin: return genCoreDeckOptions(mainFaction: .survivor, secondaryFaction: .rogue)
        case .zoeySamarasTheChef: return genDunwichDeckOptions(mainFaction: .guardian)
        case .rexMurphyTheReporter: return genDunwichDeckOptions(mainFaction: .seeker)
        case .jennyBarnesTheDilettante: return genDunwichDeckOptions(mainFaction: .rogue)
        case .jimCulverTheMusician: return genDunwichDeckOptions(mainFaction: .mystic)
        case .ashcanPeteTheDrifter: return genDunwichDeckOptions(mainFaction: .survivor)
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

