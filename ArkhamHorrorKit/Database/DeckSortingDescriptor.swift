//
//  DeckSortingDescriptor.swift
//  ArkhamHorrorKit iOS
//
//  Created by Tiago Bras on 06/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation

public struct DeckSortingDescriptor: Equatable {
    public enum Column {
        case updateDate, creationDate, faction, investigatorNumber
        
        public var name: String {
            switch self {
            case .updateDate: return "Update Date"
            case .creationDate: return "Creation Date"
            case .faction: return "Faction"
            case .investigatorNumber: return "Investigator"
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
