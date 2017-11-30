//
//  Card.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 19/04/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

public struct Card: Equatable {
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
    
    public static func ==(lhs: Card, rhs: Card) -> Bool {
        return lhs.id == rhs.id
    }
}
