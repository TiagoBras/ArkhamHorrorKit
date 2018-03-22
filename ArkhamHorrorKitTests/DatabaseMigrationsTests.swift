//
//  DatabaseBaseValuesTests.swift
//  ArkhamHorrorCompanionTests
//
//  Created by Tiago Bras on 21/10/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import XCTest

@testable import ArkhamHorrorKit

import GRDB
import SwiftyJSON

class DatabaseMigrationsTests: XCTestCase {
    #if os(iOS) || os(watchOS) || os(tvOS)
    let bundle = Bundle(identifier: "com.bitmountains.ArkhamHorrorKit-iOS")!
    #elseif os(OSX)
    let bundle = Bundle(identifier: "com.bitmountains.ArkhamHorrorKit-macOS")!
    #endif
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCyclesBaseValues() {
        let version = AHDatabaseMigrator.MigrationVersion.v1
        
        try! DatabaseTestsHelper.inReadOnly(dbVersion: version, { (db) in
            XCTAssertEqual(try CardCycleRecord.fetchCount(db), 5)
            
            let cycles = loadJSONInMainBundle(filename: "cycles.json").arrayValue
            
            XCTAssertEqual(cycles.count, 5)

            XCTAssertEqual(cycles[1]["code"].stringValue, "dwl")
            XCTAssertEqual(cycles[1]["name"].stringValue, "The Dunwich Legacy")
            XCTAssertEqual(cycles[1]["position"].intValue, 2)
            XCTAssertEqual(cycles[1]["size"].intValue, 7)
        })
    }
    
    func testPacksBaseValues() {
        let version = AHDatabaseMigrator.MigrationVersion.v1
        
        try! DatabaseTestsHelper.inReadOnly(dbVersion: version, { (db) in
            XCTAssertEqual(try CardPackRecord.fetchCount(db), 19)
            
            let packs = loadJSONInMainBundle(filename: "packs.json").arrayValue
            
            XCTAssertEqual(packs.count, 19)
            
            XCTAssertEqual(packs[4]["code"].stringValue, "bota")
            XCTAssertEqual(packs[4]["cycle_code"].stringValue, "dwl")
            XCTAssertEqual(packs[4]["name"].stringValue, "Blood on the Altar")
            XCTAssertEqual(packs[4]["position"].intValue, 4)
            XCTAssertEqual(packs[4]["size"].intValue, 41)
        })
    }
    
    func testInvestigatorsBaseValues() {
        let version = AHDatabaseMigrator.MigrationVersion.v1
        
        try! DatabaseTestsHelper.inReadOnly(dbVersion: version, { (db) in
            let core = loadInvestigatorsJSONInMainBundle(filename: "core.json")
            
            XCTAssertEqual(core.count, 5)
            
            let dwl = loadInvestigatorsJSONInMainBundle(filename: "dwl.json")
            
            XCTAssertEqual(dwl.count, 5)
            
            let ptc = loadInvestigatorsJSONInMainBundle(filename: "ptc.json")
            
            XCTAssertEqual(ptc.count, 6)
            
            let promo = loadInvestigatorsJSONInMainBundle(filename: "promo.json")
            
            XCTAssertEqual(promo.count, 1)
            
            XCTAssertEqual(try InvestigatorRecord.fetchCount(db), 17)
            
            let investigator = try InvestigatorRecord.fetchOne(db: db, id: 3004)!
            
            XCTAssertEqual(investigator.id, 3004)
            XCTAssertEqual(investigator.name, "Akachi Onyele")
            XCTAssertEqual(investigator.position, 4)
            XCTAssertEqual(investigator.subname, "The Shaman")
            XCTAssertEqual(investigator.health, 6)
            XCTAssertEqual(investigator.sanity, 8)
            XCTAssertEqual(investigator.factionId, CardFaction.mystic.id)
            XCTAssertEqual(investigator.packId, "ptc")
            XCTAssertEqual(investigator.frontText, "Your assets with \"uses (charges)\" enter play with 1 additional charge on them.\n[elder_sign] effect: +1. Add 1 charge to an asset with \"uses (charges)\" you control.")
            XCTAssertEqual(investigator.backText, "<b>Deck size</b>: 30.\n<b>Deckbuilding Options</b>: Mystic cards ([mystic]) level 0-5, Neutral cards level 0-5, cards with \"uses (charges)\" level 0-4, <i>Occult</i> cards level 0.\n<b>Deckbuilding Requirements</b> (do not count toward deck size): Spirit-Speaker, Angered Spirits, 1 random basic weakness.")
            XCTAssertEqual(investigator.agility, 3)
            XCTAssertEqual(investigator.combat, 3)
            XCTAssertEqual(investigator.intellect, 2)
            XCTAssertEqual(investigator.willpower, 5)
            XCTAssertEqual(investigator.traits, "Sorcerer.")
            XCTAssertEqual(investigator.frontFlavor, "\"I will journey to the lands beyond. I do not fear them.\"")
            XCTAssertEqual(investigator.backFlavor, "As a young girl in Nigeria, Akachi became used to being set apart. Her habits of chattering away at thin air and secluding herself from other children led her village to believe she was mad. Her village Dibia was the first to see her true potential. He believed Akachi was marked by the spirits for greatness, and he taught her how to commune with them to her advantage. Under his tutelage, Akachi grew into a wise young leader, respected not just in her village, but in every community she aided. Now she meets her destiny head on, seeking out unnatural troubles that only her knowledge can stop.")
            XCTAssertEqual(investigator.illustrator, "Magali Villeneuve")
        })
    }
    
