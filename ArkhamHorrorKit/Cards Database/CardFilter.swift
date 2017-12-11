//  Copyright © 2017 Tiago Bras. All rights reserved.

public struct CardFilter: Equatable {
    public var cardIds = Set<Int>()
    public var types = Set<CardType>()
    public var subtypes = Set<CardSubtype>()
    public var factions = Set<CardFaction>()
    public var packs = Set<CardPack>()
    public var assetSlots = Set<CardAssetSlot>()
    public var levels = Set<Int>()
    public var skillTestIcons = Set<CardSkillTestIcon>()
    public var investigatorId: Int? = nil
    public var hideRestrictedCards: Bool? = nil
    public var fullTextSearchMatch: String? = nil
    public var deckId: Int? = nil
    public var traits = Set<String>()
    public var usesCharges: Bool? = nil
    public var hideWeaknesses: Bool? = nil
    
    public init() { }
    
    public init(factions: [CardFaction], fromLevel: Int, toLevel: Int) {
        assert(fromLevel <= toLevel)
        
        self.factions = Set(factions)
        self.levels = Set(Array(fromLevel...toLevel))
    }
    
    public init(factions: [CardFaction], level: Int) {
        self.init(factions: factions, fromLevel: level, toLevel: level)
    }
    
    public init(traits: [String], level: Int) {
        self.traits = Set(traits)
        self.levels = Set([level])
    }
    
    public init(usesCharges: Bool, fromLevel: Int, toLevel: Int) {
        self.usesCharges = usesCharges
        self.levels = Set(Array(fromLevel...toLevel))
    }
    
    public init(fullSearchText: String) {
        self.fullTextSearchMatch = fullSearchText
    }
    
    public init(investigatorId: Int) {
        self.investigatorId = investigatorId
    }
    
    public init(deckId: Int) {
        self.deckId = deckId
    }
    
    public static func basicWeaknesses() -> CardFilter {
        var filter = CardFilter()
        filter.subtypes.insert(CardSubtype.basicweakness)
        
        return filter
    }
    
    public static func ==(lhs: CardFilter, rhs: CardFilter) -> Bool {
        if lhs.cardIds != rhs.cardIds { return false }
        if lhs.types != rhs.types { return false }
        if lhs.subtypes != rhs.subtypes { return false }
        if lhs.factions != rhs.factions { return false }
        if lhs.packs != rhs.packs { return false }
        if lhs.assetSlots != rhs.assetSlots { return false }
        if lhs.levels != rhs.levels { return false }
        if lhs.skillTestIcons != rhs.skillTestIcons { return false }
        if lhs.investigatorId != rhs.investigatorId { return false }
        if lhs.hideRestrictedCards != rhs.hideRestrictedCards { return false }
        if lhs.fullTextSearchMatch != rhs.fullTextSearchMatch { return false }
        if lhs.deckId != rhs.deckId { return false }
        if lhs.subfilters.count != rhs.subfilters.count { return false }
        
        for (s1, s2) in zip(lhs.subfilters, rhs.subfilters) {
            guard s1.op == s2.op else { return false }
            guard s1.filter == s2.filter else { return false }
        }
        
        return true
    }
    
    public enum Operator: String {
        case and = "AND", or = "OR"
    }
    
    public struct CardSubFilter {
        public var op: Operator
        public var filter: CardFilter
    }
    
    public var subfilters: [CardSubFilter] = []
    
    public mutating func and(_ filter: CardFilter) {
        subfilters.append(CardSubFilter(op: .and, filter: filter))
    }
    
    public mutating func or(_ filter: CardFilter) {
        subfilters.append(CardSubFilter(op: .or, filter: filter))
    }
    
    public mutating func setFullTextSearchMatch(_ text: String, applyToSubFilters: Bool) {
        self.fullTextSearchMatch = text
        
        if applyToSubFilters {
            for i in 0..<subfilters.count {
                subfilters[i].filter.setFullTextSearchMatch(text, applyToSubFilters: true)
            }
        }
    }
    
    public mutating func setOnlyDeckId(_ deckId: Int, applyToSubFilters: Bool) {
        self.deckId = deckId
        
        if applyToSubFilters {
            for i in 0..<subfilters.count {
                subfilters[i].filter.setOnlyDeckId(deckId, applyToSubFilters: true)
            }
        }
    }
    
    public mutating func setHideWeaknesses(_ hide: Bool, applyToSubFilters: Bool) {
        self.hideWeaknesses = hide
        
        if applyToSubFilters {
            for i in 0..<subfilters.count {
                subfilters[i].filter.setHideWeaknesses(hide, applyToSubFilters: true)
            }
        }
    }
    
    func usesDeckId() -> Bool {
        if deckId != nil {
            return true
        }
        
        for subfilter in subfilters {
            if subfilter.filter.usesDeckId() {
                return true
            }
        }
        
        return false
    }
    
    func usesTraits() -> Bool {
        if !traits.isEmpty {
            return true
        }
        
        for subfilter in subfilters {
            if subfilter.filter.usesTraits() {
                return true
            }
        }
        
        return false
    }
}
