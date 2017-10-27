//
//  CardsSortingDescriptor.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 19/04/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

struct CardsSortingDescriptor {
    enum CardColumn {
        case faction, type, pack, level, assetSlot, name
        
        var name: String {
            switch self {
            case .faction: return "Faction"
            case .type: return "Type"
            case .pack: return "Pack"
            case .level: return "Level"
            case .assetSlot: return "Asset Slot"
            case .name: return "Name"
            }
        }
    }
    
    var column: CardColumn
    var ascending: Bool
    
    static let defaultDescriptors: [CardsSortingDescriptor] = [
        CardsSortingDescriptor(column: .faction, ascending: true),
        CardsSortingDescriptor(column: .level, ascending: true),
        CardsSortingDescriptor(column: .type, ascending: true),
        CardsSortingDescriptor(column: .pack, ascending: true),
        CardsSortingDescriptor(column: .assetSlot, ascending: true),
        CardsSortingDescriptor(column: .name, ascending: true)
    ]
}

protocol CardStoreFetchResult {
    var numberOfSections: Int { get }
    
    func numberOfCards(inSection section: Int) -> Int
    func sectionName(_ section: Int) -> String?
    func card(_ indexPath: IndexPath) -> Card?
}

