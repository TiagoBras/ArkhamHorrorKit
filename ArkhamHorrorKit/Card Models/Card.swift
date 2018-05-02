//  Copyright © 2017 Tiago Bras. All rights reserved.
public struct Card: Hashable, Comparable, CustomStringConvertible {
    public var id: Int
    public var name: String
    public var subname: String
    public var cost: Int
    public var level: Int
    public var type: CardType
    public var subtype: CardSubtype?
    public var faction: CardFaction
    public var text: String
    public var pack: CardPack
    public var assetSlot: CardAssetSlot?
    public var position: Int
    public var quantity: Int
    public var deckLimit: Int
    public var isUnique: Bool
    public var skillAgility: Int
    public var skillCombat: Int
    public var skillIntellect: Int
    public var skillWillpower: Int
    public var skillWild: Int
    public var restrictedToInvestigator: Investigator?
    public var health: Int
    public var sanity: Int
    public var flavorText: String
    public var traits: [String]
    public var illustrator: String
    public var doubleSided: Bool
    public var enemyFight: Int
    public var enemyEvade: Int
    public var enemyHealth: Int
    public var enemyDamage: Int
    public var enemyHorror: Int
    public var enemyHealthPerInvestigator: Bool
    public var frontImageName: String
    public var backImageName: String?
    public var isFavorite: Bool
    public var isPermanent: Bool
    public var isEarnable: Bool
    
    public var isWeakness: Bool {
        return subtype != nil
    }
    
    public var isBasicWeakness: Bool {
        guard let subtype = subtype else { return false }
        
        return subtype == .basicweakness
    }
    
    public static func ==(lhs: Card, rhs: Card) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    public static func <(lhs: Card, rhs: Card) -> Bool {
        return lhs.id < rhs.id
    }
    
    public var hashValue: Int {
        return id.hashValue
    }
    
    public func isLessThan(card: Card, using sorter: CardsSortingDescriptor) -> Bool {
        return sorter.isLessThan(self, card)
    }
    
    public func isLessThan(card: Card, using sorters: [CardsSortingDescriptor]) -> Bool {
        for sorter in sorters {
            if sorter.isLessThan(self, card) {
                return true
            } else if sorter.isEqual(self, card) {
                continue
            } else {
                return false
            }
        }
        
        return false
    }
    
    public var description: String {
        return "id: \(id)\n" +
            "name: \(name)\n" +
            "subname: \(subname)\n" +
            "cost: \(cost)\n" +
            "level: \(level)\n" +
            "type: \(type)\n" +
            "subtype: \(subtype?.name ?? "nil")\n" +
            "faction: \(faction)\n" +
            "text: \(text)\n" +
            "pack: \(pack)\n" +
            "assetSlot: \(assetSlot?.name ?? "nil")\n" +
            "position: \(position)\n" +
            "quantity: \(quantity)\n" +
            "deckLimit: \(deckLimit)\n" +
            "isUnique: \(isUnique)\n" +
            "skillAgility: \(skillAgility)\n" +
            "skillCombat: \(skillCombat)\n" +
            "skillIntellect: \(skillIntellect)\n" +
            "skillWillpower: \(skillWillpower)\n" +
            "skillWild: \(skillWild)\n" +
            "restrictedToInvestigator: \(restrictedToInvestigator?.name ?? "nil")\n" +
            "health: \(health)\n" +
            "sanity: \(sanity)\n" +
            "flavorText: \(flavorText)\n" +
            "traits: \(traits)\n" +
            "illustrator: \(illustrator)\n" +
            "doubleSided: \(doubleSided)\n" +
            "enemyFight: \(enemyFight)\n" +
            "enemyEvade: \(enemyEvade)\n" +
            "enemyHealth: \(enemyHealth)\n" +
            "enemyDamage: \(enemyDamage)\n" +
            "enemyHorror: \(enemyHorror)\n" +
            "enemyHealthPerInvestigator: \(enemyHealthPerInvestigator)\n" +
            "frontImageName: \(frontImageName)\n" +
            "backImageName: \(backImageName ?? "nil")\n" +
            "isFavorite: \(isFavorite)\n" +
            "isPermanent: \(isPermanent)\n" +
            "isEarnable: \(isEarnable)\n" +
            "isWeakness: \(isWeakness)\n" +
            "isBasicWeakness: \(isBasicWeakness)"
    }
}
