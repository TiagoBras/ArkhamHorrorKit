//
//  CardV1.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 18/10/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation
import GRDB
import SwiftyJSON

final class CardRecord: Record {
    private(set) var id: Int
    var position: Int
    var level: Int
    var cost: Int
    var quantity: Int
    var deckLimit: Int
    var name: String
    var subname: String
    var isUnique: Bool
    var text: String
    var typeId: Int
    var subtypeId: Int?
    var factionId: Int
    var packId: String
    var assetSlotId: Int?
    var traits: String
    var skillAgility: Int
    var skillCombat: Int
    var skillIntellect: Int
    var skillWillpower: Int
    var skillWild: Int
    var health: Int
    var sanity: Int
    var investigatorId: Int?
    var flavorText: String
    var illustrator: String
    var enemyFight: Int
    var enemyEvade: Int
    var enemyHealth: Int
    var enemyDamage: Int
    var enemyHorror: Int
    var enemyHealthPerInvestigator: Bool
    
    override class var databaseTableName: String {
        return "Card"
    }
    
    override class var persistenceConflictPolicy: PersistenceConflictPolicy {
        return PersistenceConflictPolicy(
            insert: .replace,
            update: .replace)
    }
    
    required init(row: Row) {
        id = row[RowKeys.id.rawValue]
        position = row[RowKeys.position.rawValue]
        level = row[RowKeys.level.rawValue]
        cost = row[RowKeys.cost.rawValue]
        quantity = row[RowKeys.quantity.rawValue]
        deckLimit = row[RowKeys.deckLimit.rawValue]
        name = row[RowKeys.name.rawValue]
        subname = row[RowKeys.subname.rawValue]
        isUnique = row[RowKeys.isUnique.rawValue]
        text = row[RowKeys.text.rawValue]
        typeId = row[RowKeys.typeId.rawValue]
        subtypeId = row[RowKeys.subtypeId.rawValue]
        factionId = row[RowKeys.factionId.rawValue]
        packId = row[RowKeys.packId.rawValue]
        assetSlotId = row[RowKeys.assetSlotId.rawValue]
        traits = row[RowKeys.traits.rawValue]
        skillAgility = row[RowKeys.skillAgility.rawValue]
        skillCombat = row[RowKeys.skillCombat.rawValue]
        skillIntellect = row[RowKeys.skillIntellect.rawValue]
        skillWillpower = row[RowKeys.skillWillpower.rawValue]
        skillWild = row[RowKeys.skillWild.rawValue]
        health = row[RowKeys.health.rawValue]
        sanity = row[RowKeys.sanity.rawValue]
        investigatorId = row[RowKeys.investigatorId.rawValue]
        flavorText = row[RowKeys.flavorText.rawValue]
        illustrator = row[RowKeys.illustrator.rawValue]
        enemyFight = row[RowKeys.enemyFight.rawValue]
        enemyEvade = row[RowKeys.enemyEvade.rawValue]
        enemyHealth = row[RowKeys.enemyHealth.rawValue]
        enemyDamage = row[RowKeys.enemyDamage.rawValue]
        enemyHorror = row[RowKeys.enemyHorror.rawValue]
        enemyHealthPerInvestigator = row[RowKeys.enemyHealthPerInvestigator.rawValue]
        
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[RowKeys.id.rawValue] = id
        container[RowKeys.position.rawValue] = position
        container[RowKeys.level.rawValue] = level
        container[RowKeys.cost.rawValue] = cost
        container[RowKeys.quantity.rawValue] = quantity
        container[RowKeys.deckLimit.rawValue] = deckLimit
        container[RowKeys.name.rawValue] = name
        container[RowKeys.subname.rawValue] = subname
        container[RowKeys.isUnique.rawValue] = isUnique
        container[RowKeys.text.rawValue] = text
        container[RowKeys.typeId.rawValue] = typeId
        container[RowKeys.subtypeId.rawValue] = subtypeId
        container[RowKeys.factionId.rawValue] = factionId
        container[RowKeys.packId.rawValue] = packId
        container[RowKeys.assetSlotId.rawValue] = assetSlotId
        container[RowKeys.traits.rawValue] = traits
        container[RowKeys.skillAgility.rawValue] = skillAgility
        container[RowKeys.skillCombat.rawValue] = skillCombat
        container[RowKeys.skillIntellect.rawValue] = skillIntellect
        container[RowKeys.skillWillpower.rawValue] = skillWillpower
        container[RowKeys.skillWild.rawValue] = skillWild
        container[RowKeys.health.rawValue] = health
        container[RowKeys.sanity.rawValue] = sanity
        container[RowKeys.investigatorId.rawValue] = investigatorId
        container[RowKeys.flavorText.rawValue] = flavorText
        container[RowKeys.illustrator.rawValue] = illustrator
        container[RowKeys.enemyFight.rawValue] = enemyFight
        container[RowKeys.enemyEvade.rawValue] = enemyEvade
        container[RowKeys.enemyHealth.rawValue] = enemyHealth
        container[RowKeys.enemyDamage.rawValue] = enemyDamage
        container[RowKeys.enemyHorror.rawValue] = enemyHorror
        container[RowKeys.enemyHealthPerInvestigator.rawValue] = enemyHealthPerInvestigator
    }
    
