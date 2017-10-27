//
//  InvestigatorRecord.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 21/10/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation
import GRDB
import SwiftyJSON

class InvestigatorRecord: Record {
    var id: Int
    var name: String
    var position: Int
    var subname: String
    var health: Int
    var sanity: Int
    var factionId: Int
    var packId: String
    var frontText: String
    var backText: String
    var agility: Int
    var combat: Int
    var intellect: Int
    var willpower: Int
    var traits: String
    var frontFlavor: String
    var backFlavor: String
    var illustrator: String
    
    override class var databaseTableName: String {
        return "Investigator"
    }
    
    override class var persistenceConflictPolicy: PersistenceConflictPolicy {
        return PersistenceConflictPolicy(
            insert: .replace,
            update: .replace)
    }
    
    required init(row: Row) {
        id = row[RowKeys.id.rawValue]
        name = row[RowKeys.name.rawValue]
        position = row[RowKeys.position.rawValue]
        subname = row[RowKeys.subname.rawValue]
        health = row[RowKeys.health.rawValue]
        sanity = row[RowKeys.sanity.rawValue]
        factionId = row[RowKeys.factionId.rawValue]
        packId = row[RowKeys.packId.rawValue]
        frontText = row[RowKeys.frontText.rawValue]
        backText = row[RowKeys.backText.rawValue]
        agility = row[RowKeys.agility.rawValue]
        combat = row[RowKeys.combat.rawValue]
        intellect = row[RowKeys.intellect.rawValue]
        willpower = row[RowKeys.willpower.rawValue]
        traits = row[RowKeys.traits.rawValue]
        frontFlavor = row[RowKeys.frontFlavor.rawValue]
        backFlavor = row[RowKeys.backFlavor.rawValue]
        illustrator = row[RowKeys.illustrator.rawValue]
        
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[RowKeys.id.rawValue] = id
        container[RowKeys.name.rawValue] = name
        container[RowKeys.position.rawValue] = position
        container[RowKeys.subname.rawValue] = subname
        container[RowKeys.health.rawValue] = health
        container[RowKeys.sanity.rawValue] = sanity
        container[RowKeys.factionId.rawValue] = factionId
        container[RowKeys.packId.rawValue] = packId
        container[RowKeys.frontText.rawValue] = frontText
        container[RowKeys.backText.rawValue] = backText
        container[RowKeys.agility.rawValue] = agility
        container[RowKeys.combat.rawValue] = combat
        container[RowKeys.intellect.rawValue] = intellect
        container[RowKeys.willpower.rawValue] = willpower
        container[RowKeys.traits.rawValue] = traits
        container[RowKeys.frontFlavor.rawValue] = frontFlavor
        container[RowKeys.backFlavor.rawValue] = backFlavor
        container[RowKeys.illustrator.rawValue] = illustrator
    }
    
    class func fetchOne(db: Database, id: Int) throws -> InvestigatorRecord? {
        return try InvestigatorRecord.fetchOne(db, key: ["id": id])
    }
    
    class func loadJSONRecords(json: JSON, into db: Database) throws {
        for obj in json.arrayValue {
            guard obj["type_code"] == "investigator" else { continue }
            
            if let hidden = obj["hidden"].bool, hidden {
                continue
            }
            
            var dict = [String: DatabaseValueConvertible?]()
            dict[RowKeys.id.rawValue] = Int(obj["code"].stringValue)
            dict[RowKeys.name.rawValue] = obj["name"].stringValue
            dict[RowKeys.position.rawValue] = obj["position"].intValue
            dict[RowKeys.subname.rawValue] = obj["subname"].stringValue
            dict[RowKeys.health.rawValue] = obj["health"].intValue
            dict[RowKeys.sanity.rawValue] = obj["sanity"].intValue
            
            guard let factionId = CardFaction(code: obj["faction_code"].stringValue)?.rawValue else {
                throw InvestigatorError.invalidFactionCode(obj["type_code"].stringValue)
            }
            
            dict[RowKeys.factionId.rawValue] = factionId

            dict[RowKeys.packId.rawValue] = obj["pack_code"].stringValue
            dict[RowKeys.frontText.rawValue] = obj["text"].stringValue
            dict[RowKeys.backText.rawValue] = obj["back_text"].string
            dict[RowKeys.agility.rawValue] = obj["skill_agility"].intValue
            dict[RowKeys.combat.rawValue] = obj["skill_combat"].intValue
            dict[RowKeys.intellect.rawValue] = obj["skill_intellect"].intValue
            dict[RowKeys.willpower.rawValue] = obj["skill_willpower"].intValue
            dict[RowKeys.traits.rawValue] = obj["traits"].stringValue
            dict[RowKeys.frontFlavor.rawValue] = obj["flavor"].stringValue
            dict[RowKeys.backFlavor.rawValue] = obj["back_flavor"].stringValue
            dict[RowKeys.illustrator.rawValue] = obj["illustrator"].stringValue
            
            let investigator = InvestigatorRecord(row: Row(dict))
            
            try investigator.insert(db)
        }
    }
    
    enum InvestigatorError: Error {
        case invalidFactionCode(String)
    }
    
    enum RowKeys: String {
        case id = "id"
        case name = "name"
        case position = "position"
        case subname = "subname"
        case health = "health"
        case sanity = "sanity"
        case factionId = "faction_id"
        case packId = "pack_id"
        case frontText = "front_text"
        case backText = "back_text"
        case agility = "agility"
        case combat = "combat"
        case intellect = "intellect"
        case willpower = "willpower"
        case traits = "traits"
        case frontFlavor = "front_flavor"
        case backFlavor = "back_flavor"
        case illustrator = "illustrator"
    }
}