    func testCardsBaseValues() {
        let version = AHDatabaseMigrator.MigrationVersion.v1
        
        try! DatabaseTestsHelper.inReadOnly(dbVersion: version, { (db) in
            let bota = loadCardsJSONInMainBundle(filename: "bota.json")
            XCTAssertEqual(bota.count, 11)
            
            let core = loadCardsJSONInMainBundle(filename: "core.json")
            XCTAssertEqual(core.count, 98)
            
            let dwl = loadCardsJSONInMainBundle(filename: "dwl.json")
            XCTAssertEqual(dwl.count, 34)
            
            let eotp = loadCardsJSONInMainBundle(filename: "eotp.json")
            XCTAssertEqual(eotp.count, 14)
            
            let litas = loadCardsJSONInMainBundle(filename: "litas.json")
            XCTAssertEqual(litas.count, 12)
            
            let promo = loadCardsJSONInMainBundle(filename: "promo.json")
            XCTAssertEqual(promo.count, 2)
            
            let ptc = loadCardsJSONInMainBundle(filename: "ptc.json")
            XCTAssertEqual(ptc.count, 36)
            
            let tece = loadCardsJSONInMainBundle(filename: "tece.json")
            XCTAssertEqual(tece.count, 12)
            
            let tmm = loadCardsJSONInMainBundle(filename: "tmm.json")
            XCTAssertEqual(tmm.count, 13)
            
            let tuo = loadCardsJSONInMainBundle(filename: "tuo.json")
            XCTAssertEqual(tuo.count, 12)
            
            let uau = loadCardsJSONInMainBundle(filename: "uau.json")
            XCTAssertEqual(uau.count, 11)
            
            let wda = loadCardsJSONInMainBundle(filename: "wda.json")
            XCTAssertEqual(wda.count, 14)
            
            XCTAssertEqual(try CardRecord.fetchCount(db), 269)
            
            let card1 = try CardRecord.fetchOne(db: db, id: 2027)!
            
            XCTAssertEqual(card1.id, 2027)
            XCTAssertEqual(card1.position, 27)
            XCTAssertEqual(card1.level, 1)
            XCTAssertEqual(card1.cost, 1)
            XCTAssertEqual(card1.quantity, 2)
            XCTAssertEqual(card1.deckLimit, 2)
            XCTAssertEqual(card1.name, "Hired Muscle")
            XCTAssertEqual(card1.subname, "")
            XCTAssertEqual(card1.isUnique, false)
            XCTAssertEqual(card1.text, "You get +1 [combat].\n<b>Forced</b> – At the end of the upkeep phase: You must either pay 1 resource or discard Hired Muscle.")
            XCTAssertEqual(card1.typeId, CardType.asset.id)
            XCTAssertEqual(card1.subtypeId, nil)
            XCTAssertEqual(card1.factionId, CardFaction.rogue.id)
            XCTAssertEqual(card1.packId, "dwl")
            XCTAssertEqual(card1.assetSlotId, CardAssetSlot.ally.id)
            XCTAssertEqual(card1.traits, "Ally. Criminal.")
            XCTAssertEqual(card1.skillAgility, 0)
            XCTAssertEqual(card1.skillCombat, 1)
            XCTAssertEqual(card1.skillIntellect, 0)
            XCTAssertEqual(card1.skillWillpower, 0)
            XCTAssertEqual(card1.skillWild, 0)
            XCTAssertEqual(card1.health, 3)
            XCTAssertEqual(card1.sanity, 1)
            XCTAssertEqual(card1.investigatorId, nil)
            XCTAssertEqual(card1.flavorText, "")
            XCTAssertEqual(card1.illustrator, "Mike Capprotti")
            XCTAssertEqual(card1.doubleSided, false)
            XCTAssertEqual(card1.enemyFight, 0)
            XCTAssertEqual(card1.enemyEvade, 0)
            XCTAssertEqual(card1.enemyHealth, 0)
            XCTAssertEqual(card1.enemyDamage, 0)
            XCTAssertEqual(card1.enemyHorror, 0)
            XCTAssertEqual(card1.enemyHealthPerInvestigator, false)
            XCTAssertEqual(card1.internalCode, "02027")
            
            let card2 = try CardRecord.fetchOne(db: db, id: 3012)!
            
            XCTAssertEqual(card2.id, 3012)
            XCTAssertEqual(card2.position, 12)
            XCTAssertEqual(card2.level, 0)
            XCTAssertEqual(card2.cost, 0)
            XCTAssertEqual(card2.quantity, 3)
            XCTAssertEqual(card2.deckLimit, 3)
            XCTAssertEqual(card2.name, "The Painted World")
            XCTAssertEqual(card2.subname, "")
            XCTAssertEqual(card2.isUnique, false)
            XCTAssertEqual(card2.text, "Sefina Rousseau deck only.\nCannot be placed beneath Sefina Rousseau.\nPlay The Painted World as an exact copy of a non-exceptional event that is beneath Sefina Rousseau. Remove The Painted World from the game instead of discarding it.")
            XCTAssertEqual(card2.typeId, CardType.event.id)
            XCTAssertEqual(card2.subtypeId, nil)
            XCTAssertEqual(card2.factionId, CardFaction.neutral.id)
            XCTAssertEqual(card2.packId, "ptc")
            XCTAssertEqual(card2.assetSlotId, nil)
            XCTAssertEqual(card2.traits, "Spell.")
            XCTAssertEqual(card2.skillAgility, 1)
            XCTAssertEqual(card2.skillCombat, 0)
            XCTAssertEqual(card2.skillIntellect, 0)
            XCTAssertEqual(card2.skillWillpower, 1)
            XCTAssertEqual(card2.skillWild, 1)
            XCTAssertEqual(card2.health, 0)
            XCTAssertEqual(card2.sanity, 0)
            XCTAssertEqual(card2.investigatorId, 3003)
            XCTAssertEqual(card2.flavorText, "")
            XCTAssertEqual(card2.illustrator, "Andreia Ugrai")
            XCTAssertEqual(card2.doubleSided, false)
            XCTAssertEqual(card2.enemyFight, 0)
            XCTAssertEqual(card2.enemyEvade, 0)
            XCTAssertEqual(card2.enemyHealth, 0)
            XCTAssertEqual(card2.enemyDamage, 0)
            XCTAssertEqual(card2.enemyHorror, 0)
            XCTAssertEqual(card2.enemyHealthPerInvestigator, false)
            XCTAssertEqual(card2.internalCode, "03012")
            
            let card3 = try CardRecord.fetchOne(db: db, id: 3017)!
            
            XCTAssertEqual(card3.id, 3017)
            XCTAssertEqual(card3.position, 17)
            XCTAssertEqual(card3.level, 0)
            XCTAssertEqual(card3.cost, 0)
            XCTAssertEqual(card3.quantity, 1)
            XCTAssertEqual(card3.deckLimit, 1)
            XCTAssertEqual(card3.name, "Graveyard Ghouls")
            XCTAssertEqual(card3.subname, "")
            XCTAssertEqual(card3.isUnique, false)
            XCTAssertEqual(card3.text, "<b>Prey</b> - William Yorick only.\nHunter.\nWhile Graveyard Ghouls is engaged with you, cards cannot leave your discard pile.")
            XCTAssertEqual(card3.typeId, CardType.enemy.id)
            XCTAssertEqual(card3.subtypeId, CardSubtype.weakness.id)
            XCTAssertEqual(card3.factionId, CardFaction.neutral.id)
            XCTAssertEqual(card3.packId, "ptc")
            XCTAssertEqual(card3.assetSlotId, nil)
            XCTAssertEqual(card3.traits, "Humanoid. Monster. Ghoul.")
            XCTAssertEqual(card3.skillAgility, 0)
            XCTAssertEqual(card3.skillCombat, 0)
            XCTAssertEqual(card3.skillIntellect, 0)
            XCTAssertEqual(card3.skillWillpower, 0)
            XCTAssertEqual(card3.skillWild, 0)
            XCTAssertEqual(card3.health, 0)
            XCTAssertEqual(card3.sanity, 0)
            XCTAssertEqual(card3.investigatorId, 3005)
            XCTAssertEqual(card3.flavorText, "\"Hell is empty and all the devils are here.\"\n - William Shakespeare, The Tempest")
            XCTAssertEqual(card3.illustrator, "Mike Capprotti")
            XCTAssertEqual(card3.doubleSided, false)
            XCTAssertEqual(card3.enemyFight, 3)
            XCTAssertEqual(card3.enemyEvade, 2)
            XCTAssertEqual(card3.enemyHealth, 3)
            XCTAssertEqual(card3.enemyDamage, 1)
            XCTAssertEqual(card3.enemyHorror, 1)
            XCTAssertEqual(card3.enemyHealthPerInvestigator, false)
            XCTAssertEqual(card3.internalCode, "03017")
        })
    }
    