    class func fetchOne(db: Database, id: Int) throws -> CardRecord? {
        return try CardRecord.fetchOne(db, key: ["id": id])
    }
    
    class func loadJSONRecords(json: JSON, into db: Database) throws {
        for obj in json.arrayValue {
            guard obj["type_code"] != "investigator" else { continue }
            
            if let hidden = obj["hidden"].bool, hidden {
                continue
            }
            
            var dict = [String: DatabaseValueConvertible?]()
            dict[RowKeys.id.rawValue] = Int(obj["code"].stringValue)
            dict[RowKeys.position.rawValue] = obj["position"].intValue
            dict[RowKeys.level.rawValue] = obj["xp"].intValue
            dict[RowKeys.cost.rawValue] = obj["cost"].intValue
            dict[RowKeys.quantity.rawValue] = obj["quantity"].intValue
            dict[RowKeys.deckLimit.rawValue] = obj["deck_limit"].intValue
            dict[RowKeys.name.rawValue] = obj["name"].stringValue
            dict[RowKeys.subname.rawValue] = obj["subname"].stringValue
            dict[RowKeys.isUnique.rawValue] = obj["is_unique"].boolValue
            dict[RowKeys.text.rawValue] = obj["text"].stringValue
            
            guard let typeId = CardType(code: obj["type_code"].stringValue)?.rawValue else {
                throw CardError.invalidTypeCode(obj["type_code"].stringValue)
            }
            
            dict[RowKeys.typeId.rawValue] = typeId
            
            if let subtype = obj["subtype_code"].string {
                guard let subtypeId = CardSubtype(code: subtype)?.rawValue else {
                    throw CardError.invalidSubtypeCode(obj["type_code"].stringValue)
                }
                
                dict[RowKeys.subtypeId.rawValue] = subtypeId
            } else {
                dict[RowKeys.subtypeId.rawValue] = nil
            }

            guard let factionId = CardFaction(code: obj["faction_code"].stringValue)?.rawValue else {
                throw CardError.invalidFactionCode(obj["type_code"].stringValue)
            }
        
            dict[RowKeys.factionId.rawValue] = factionId
            dict[RowKeys.packId.rawValue] = obj["pack_code"].stringValue
            
            if let slot = obj["slot"].string {
                guard let slotId = CardAssetSlot(code: slot)?.rawValue else {
                    throw CardError.invalidAssetSlotCode(obj["type_code"].stringValue)
                }
                
                dict[RowKeys.assetSlotId.rawValue] = slotId
            } else {
                dict[RowKeys.assetSlotId.rawValue] = nil
            }
            
            dict[RowKeys.traits.rawValue] = obj["traits"].stringValue
            dict[RowKeys.skillAgility.rawValue] = obj["skill_agility"].intValue
            dict[RowKeys.skillCombat.rawValue] = obj["skill_combat"].intValue
            dict[RowKeys.skillIntellect.rawValue] = obj["skill_intellect"].intValue
            dict[RowKeys.skillWillpower.rawValue] = obj["skill_willpower"].intValue
            dict[RowKeys.skillWild.rawValue] = obj["skill_wild"].intValue
            
            if typeId != CardType.enemy.id {
                dict[RowKeys.health.rawValue] = obj["health"].intValue
            } else {
                dict[RowKeys.health.rawValue] = 0
            }
            
            dict[RowKeys.sanity.rawValue] = obj["sanity"].intValue
            
            let restrictions = obj["restrictions"].stringValue
            let components = restrictions.components(separatedBy: ":")
            
            if restrictions.hasPrefix("investigator:") && components.count == 2 {
                dict[RowKeys.investigatorId.rawValue] = Int(components[1])
            } else {
                dict[RowKeys.investigatorId.rawValue] = nil
            }
            
            dict[RowKeys.flavorText.rawValue] = obj["flavor"].stringValue
            dict[RowKeys.illustrator.rawValue] = obj["illustrator"].stringValue
            dict[RowKeys.enemyFight.rawValue] = obj["enemy_fight"].intValue
            dict[RowKeys.enemyEvade.rawValue] = obj["enemy_evade"].intValue
            
            if typeId == CardType.enemy.id {
                dict[RowKeys.enemyHealth.rawValue] = obj["health"].intValue
            } else {
                dict[RowKeys.enemyHealth.rawValue] = 0
            }
            
            dict[RowKeys.enemyDamage.rawValue] = obj["enemy_damage"].intValue
            dict[RowKeys.enemyHorror.rawValue] = obj["enemy_horror"].intValue
            dict[RowKeys.enemyHealthPerInvestigator.rawValue] = obj["health_per_investigator"].boolValue
            
            let card = CardRecord(row: Row(dict))
            
            try card.insert(db)
        }
    }
    
