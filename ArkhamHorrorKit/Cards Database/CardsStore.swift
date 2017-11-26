//
//  CardsStoreV1.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 23/10/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation
import GRDB
import TBSwiftKit

public final class CardsStore {
    private let dbWriter: DatabaseWriter
    private let cardCycles: [String: CardCycle]
    private let cardPacks: [String: CardPack]
    public let investigators: [Int: Investigator]
    
    public private(set) var cardsCache = Cache<Int, Card>(maxItems: 50)
    
    public init(dbWriter: DatabaseWriter,
         cycles: [String: CardCycle],
         packs: [String: CardPack],
         investigators: [Int: Investigator]) {
        self.dbWriter = dbWriter
        self.cardCycles = cycles
        self.cardPacks = packs
        self.investigators = investigators
    }
    
    // MARK:- Public Interface
    public func fetchCard(id: Int) throws -> Card {
        return try dbWriter.read({ (db) -> Card in
            guard let record = try CardRecord.fetchOne(db: db, id: id) else {
                throw AHDatabaseError.cardNotFound(id)
            }
            
            guard let card = try makeCard(record: record) else {
                throw AHDatabaseError.couldNotMakeCardFromRecord(id)
            }
            
            return card
        })
    }
    
    public func fetchCards(filter: CardFilter?, sorting: [CardsSortingDescriptor]?) -> [Card] {
        guard let cards = try? dbWriter.read({ db -> [Card] in
            let joinClause = genJoinClause(filter)
            let whereClause = genWhereClause(filter)
            let sortByClause = genOrderByClause(sorting)
            
            let stmt = "SELECT * FROM Card \(joinClause) \(whereClause) \(sortByClause)"
            return try CardRecord.fetchAll(db, stmt).flatMap ({ (record) -> Card? in
                let card = try makeCard(record: record)
                
                return card
            })
        }) else {
            return [Card]()
        }
        
        return cards
    }
    
    public func fetchCards(filter: CardFilter?, sorting: [CardsSortingDescriptor]?, groupResults: Bool) -> DatabaseCardStoreFetchResult? {
        let cards = fetchCards(filter: filter, sorting: sorting)
                
        let result: DatabaseCardStoreFetchResult
        
        // Group results using the first sorting descriptor
        if let groupBy = sorting?.first, groupResults {
            let groupedCards = group(cards: cards, by: groupBy.column)
            
            let sectionNames = sectionsNames(cards: cards, using: groupBy.column)
            
            result = DatabaseCardStoreFetchResult(
                cards: groupedCards,
                sectionsNames: sectionNames)
        } else {
            result = DatabaseCardStoreFetchResult(cards: [cards], sectionsNames: [])
        }
        
        return result
    }
    
    private func makeCard(record: CardRecord) throws -> Card? {
        guard let faction = CardFaction(rawValue: record.factionId) else {
            throw AHDatabaseError.invalidCardFactionId(record.factionId)
        }
        
        guard let type = CardType(rawValue: record.typeId) else {
            throw AHDatabaseError.typeNotFound(record.typeId)
        }
        
        var subtype: CardSubtype?
        if let subtypeId = record.subtypeId {
            guard let sub = CardSubtype(rawValue: subtypeId) else {
                throw AHDatabaseError.subtypeNotFound(subtypeId)
            }
            subtype = sub
        }
        
        guard let pack = cardPacks[record.packId] else {
            throw AHDatabaseError.packNotFound(record.packId)
        }
        
        var assetSlot: CardAssetSlot?
        if let slotId = record.assetSlotId {
            guard let slot = CardAssetSlot(rawValue: slotId) else {
                throw AHDatabaseError.assetSlotNotFound(slotId)
            }
            
            assetSlot = slot
        }
        
        var investigator: Investigator?
        if let id = record.investigatorId {
            guard let inv = investigators[id] else {
                throw AHDatabaseError.investigatorNotFound(id)
            }
            
            investigator = inv
        }
        
        let card = cardsCache.getCachedValue(record.id, defaultValue: { () -> Card? in
            var backImageName: String?
            
            if record.doubleSided {
                backImageName = "\(record.internalCode)b.jpeg"
            }
            
            return Card(id: record.id,
                        name: record.name,
                        subname: record.subname,
                        cost: record.cost, level: record.level,
                        type: type, subtype: subtype,
                        faction: faction, text: record.text,
                        pack: pack, assetSlot: assetSlot,
                        position: record.position,
                        quantity: record.quantity,
                        deckLimit: record.deckLimit,
                        isUnique: record.isUnique,
                        skillAgility: record.skillAgility,
                        skillCombat: record.skillCombat,
                        skillIntellect: record.skillIntellect,
                        skillWillpower: record.skillWillpower,
                        skillWild: record.skillWild,
                        restrictedToInvestigator: investigator,
                        health: record.health,
                        sanity: record.sanity,
                        flavorText: record.flavorText,
                        traits: record.traits,
                        illustrator: record.illustrator,
                        doubleSided: record.doubleSided,
                        enemyFight: record.enemyFight,
                        enemyEvade: record.enemyEvade,
                        enemyHealth: record.enemyHealth,
                        enemyDamage: record.enemyDamage,
                        enemyHorror: record.enemyHorror,
                        enemyHealthPerInvestigator: record.enemyHealthPerInvestigator,
                        frontImageName: "\(record.internalCode).jpeg",
                        backImageName: backImageName)
        })
        
        return card
    }
    
