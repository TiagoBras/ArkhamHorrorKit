//  Copyright © 2017 Tiago Bras. All rights reserved.

public struct CardsSortingDescriptor: Equatable {
    public enum CardColumn {
        case faction, type, pack, level, assetSlot, name, favoriteStatus
        
        public var name: String {
            switch self {
            case .faction: return "Faction"
            case .type: return "Type"
            case .pack: return "Pack"
            case .level: return "Level"
            case .assetSlot: return "Asset Slot"
            case .name: return "Name"
            case .favoriteStatus: return "Favorite"
            }
        }
    }
    
    public var column: CardColumn
    public var ascending: Bool
    
    public static let defaultDescriptors: [CardsSortingDescriptor] = [
        CardsSortingDescriptor(column: .faction, ascending: true),
        CardsSortingDescriptor(column: .name, ascending: true),
        CardsSortingDescriptor(column: .level, ascending: true),
        CardsSortingDescriptor(column: .type, ascending: true),
        CardsSortingDescriptor(column: .pack, ascending: true),
        CardsSortingDescriptor(column: .assetSlot, ascending: true)
    ]
    
    public static func ==(lhs: CardsSortingDescriptor, rhs: CardsSortingDescriptor) -> Bool {
        return lhs.column == rhs.column && lhs.ascending == rhs.ascending
    }
    
    public func isLessThan(_ a: Card, _ b: Card) -> Bool {
        var isLessThan: Bool = false
        
        switch column {
        case .faction: isLessThan = a.faction.id < b.faction.id
        case .type: isLessThan = a.type.id < b.type.id
        case .pack: isLessThan = a.type.id < b.type.id
        case .level: isLessThan = a.level < b.level
        case .assetSlot: isLessThan = (a.assetSlot?.id ?? -1) < (b.assetSlot?.id ?? -1)
        case .name: isLessThan = a.name < b.name
        case .favoriteStatus: isLessThan = !a.isFavorite && b.isFavorite
        }
        
        if ascending {
            return isLessThan
        } else {
            return !isLessThan
        }
    }
    
    public func isLessThan(_ a: DeckCard, _ b: DeckCard) -> Bool {
        return isLessThan(a.card, b.card)
    }
    
    public func isEqual(_ a: Card, _ b: Card) -> Bool {
        var isEqual: Bool = false
        
        switch column {
        case .faction: isEqual = a.faction.id == b.faction.id
        case .type: isEqual = a.type.id == b.type.id
        case .pack: isEqual = a.type.id == b.type.id
        case .level: isEqual = a.level == b.level
        case .assetSlot: isEqual = (a.assetSlot?.id ?? -1) == (b.assetSlot?.id ?? -1)
        case .name: isEqual = a.name == b.name
        case .favoriteStatus: isEqual = a.isFavorite == b.isFavorite
        }
        
        if ascending {
            return isEqual
        } else {
            return !isEqual
        }
    }
    
    public func isEqual(_ a: DeckCard, _ b: DeckCard) -> Bool {
        return isEqual(a.card, b.card)
    }
}

public protocol CardStoreFetchResult {
    var numberOfSections: Int { get }
    
    func numberOfCards(inSection section: Int) -> Int
    func sectionName(_ section: Int) -> String?
    func card(_ indexPath: IndexPath) -> Card?
}

