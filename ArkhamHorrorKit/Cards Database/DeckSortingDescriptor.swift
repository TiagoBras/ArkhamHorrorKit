//  Copyright © 2017 Tiago Bras. All rights reserved.

import Foundation

public struct DeckSortingDescriptor: Equatable {
    public enum Column {
        case name, updateDate, creationDate, faction, investigator
        
        public var name: String {
            switch self {
            case .name: return "Name"
            case .updateDate: return "Update Date"
            case .creationDate: return "Creation Date"
            case .faction: return "Faction"
            case .investigator: return "Investigator"
            }
        }
    }
    
    public var column: Column
    public var ascending: Bool
    
    public init(column: Column, ascending: Bool = true) {
        self.column = column
        self.ascending = ascending
    }
    
    public static func ==(lhs: DeckSortingDescriptor, rhs: DeckSortingDescriptor) -> Bool {
        return lhs.column == rhs.column && lhs.ascending == rhs.ascending
    }
}