    // MARK:- Private Interface
    private func genJoinClause(_ filter: CardFilter?) -> String {
        guard filter?.onlyDeck != nil else { return "" }
        
        return "INNER JOIN DeckCard ON DeckCard.card_id = Card.id"
    }
    
    private func genWhereClause(_ filter: CardFilter?) -> String {
        guard let filter = filter else { return "" }
        
        var whereInClauses: [String] = []
        
        if filter.hideRestrictedCards {
            whereInClauses.append("restricted = 0")
        }
        
        if !filter.cardIds.isEmpty {
            let ids = filter.cardIds
                .map{ String($0) }
                .joined(separator: ",")
            whereInClauses.append("id IN (\(ids))")
        }
        
        if !filter.factions.isEmpty {
            let ids = filter.factions
                .map{ String($0.id) }
                .joined(separator: ",")
            whereInClauses.append("faction_id IN (\(ids))")
        }
        
        if !filter.types.isEmpty {
            let ids = filter.types
                .map{ String($0.id) }
                .joined(separator: ",")
            whereInClauses.append("type_id IN (\(ids))")
        }
        
        if !filter.subtypes.isEmpty {
            let ids = filter.subtypes
                .map{ String($0.id) }
                .joined(separator: ",")
            whereInClauses.append("subtype_id IN (\(ids))")
        } else {
            whereInClauses.append("subtype_id IS NULL")
        }
        
        if !filter.packs.isEmpty {
            let ids = filter.packs
                .map{ String($0.id) }
                .joined(separator: ",")
            whereInClauses.append("pack_id IN (\(ids))")
        }
        
        if !filter.assetSlots.isEmpty {
            let ids = filter.assetSlots
                .map{ String($0.id) }
                .joined(separator: ",")
            whereInClauses.append("(asset_slot_id IN (\(ids)) OR asset_slot_id IS NULL)")
        }
        
        if !filter.levels.isEmpty {
            let numbers = filter.levels.map({ String($0) }).joined(separator: ", ")
            whereInClauses.append("level IN (\(numbers))")
        }
        
        if !filter.skillTestIcons.isEmpty {
            let notAllowed = Set<CardSkillTestIcon>(CardSkillTestIcon.allValues)
                .symmetricDifference(filter.skillTestIcons)
            
            let stmt = notAllowed.map({ icon -> String in
                switch icon {
                case .agility: return "skill_agility = 0"
                case .combat: return "skill_combat = 0"
                case .intellect: return "skill_intellect = 0"
                case .willpower: return "skill_willpower = 0"
                case .wild: return "skill_wild = 0"
                }
            }).joined(separator: " AND ")
            
            if !stmt.isEmpty {
                whereInClauses.append("(\(stmt))")
            }
        }
        
        if let deckOptions = filter.investigatorOnly?.deckOptions {
            var subClauses: [String] = []
            
            for case let option as DeckOptionAllowedFactions in deckOptions {
                let ids = option.factions.map({ String($0.id) }).joined(separator: ",")
                let levels = option.levels.map({ String($0) }).joined(separator: ", ")
                
                subClauses.append("(faction_id IN (\(ids)) AND level IN (\(levels)))")
            }
            
            if !subClauses.isEmpty {
                let subClause = subClauses.joined(separator: " OR ")
                
                whereInClauses.append("(\(subClause))")
            }
        }
        
        if let deck = filter.onlyDeck {
            whereInClauses.append("DeckCard.deck_id = \(deck.id)")
        }
        
        func removeAllNonAlphanumericCharacters(_ s: String) -> String {
            let whitelist = CharacterSet.alphanumerics
                .union(CharacterSet.whitespaces)
                .union(CharacterSet(charactersIn: "_"))
            
            let filtered = s.characters.filter({ (c) -> Bool in
                return String(c).rangeOfCharacter(from: whitelist) != nil
            })
            
            return String(filtered)
        }
        
        if let match = filter.fullTextSearchMatch {
            let filteredMatch = removeAllNonAlphanumericCharacters(match)
            
            if !filteredMatch.characters.isEmpty {
                whereInClauses.append("id IN (SELECT id FROM CardFTS WHERE CardFTS MATCH \"\(filteredMatch)*\" ORDER BY bm25(CardFTS, 11, 10, 9, 8, 7, 6, 5, 2))")
            }
        }
        
        if !whereInClauses.isEmpty {
            return "WHERE " + whereInClauses.joined(separator: " AND ")
        } else {
            return ""
        }
    }
    
