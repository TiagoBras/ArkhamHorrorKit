//  Copyright © 2017 Tiago Bras. All rights reserved.

import Foundation

public struct DeckFilter {
    public var factions: [CardFaction]?
    public var investigatorsIds: [Int]?
    
    public init(factions: [CardFaction]?, investigatorsIds: [Int]?) {
        self.factions = factions
        self.investigatorsIds = investigatorsIds
    }
}
