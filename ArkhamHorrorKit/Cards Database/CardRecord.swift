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
    public private(set) var id: Int
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
    var doubleSided: Bool
    var enemyFight: Int
    var enemyEvade: Int
    var enemyHealth: Int
    var enemyDamage: Int
    var enemyHorror: Int
    var enemyHealthPerInvestigator: Bool
    var internalCode: String
    var usesCharges: Bool
    
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
        doubleSided = row[RowKeys.doubleSided.rawValue]
        enemyFight = row[RowKeys.enemyFight.rawValue]
        enemyEvade = row[RowKeys.enemyEvade.rawValue]
        enemyHealth = row[RowKeys.enemyHealth.rawValue]
        enemyDamage = row[RowKeys.enemyDamage.rawValue]
        enemyHorror = row[RowKeys.enemyHorror.rawValue]
        enemyHealthPerInvestigator = row[RowKeys.enemyHealthPerInvestigator.rawValue]
        internalCode = row[RowKeys.internalCode.rawValue]
        usesCharges = row[RowKeys.usesCharges.rawValue]
        
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
        container[RowKeys.doubleSided.rawValue] = doubleSided
        container[RowKeys.enemyFight.rawValue] = enemyFight
        container[RowKeys.enemyEvade.rawValue] = enemyEvade
        container[RowKeys.enemyHealth.rawValue] = enemyHealth
        container[RowKeys.enemyDamage.rawValue] = enemyDamage
        container[RowKeys.enemyHorror.rawValue] = enemyHorror
        container[RowKeys.enemyHealthPerInvestigator.rawValue] = enemyHealthPerInvestigator
        container[RowKeys.internalCode.rawValue] = internalCode
        container[RowKeys.usesCharges.rawValue] = usesCharges
    }
    
    class func fetchOne(db: Database, id: Int) throws -> CardRecord? {
        return try CardRecord.fetchOne(db, key: ["id": id])
    }
    
    class func fetchAll(db: Database, ids: [Int]) throws -> [CardRecord] {
        guard ids.count > 0 else { return [] }
        
        let idsString = ids.map({ String($0) }).joined(separator: ", ")
        
        let sql = "SELECT * FROM \(CardRecord.databaseTableName) WHERE id IN (\(idsString))"
        
        return try CardRecord.fetchAll(db, sql)
    }
    
    class func loadJSONRecords(json: JSON, into db: Database) throws {
        for obj in json.arrayValue {
            guard obj["type_code"].string != nil else {
                throw CardError.jsonDoesNotContainCards
            }
            
            guard obj["type_code"] != "investigator" else { continue }
            
            if let hidden = obj["hidden"].bool, hidden {
                continue
            }
            
            var dict = [String: DatabaseValueConvertible?]()
            dict[RowKeys.id.rawValue] = Int(obj["code"].stringValue)
            dict[RowKeys.internalCode.rawValue] = obj["code"].stringValue
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
            dict[RowKeys.doubleSided.rawValue] = obj["double_sided"].boolValue
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
            dict[RowKeys.usesCharges.rawValue] = CardRecord.doesCardUsesCharges(obj["text"].stringValue)
            
            let card = CardRecord(row: Row(dict))
            
            try card.save(db)
            
            try CardRecord.updateCardFTS(db, card: card)
            
            try insertOrIgnoreTraitsIntoDatabase(db, card: card)
        }
    }
    
    class private func updateCardFTS(_ db: Database, card: CardRecord) throws {
        var keywords = [String]()
        keywords.append(String(card.id))
        keywords.append(card.name)
        keywords.append(card.subname)
        
        if let type = CardType(rawValue: card.typeId)?.name {
            keywords.append(type)
            keywords.append("type:\(type)")
        }
        
        if let faction = CardFaction(rawValue: card.factionId)?.name {
            keywords.append(faction)
            keywords.append("faction:\(faction)")
        }
        
        if card.traits.count > 0 {
            let dotsRemoved = card.traits.replacingOccurrences(of: ".", with: "")
            let traits = dotsRemoved.components(separatedBy: " ").map({ "trait:\($0)" })
            
            keywords.append(traits.joined(separator: " "))
        }
        
        if let slotId = card.assetSlotId {
            if let slot = CardAssetSlot(rawValue: slotId)?.name {
                keywords.append(slot)
                keywords.append("slot:\(slot)")
            }
        }
        
        if card.isUnique {
            keywords.append("unique")
        }
        if card.sanity > 0 {
            keywords.append("sanity:\(card.sanity)")
        }
        if card.health > 0 {
            keywords.append("health:\(card.health)")
        }
        if card.skillWillpower > 0 {
            keywords.append("willpower:\(card.skillWillpower)")
        }
        if card.skillIntellect > 0 {
            keywords.append("intellect:\(card.skillIntellect)")
        }
        if card.skillCombat > 0 {
            keywords.append("combat:\(card.skillCombat)")
        }
        if card.skillAgility > 0 {
            keywords.append("agility:\(card.skillAgility)")
        }
        if card.skillWild > 0 {
            keywords.append("wild:\(card.skillWild)")
        }
        if card.subtypeId != nil {
            keywords.append("weakness")
        }
        
        keywords.append(card.text)
        keywords.append(card.illustrator)
        keywords.append(card.flavorText)
        
        let keywordsString = keywords.joined(separator: " ").replacingOccurrences(of: ".", with: "")
        
        if let count = try Int.fetchOne(db, "SELECT Count(*) FROM CardFTS WHERE id = \(card.id)") {
            if count > 0 {
                let sql = """
                INSERT OR REPLACE INTO CardFTS
                (rowid, id, keywords)
                SELECT CardFTS.rowid, ?, ? FROM CardFTS
                WHERE id = ?
                """
                
                try db.execute(sql, arguments: [card.id, keywordsString, card.id])
            } else {
                let sql = "INSERT INTO CardFTS (id, keywords) VALUES (?, ?)"
                
                try db.execute(sql, arguments: [card.id, keywordsString])
            }
        }
    }
    
    class private func insertOrIgnoreTraitsIntoDatabase(_ db: Database, card: CardRecord) throws {
        let dotsRemoved = card.traits.replacingOccurrences(of: ".", with: "")
        let traits = dotsRemoved.components(separatedBy: " ")
        
        for trait in traits {
            let sql = "INSERT OR IGNORE INTO \(TraitRecord.databaseTableName) VALUES (?)"
            
            try db.execute(sql, arguments: [trait])
            
            try CardTraitRecord(cardId: card.id, traitName: trait).save(db)
        }
    }
    
    class private func doesCardUsesCharges(_ cardText: String) -> Bool {
        let regex = "Uses \\(\\w+ charges?\\)"
        
        return cardText.range(of: regex,
                              options: [.regularExpression, .caseInsensitive],
                              range: nil,
                              locale: nil) != nil
    }
    
    // MARK:- Enumerations
    enum CardError: Error {
        case invalidTypeCode(String)
        case invalidSubtypeCode(String)
        case invalidFactionCode(String)
        case invalidAssetSlotCode(String)
        case jsonDoesNotContainCards
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
        case doubleSided = "double_sided"
        case enemyFight = "enemy_fight"
        case enemyEvade = "enemy_evade"
        case enemyHealth = "enemy_health"
        case enemyDamage = "enemy_damage"
        case enemyHorror = "enemy_horror"
        case enemyHealthPerInvestigator = "enemy_health_per_investigator"
        case internalCode = "internal_code"
        case usesCharges = "uses_charges"
    }
}
