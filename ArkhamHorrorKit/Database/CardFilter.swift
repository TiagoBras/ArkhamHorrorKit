//
//  CardFilter.swift
//  ArkhamHorrorKit iOS
//
//  Created by Tiago Bras on 26/10/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

public struct CardFilter: Equatable {
    public var cardIds = Set<Int>()
    public var types = Set<CardType>()
    public var subtypes = Set<CardSubtype>()
    public var factions = Set<CardFaction>()
    public var packs = Set<CardPack>()
    public var assetSlots = Set<CardAssetSlot>()
    public var levels = Set<Int>()
    public var skillTestIcons = Set<CardSkillTestIcon>()
    public var investigatorOnly: Investigator? = nil
    public var hideRestrictedCards: Bool = true
    public var fullTextSearchMatch: String? = nil
    public var onlyDeck: Deck? = nil
    
    public init() { }
    
    public static func ==(lhs: CardFilter, rhs: CardFilter) -> Bool {
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
