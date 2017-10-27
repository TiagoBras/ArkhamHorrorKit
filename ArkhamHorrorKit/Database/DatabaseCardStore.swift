//
//  DatabaseCardStore.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 23/05/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation
import GRDB

struct DatabaseCardStoreFetchResult: CardStoreFetchResult {
    var cards: [[Card]]
    var sectionsNames: [String]
    
    var numberOfSections: Int {
        return cards.count 
    }
    
    func numberOfCards(inSection section: Int) -> Int {
        return cards[section].count
    }
    
    func sectionName(_ section: Int) -> String? {
        guard section < sectionsNames.count else { return nil }
        
        return sectionsNames[section]
    }
    
    func card(_ indexPath: IndexPath) -> Card? {
        guard indexPath.section < numberOfSections, indexPath.row < numberOfCards(inSection: indexPath.section) else {
            return nil
        }
        
        return cards[indexPath.section][indexPath.row]
    }
}

class DatabaseCardStore: CardStore_toDelete {
    private var db: DatabasePool
    private(set) var investigators: [Investigator]?
    
    init(database: DatabasePool) throws {
        self.db = database
        
        try database.read { (db) -> () in
            investigators = try InvestigatorRecord.fetchAll(db).flatMap({ (record) -> Investigator? in
                return Investigator.makeInvestigator(record: record, db: db)
            })
        }
    }
    
    func fetchCards(filter: CardFilter?, sorting: [CardsSortingDescriptor]?, groupResults: Bool, completion: @escaping (CardStoreFetchResult?, Error?) -> ()) {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            do {
                guard let strongSelf = self else { return }
                
                let joinClause = strongSelf.genJoinClause(filter)
                let whereClause = strongSelf.genWhereClause(filter)
                let sortByClause = strongSelf.genOrderByClause(sorting)
                
                try strongSelf.db.read { db in
                    let stmt = "SELECT * FROM Card \(joinClause) \(whereClause) \(sortByClause)"
                    let cards = try CardRecord.fetchAll(db, stmt).flatMap ({ (record) -> Card? in
                        return Card.makeCard(record: record, db: db)
                    })
                    
                    print(stmt)
                    
                    var result: DatabaseCardStoreFetchResult!
                    
                    // Group results using the first sorting descriptor
                    if let groupBy = sorting?.first, groupResults {
                        let groupedCards = strongSelf.group(cards: cards, by: groupBy.column)
                        
                        let sectionNames = strongSelf.sectionsNames(cards: cards, using: groupBy.column)
                        
                        result = DatabaseCardStoreFetchResult(
                            cards: groupedCards,
                            sectionsNames: sectionNames)
                    } else {
                        result = DatabaseCardStoreFetchResult(cards: [cards], sectionsNames: [])
                    }
                    
                    DispatchQueue.main.async {
                        completion(result, nil)
                    }
                }
            } catch let error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }
    
    enum CardStoreError: Error {
        case cardNotFound(Int)
    }
    
    private func genJoinClause(_ filter: CardFilter?) -> String {
        guard filter?.onlyDeck != nil else { return "" }
        
        return "INNER JOIN DeckCard ON DeckCard.card_id = CardExtendedView.id"
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
//        case .id: return a.id == b.id
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
    
    // TODO: remove X.makeX from all classes create methods in CardsDatabase so the results can be cached
    func fetchCard(id: Int, completion: @escaping (Card?, Error?) -> ()) {
//        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
//            do {
//                try self?.db.read { db in
//                    if let record = try CardRecord.fetchOne(db: db, id: id) {
//                        let card = Card.makeCard(record: record, db: db)
//                        
//                        DispatchQueue.main.async {
//                            completion(card, nil)
//                        }
//                    }
//                    
//                    throw CardStoreError.cardNotFound(id)
//                }
//            } catch let error {
//                DispatchQueue.main.async {
//                    completion(nil, error)
//                }
//            }
//        }
    }
}