    private func genOrderByClause(_ descriptors: [CardsSortingDescriptor]?) -> String {
        guard let descriptors = descriptors, !descriptors.isEmpty else {
            return ""
        }
        
        func orderStmt(_ descriptor: CardsSortingDescriptor) -> String {
            switch descriptor.column {
            case .name: return "name \(descriptor.ascending ? "ASC" : "DESC")"
            case .faction: return "faction_id \(descriptor.ascending ? "ASC" : "DESC")"
            case .pack: return "pack_id \(descriptor.ascending ? "ASC" : "DESC")"
            case .type: return "type_id \(descriptor.ascending ? "ASC" : "DESC")"
            case .level: return "level \(descriptor.ascending ? "ASC" : "DESC")"
            case .assetSlot: return "asset_slot_id IS NULL, asset_slot_id \(descriptor.ascending ? "ASC" : "DESC")"
            }
        }
        
        return "ORDER BY " + descriptors
            .map({ orderStmt($0) })
            .joined(separator: ", ")
    }
    
    private func isCard(_ a: Card, equalTo b: Card, column: CardsSortingDescriptor.CardColumn) -> Bool {
        switch column {
        case .name: return getSectionName(forCardName: a.name) == getSectionName(forCardName: b.name)
        case .faction: return a.faction.id == b.faction.id
        case .pack: return a.pack.id == b.pack.id
        case .type: return a.type.id == b.type.id
        case .level: return a.level == b.level
        case .assetSlot: return a.assetSlot == b.assetSlot
        }
    }
    
    private func getSectionName(forCardName name: String) -> String {
        guard let firstChar = name.unicodeScalars.first else { return "Other" }
        
        return CharacterSet.letters.contains(firstChar) ? "\(firstChar)" : "#"
    }
    
    private func sectionsNames(cards: [Card], using column: CardsSortingDescriptor.CardColumn) -> [String] {
        guard !cards.isEmpty else { return [] }
        
        var names: [String] = []
        
        let kNotAnAsset: String = "Not an Asset"
        
        for card in cards {
            var name: String!
            
            switch column {
            case .name: name = getSectionName(forCardName: card.name)
            case .faction: name = card.faction.name
            //            case .id: name = String(card.id)
            case .pack: name = card.pack.name
            case .type: name = card.type.name
            case .level: name = "Level: \(card.level)"
            case .assetSlot:
                if let assetSlot = card.assetSlot {
                    name = assetSlot.name
                } else {
                    name = kNotAnAsset
                }
            }
            
            if names.isEmpty {
                names.append(name)
            } else if let last = names.last, last != name {
                names.append(name)
            }
        }
        
        return names
    }
    
    private func group(cards: [Card], by column: CardsSortingDescriptor.CardColumn) -> [[Card]] {
        guard !cards.isEmpty else { return [[]] }
        
        var groups: [[Card]] = []
        
        var lastCard: Card? = nil
        
        var group: [Card] = []
        
        for card in cards {
            if lastCard == nil {
                group.append(card)
            } else if isCard(card, equalTo: lastCard!, column: column) {
                group.append(card)
            } else {
                groups.append(group)
                group = [card]
            }
            
            lastCard = card
        }
        
        if !group.isEmpty {
            groups.append(group)
        }
        
        return groups
    }
}

public struct DatabaseCardStoreFetchResult: CardStoreFetchResult {
    public var cards: [[Card]]
    public var sectionsNames: [String]
    
    public var numberOfSections: Int {
        return cards.count
    }
    
    public func numberOfCards(inSection section: Int) -> Int {
        return cards[section].count
    }
    
    public func sectionName(_ section: Int) -> String? {
        guard section < sectionsNames.count else { return nil }
        
        return sectionsNames[section]
    }
    
    public func card(_ indexPath: IndexPath) -> Card? {
        #if os(iOS) || os(watchOS) || os(tvOS)
            let row = indexPath.row
        #elseif os(OSX)
            let row = indexPath.item
        #endif
        
        guard indexPath.section < numberOfSections, row < numberOfCards(inSection: indexPath.section) else {
            return nil
        }
        
        return cards[indexPath.section][row]
    }
}

