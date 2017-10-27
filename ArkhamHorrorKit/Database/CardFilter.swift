//
//  CardFilter.swift
//  ArkhamHorrorKit iOS
//
//  Created by Tiago Bras on 26/10/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

struct CardFilter: Equatable {
    var cardIds = Set<Int>()
    var types = Set<CardType>()
    var subtypes = Set<CardSubtype>()
    var factions = Set<CardFaction>()
    var packs = Set<CardPack>()
    var assetSlots = Set<CardAssetSlot>()
    var levels = Set<Int>()
    var skillTestIcons = Set<CardSkillTestIcon>()
    var investigatorOnly: Investigator? = nil
    var hideRestrictedCards: Bool = true
    var fullTextSearchMatch: String? = nil
    var onlyDeck: Deck? = nil
    
    static func ==(lhs: CardFilter, rhs: CardFilter) -> Bool {
        if lhs.cardIds != rhs.cardIds { return false }
        if lhs.types != rhs.types { return false }
        if lhs.subtypes != rhs.subtypes { return false }
        if lhs.factions != rhs.factions { return false }
        if lhs.packs != rhs.packs { return false }
        if lhs.assetSlots != rhs.assetSlots { return false }
        if lhs.levels != rhs.levels { return false }
        if lhs.skillTestIcons != rhs.skillTestIcons { return false }
        if lhs.investigatorOnly != rhs.investigatorOnly { return false }
        if lhs.hideRestrictedCards != rhs.hideRestrictedCards { return false }
        if lhs.fullTextSearchMatch != rhs.fullTextSearchMatch { return false }
        if lhs.onlyDeck != rhs.onlyDeck { return false }
        
        return true
    }
}
