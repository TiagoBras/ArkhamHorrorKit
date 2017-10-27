//
//  Card.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 19/04/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

public struct Card {
    var id: Int
    var name: String
    var subname: String
    var cost: Int
    var level: Int
    var type: CardType
    var subtype: CardSubtype?
    var faction: CardFaction
    var text: String
    var pack: CardPack
    var assetSlot: CardAssetSlot?
    var position: Int
    var quantity: Int
    var deckLimit: Int
    var isUnique: Bool
    var skillAgility: Int
    var skillCombat: Int
    var skillIntellect: Int
    var skillWillpower: Int
    var skillWild: Int
    var restrictedToInvestigator: Investigator?
    var health: Int
    var sanity: Int
    var flavorText: String
    var traits: String
    var illustrator: String
    var enemyFight: Int
    var enemyEvade: Int
    var enemyHealth: Int
    var enemyDamage: Int
    var enemyHorror: Int
    var enemyHealthPerInvestigator: Bool
}
