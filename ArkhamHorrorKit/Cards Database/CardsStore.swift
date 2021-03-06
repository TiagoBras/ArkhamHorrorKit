//  Copyright © 2017 Tiago Bras. All rights reserved.

import Foundation
import GRDB
import TBSwiftKit

public final class CardsStore {
    var dbWriter: DatabaseWriter
    var cardCycles: [String: CardCycle]
    var cardPacks: [String: CardPack]
    var traits: Set<String>
    var dbVersion: AHDatabaseMigrator.MigrationVersion
    public internal(set) var investigators: [Int: Investigator]
    
    public private(set) var cardsCache = Cache<Int, Card>(maxItems: 50)
    
    public init(dbWriter: DatabaseWriter,
                cycles: [String: CardCycle],
                packs: [String: CardPack],
                traits: Set<String>,
                investigators: [Int: Investigator],
                dbVersion: AHDatabaseMigrator.MigrationVersion) {
        self.dbWriter = dbWriter
        self.cardCycles = cycles
        self.cardPacks = packs
        self.traits = traits
        self.investigators = investigators
        self.dbVersion = dbVersion
    }
    
    var RightCardRecord: CardRecord.Type {
        if dbVersion >= .v2 {
            return CardRecordV2.self
        } else {
            return CardRecord.self
        }
    }
    
    // MARK:- Public Interface
    public func fetchCard(id: Int) throws -> Card {
        return try dbWriter.read({ (db) -> Card in
            guard let record = try RightCardRecord.fetchCard(db: db, id: id) else {
                throw AHDatabaseError.cardNotFound(id)
            }
            
            let traits = try CardTraitRecord.fetchCardTraits(db: db, cardId: id)
                .map({ $0.traitName })
            
            guard let card = try makeCard(record: record, traits: traits) else {
                throw AHDatabaseError.couldNotMakeCardFromRecord(id)
            }
            
            return card
        })
    }
    
    public func fetchCard(id: Int, completion: @escaping (Card?, Error?) -> ()) throws {
        DispatchQueue.global().async { [weak self] in
            do {
                if let output = try self?.fetchCard(id: id) {
                    DispatchQueue.main.async {
                        completion(output, nil)
                    }
                }
            } catch {
                completion(nil, error)
            }
        }
    }
    
    public var onBeforeFetch: ((String) -> ())?
    public func fetchCards(filter: CardFilter?, sorting: [CardsSortingDescriptor]?) -> [Card] {
        guard let cards = try? dbWriter.read({ db -> [Card] in
            let joinClause = genJoinClause(filter)
            let whereClause = genWhereClause(filter)
            let sortByClause = genOrderByClause(sorting)
            
            let stmt = "SELECT DISTINCT * FROM Card \(joinClause) WHERE \(whereClause) GROUP BY Card.id ORDER BY \(sortByClause)"
            
            onBeforeFetch?(stmt)
            
            
            return try RightCardRecord.fetchCards(db: db, sql: stmt).compactMap ({ (record) -> Card? in
                let traits = try CardTraitRecord.fetchCardTraits(
                    db: db,
                    cardId: record.id).map({ $0.traitName })
                
                let card = try makeCard(record: record, traits: traits)
                
                return card
            })
        }) else {
            return [Card]()
        }
        
        return cards
    }
    