    // MARK:- Enumerations
    enum CardError: Error {
        case invalidTypeCode(String)
        case invalidSubtypeCode(String)
        case invalidFactionCode(String)
        case invalidAssetSlotCode(String)
    }
    
    enum RowKeys: String {
        case id = "id"
        case position = "position"
        case level = "level"
        case cost = "cost"
        case quantity = "quantity"
        case deckLimit = "deck_limit"
        case name = "name"
        case subname = "subname"
        case isUnique = "is_unique"
        case text = "text"
        case typeId = "type_id"
        case subtypeId = "subtype_id"
        case factionId = "faction_id"
        case packId = "pack_id"
        case assetSlotId = "asset_slot_id"
        case traits = "traits"
        case skillAgility = "skill_agility"
        case skillCombat = "skill_combat"
        case skillIntellect = "skill_intellect"
        case skillWillpower = "skill_willpower"
        case skillWild = "skill_wild"
        case health = "health"
        case sanity = "sanity"
        case investigatorId = "investigator_id"
        case flavorText = "flavor_text"
        case illustrator = "illustrator"
        case enemyFight = "enemy_fight"
        case enemyEvade = "enemy_evade"
        case enemyHealth = "enemy_health"
        case enemyDamage = "enemy_damage"
        case enemyHorror = "enemy_horror"
        case enemyHealthPerInvestigator = "enemy_health_per_investigator"
    }
    