    func testMigrationValuesV2() {
        let db = try! AHDatabase()
        var card = DatabaseTestsHelper.fetchCard(id: 2185, in: db)
        XCTAssertEqual(card.isPermanent, true)
        
        try! db.deleteAllSavedFileChecksums()
        
        let botaURL = Bundle(for: AHDatabase.self).url(forResource: "bota", withExtension: "json")!
        try! db.loadCardsAndInvestigatorsFromJSON(at: botaURL)
        
        card = DatabaseTestsHelper.fetchCard(id: 2185, in: db)
        XCTAssertEqual(card.isPermanent, true)
    }

    
    private func loadJSONInMainBundle(filename: String) -> JSON {
        let components = filename.components(separatedBy: ".")
        
        let url = bundle.url(forResource: components[0], withExtension: components[1])
        
        let data = try! Data(contentsOf: url!)
        
        return JSON(data: data)
    }
    
    private func loadInvestigatorsJSONInMainBundle(filename: String) -> [JSON] {
        return loadJSONInMainBundle(filename: filename).arrayValue.filter {
            $0["type_code"] == "investigator"
        }
    }
    
    private func loadCardsJSONInMainBundle(filename: String) -> [JSON] {
        return loadJSONInMainBundle(filename: filename).arrayValue.filter {
            $0["type_code"] != "investigator" && !$0["hidden"].boolValue
        }
    }
}