    public func fetchCards(filter: CardFilter?,
                           sorting: [CardsSortingDescriptor]?,
                           completion: @escaping ([Card]) -> ()) {
        DispatchQueue.global().async { [weak self] in
            if let cards = self?.fetchCards(filter: filter, sorting: sorting) {
                DispatchQueue.main.async {
                    completion(cards)
                }
            }
        }
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
    
    public func fetchCards(filter: CardFilter?,
                           sorting: [CardsSortingDescriptor]?,
                           groupResults: Bool,
                           completion: @escaping (DatabaseCardStoreFetchResult?) -> ()) {
        DispatchQueue.global().async { [weak self] in
            if let result = self?.fetchCards(filter: filter, sorting: sorting, groupResults: groupResults) {
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }
    }
    
    private func updateFavoriteCardStatus(_ card: Card, isFavorite: Bool) {
        
    }
    
    private func updateCardStar(_ card: Card, starred: Bool, completion: ((Card?, Error?) -> ())?) {
        // TODO: complete this
//        DispatchQueue.global().async { [weak self] in
//
//        }
        print("!!!!!!!!!!!!!!! NOT IMPLEMENTED !!!!!!!!!!!!!!!")
    }
    
    public func starCard(_ card: Card, completion: ((Card?, Error?) -> ())?) {
        updateCardStar(card, starred: true, completion: completion)
    }
    
    public func unstarCard(_ card: Card, completion: ((Card?, Error?) -> ())?) {
        updateCardStar(card, starred: false, completion: completion)
    }
    
    class func makeCard(record: CardRecord,
                        pack: CardPack,
                        traits: [String] = [],
                        investigator: Investigator? = nil,
                        cardsCache: Cache<Int, Card>?) throws -> Card? {
        guard let faction = CardFaction(rawValue: record.factionId) else {
            throw AHDatabaseError.invalidCardFactionId(record.factionId)
        }
        
        guard let cardType = CardType(rawValue: record.typeId) else {
            throw AHDatabaseError.typeNotFound(record.typeId)
        }
        
        var subtype: CardSubtype?
        if let subtypeId = record.subtypeId {
            guard let sub = CardSubtype(rawValue: subtypeId) else {
                throw AHDatabaseError.subtypeNotFound(subtypeId)
            }
            subtype = sub
        }
        
        var assetSlot: CardAssetSlot?
        if let slotId = record.assetSlotId {
            guard let slot = CardAssetSlot(rawValue: slotId) else {
                throw AHDatabaseError.assetSlotNotFound(slotId)
            }
            
            assetSlot = slot
        }
        
        let getCard = { () -> Card? in
            var backImageName: String?
            
            if record.doubleSided {
                backImageName = "\(record.internalCode)b.jpeg"
            }
            
            var isPermanent: Bool = false
            var isEarnable: Bool = false
            
            if let recordV2 = record as? CardRecordV2 {
                isPermanent = recordV2.isPermanent
                isEarnable = recordV2.isEarnable
            }
            
            return Card(id: record.id,
                        name: record.name,
                        subname: record.subname,
                        cost: record.cost, level: record.level,
                        type: cardType, subtype: subtype,
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
                        traits: traits,
                        illustrator: record.illustrator,
                        doubleSided: record.doubleSided,
                        enemyFight: record.enemyFight,
                        enemyEvade: record.enemyEvade,
                        enemyHealth: record.enemyHealth,
                        enemyDamage: record.enemyDamage,
                        enemyHorror: record.enemyHorror,
                        enemyHealthPerInvestigator: record.enemyHealthPerInvestigator,
                        frontImageName: "\(record.internalCode).jpeg",
                        backImageName: backImageName,
                        isFavorite: record.isFavorite,
                        isPermanent: isPermanent,
                        isEarnable: isEarnable)
        }
        
        if let cache = cardsCache {
            return cache.get(record.id, defaultValue: getCard)
        } else {
            return getCard()
        }
    }
    
    private func makeCard(record: CardRecord, traits: [String] = []) throws -> Card? {
        guard let pack = cardPacks[record.packId] else {
            throw AHDatabaseError.packNotFound(record.packId)
        }
        
        var investigator: Investigator?
        if let id = record.investigatorId {
            guard let inv = investigators[id] else {
                throw AHDatabaseError.investigatorNotFound(id)
            }
            
            investigator = inv
        }
        
        return try CardsStore.makeCard(record: record,
                                       pack: pack,
                                       traits: traits,
                                       investigator: investigator,
                                       cardsCache: self.cardsCache)
    }
    
    // MARK:- Private Interface
    private func genJoinClause(_ filter: CardFilter?) -> String {
        guard let filter = filter else { return "" }
        var clause = [String]()
        
        if filter.usesDeckId() {
            clause.append("INNER JOIN DeckCard ON DeckCard.card_id = Card.id")
        }
        
        return clause.isEmpty ? "" : clause.joined(separator: " ")
    }
    
    private func genWhereClause(_ filter: CardFilter?) -> String {
        guard let filter = filter else { return "1" }
        
        var whereInClauses: [String] = []
        
        if let hide = filter.hideRestrictedCards, hide {
            whereInClauses.append("investigator_id IS NULL")
        }
        
        if let hideWeaknesses = filter.hideWeaknesses, hideWeaknesses {
            whereInClauses.append("subtype_id IS NULL")
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
        }
        
        if !filter.packs.isEmpty {
            let ids = filter.packs
                .map{ "'\(String($0.id))'" }
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
        
        if !filter.traits.isEmpty {
            var traits = filter.traits.map({ "'\($0)'" }).joined(separator: ", ")
            
            whereInClauses.append("(Card.id IN (SELECT card_id FROM CardTrait WHERE trait_name IN (\(traits))))")
        }
        
        if !filter.prohibitedTraits.isEmpty {
            var traits = filter.prohibitedTraits.map({ "'\($0)'" }).joined(separator: ", ")
            
            whereInClauses.append("(Card.id NOT IN (SELECT card_id FROM CardTrait WHERE trait_name IN (\(traits))))")
        }
        
        if let usesCharges = filter.usesCharges {
            whereInClauses.append("uses_charges = \(usesCharges ? 1 : 0)")
        }
        
        if let investigatorId = filter.investigatorId {
            whereInClauses.append("investigator_id = \(investigatorId)")
        }
        
        if let deckId = filter.deckId {
            whereInClauses.append("DeckCard.deck_id = \(deckId)")
        }
        
        func removeAllNonAlphanumericCharacters(_ s: String) -> String {
            let whitelist = CharacterSet.alphanumerics
                .union(CharacterSet.whitespaces)
                .union(CharacterSet(charactersIn: "_:"))
            
            let filtered = s.filter({ (c) -> Bool in
                return String(c).rangeOfCharacter(from: whitelist) != nil
            })
            
            return String(filtered)
        }
        
        if let match = filter.fullTextSearchMatch {
            let filteredMatch = removeAllNonAlphanumericCharacters(match)
            
            if !filteredMatch.isEmpty {
                whereInClauses.append("id IN (SELECT id FROM CardFTS WHERE CardFTS MATCH \"\(filteredMatch)*\")")
            }
        }
        
        if let isFavorite = filter.onlyFavorites {
            let favorite: Int = isFavorite ? 1 : 0
            
            whereInClauses.append("favorite = \(favorite)")
        }

        if dbVersion >= .v2 {
            if let onlyPermanentCards = filter.onlyPermanentCards {
                let intValue: Int = onlyPermanentCards ? 1 : 0
                
                whereInClauses.append("\(CardRecord.RowKeys.isPermanent.rawValue) = \(intValue)")
            }
            
            if let onlyEarnedCards = filter.onlyEarnedCards {
                let intValue: Int = onlyEarnedCards ? 1 : 0
                
                whereInClauses.append("\(CardRecord.RowKeys.isEarnable.rawValue) = \(intValue)")
            }
        }

        var s = ""
        if !whereInClauses.isEmpty {
            s = "(\(whereInClauses.joined(separator: " AND ")))"
        } else {
            s = "1"
        }
        
        for subfilter in filter.subfilters {
            s = "\(s) \(subfilter.op.rawValue) (\(genWhereClause(subfilter.filter)))"
        }

        return s
    }
    
    private func genOrderByClause(_ descriptors: [CardsSortingDescriptor]?) -> String {
        guard let descriptors = descriptors, !descriptors.isEmpty else {
            return "id ASC"
        }
        
        func orderStmt(_ descriptor: CardsSortingDescriptor) -> String {
            let mod: String = descriptor.ascending ? "ASC" : "DESC"
            
            switch descriptor.column {
            case .name: return "name \(mod)"
            case .faction: return "faction_id \(mod)"
            case .pack: return "pack_id \(mod)"
            case .type: return "type_id \(mod)"
            case .level: return "level \(mod)"
            case .assetSlot: return "asset_slot_id IS NULL, asset_slot_id \(mod)"
            case .favoriteStatus: return "favorite \(mod)"
            }
        }
        
        return descriptors
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
        case .favoriteStatus: return a.isFavorite == b.isFavorite
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
            case .favoriteStatus: name = "Favorites"
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

