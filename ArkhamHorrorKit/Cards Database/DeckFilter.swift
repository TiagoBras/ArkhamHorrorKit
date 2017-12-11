//  Copyright © 2017 Tiago Bras. All rights reserved.

import Foundation

public struct DeckFilter {
    public var factions: [CardFaction]?
    public var investigators: [Investigator]?
    
    public init(factions: [CardFaction]?, investigators: [Investigator]?) {
        self.factions = factions
        self.investigators = investigators
    }
}