    enum JSONKeys: String {
        case id = "id"
        case position = "position"
        case level = "level"
        case cost = "cost"
        case quantity = "quantity"
        case deckLimit = "deck_limit"
        case name = "name"
        case subname = "subname"
        case isUnique = "is_unique"
        case text = "text"
        case typeId = "type_id"
        case subtypeId = "subtype_id"
        case factionId = "faction_id"
        case packId = "pack_id"
        case assetSlotId = "asset_slot_id"
        case skillAgility = "skill_agility"
        case skillCombat = "skill_combat"
        case skillIntellect = "skill_intellect"
        case skillWillpower = "skill_willpower"
        case skillWild = "skill_wild"
        case health = "health"
        case sanity = "sanity"
        case investigatorId = "investigator_id"
        case flavorText = "flavor_text"
        case illustrator = "illustrator"
        case enemyFight = "enemy_fight"
        case enemyEvade = "enemy_evade"
        case enemyHealth = "enemy_health"
        case enemyDamage = "enemy_damage"
        case enemyHorror = "enemy_horror"
        case enemyHealthPerInvestigator = "enemy_health_per_investigator"
    }
    
    
    //    var id: Int
    //    var name: String
    //    var subname: String?
    //    var number: Int
    //    var level: Int
    //    var isUnique: Bool
    //    var text: String
    //    var cost: Int
    //    var setQuantity: Int
    //    var deckLimit: Int
    //    var restricted: Bool
    //
    //    private var typeId: Int
    //    private var typeName: String
    //    private var subtypeId: Int?
    //    private var subtypeName: String?
    //    private var factionId: Int
    //    private var factionName: String
    //    private var factionColor: String
    //    private var factionLightColor: String
    //    private var factionSaturatedColor: String
    //    private var packId: Int
    //    private var packName: String
    //    private var packPosition: Int
    //    private var cycleId: Int?
    //    private var cycleName: String?
    //    private var cyclePosition: Int?
    //    private var assetSlotId: Int?
    //    private var assetSlotName: String?
    //
    //    private var traitsIds: String?
    //    private var traitsNames: String?
    //
    //    var type: CardType {
    //        return CardType(rawValue: typeId)!
    //    }
    //
    //    var subtype: CardSubtype? {
    //        guard let id = subtypeId else { return nil }
    //
    //        return CardSubtype(rawValue: id)
    //    }
    //    var faction: CardFaction {
    //        return CardFaction(rawValue: factionId)!
    //    }
    //    var traits: [CardTrait] {
    //        guard let ids = traitsIds?.components(separatedBy: "|").flatMap({ Int($0) }) else { return [] }
    //        guard let names = traitsNames?.components(separatedBy: "|") else { return [] }
    //
    //        guard ids.count == names.count else {
    //            fatalError("Card '\(name)' traits ids don't match names: '\(ids)' & '\(names)'")
    //        }
    //
    //        return zip(ids, names).map{ (id, name) in
    //            return DBCardTrait(id: id, name: name)
    //        }
    //    }
    //    var pack: CardPack {
    //        return CardPack(rawValue: packId)!
    //    }
    //    var assetSlot: CardAssetSlot? {
    //        guard let assetSlotId = assetSlotId else { return nil }
    //
    //        return CardAssetSlot(rawValue: assetSlotId)!
    //    }
    //
    //    var skillAgility: Int
    //    var skillCombat: Int
    //    var skillIntellect: Int
    //    var skillWillpower: Int
    //    var skillWild: Int
    //
    //    var health: Int
    //    var sanity: Int
    //
    //    var flavorText: String?
    //    var illustrator: String?
    //
    //    var enemyFight: Int?
    //    var enemyEvade: Int?
    //    var enemyHealth: Int?
    //    var enemyDamage: Int?
    //    var enemyHorror: Int?
    //    var enemyHasHealthPerInvestigator: Bool?
    //
    //    override class var databaseTableName: String {
    //        return "CardExtendedView"
    //    }
    //
    //    required init(row: Row) {
    //        id = row["id"]
    //        number = row["number"]
    //        level = row["level"]
    //        cost = row["cost"]
    //        setQuantity = row["set_quantity"]
    //        deckLimit = row["deck_limit"]
    //        name = row["name"]
    //        subname = row["subname"]
    //        isUnique = row["is_unique"]
    //        text = row["text"]
    //        restricted = row["restricted"]
    //
    //        typeId = row["type_id"]
    //        typeName = row["type_name"]
    //        subtypeId = row["subtype_id"]
    //        subtypeName = row["subtype_name"]
    //        factionId = row["faction_id"]
    //        factionName = row["faction_name"]
    //        factionColor = row["faction_color"]
    //        factionLightColor = row["faction_light_color"]
    //        factionSaturatedColor = row["faction_saturated_color"]
    //        packId = row["pack_id"]
    //        packName = row["pack_name"]
    //        packPosition = row["pack_position"]
    //        cycleId = row["cycle_id"]
    //        cycleName = row["cycle_name"]
    //        cyclePosition = row["cycle_position"]
    //        assetSlotId = row["asset_slot_id"]
    //        assetSlotName = row["asset_slot_name"]
    //        traitsIds = row["traits_ids"]
    //        traitsNames = row["traits_names"]
    //
    //        skillAgility = row["skill_agility"]
    //        skillCombat = row["skill_combat"]
    //        skillIntellect = row["skill_intellect"]
    //        skillWillpower = row["skill_willpower"]
    //        skillWild = row["skill_wild"]
    //
    //        health = row["health"]
    //        sanity = row["sanity"]
    //
    //        flavorText = row["flavor_text"]
    //        illustrator = row["illustrator"]
    //
    //        enemyFight = row["enemy_fight"]
    //        enemyEvade = row["enemy_evade"]
    //        enemyHealth = row["enemy_health"]
    //        enemyDamage = row["enemy_damage"]
    //        enemyHorror = row["enemy_horror"]
    //        enemyHasHealthPerInvestigator = row["enemy_has_health_per_investigator"]
    //
    //        super.init(row: row)
    //    }
    //
    //    override func encode(to container: inout PersistenceContainer) {
    //        container["id"] = id
    //        container["number"] = number
    //        container["level"] = level
    //        container["cost"] = cost
    //        container["set_quantity"] = setQuantity
    //        container["deck_limit"] = deckLimit
    //        container["name"] = name
    //        container["subname"] = subname
    //        container["is_unique"] = isUnique
    //        container["restricted"] = restricted
    //        container["text"] = text
    //        container["type_id"] = typeId
    //        container["type_name"] = typeName
    //        container["subtype_id"] = subtypeId
    //        container["subtype_name"] = subtypeName
    //        container["faction_id"] = factionId
    //        container["faction_name"] = factionName
    //        container["faction_color"] = factionColor
    //        container["faction_light_color"] = factionLightColor
    //        container["faction_saturated_color"] = factionSaturatedColor
    //        container["pack_id"] = packId
    //        container["pack_name"] = packName
    //        container["pack_position"] = packPosition
    //        container["cycle_id"] = cycleId
    //        container["cycle_name"] = cycleName
    //        container["cycle_position"] = cyclePosition
    //        container["traits_ids"] = traitsIds
    //        container["traits_names"] = traitsNames
    //        container["asset_slot_id"] = assetSlotId
    //        container["asset_slot_name"] = assetSlotName
    //        container["skill_agility"] = skillAgility
    //        container["skill_combat"] = skillCombat
    //        container["skill_intellect"] = skillIntellect
    //        container["skill_willpower"] = skillWillpower
    //        container["skill_wild"] = skillWild
    //        container["health"] = health
    //        container["sanity"] = sanity
    //        container["flavor_text"] = flavorText
    //        container["illustrator"] = illustrator
    //        container["enemy_fight"] = enemyFight
    //        container["enemy_evade"] = enemyEvade
    //        container["enemy_health"] = enemyHealth
    //        container["enemy_damage"] = enemyDamage
    //        container["enemy_horror"] = enemyHorror
    //        container["enemy_has_health_per_investigator"] = enemyHasHealthPerInvestigator
    //    }
    //
    //
    //    override func insert(_ db: Database) throws {
    //        fatalError("Card.insert NOT implemented")
    //    }
}
