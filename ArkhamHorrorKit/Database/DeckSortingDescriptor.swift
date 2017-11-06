//
//  DeckSortingDescriptor.swift
//  ArkhamHorrorKit iOS
//
//  Created by Tiago Bras on 06/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation

struct DeckSortingDescriptor {
    enum Column {
        case updateDate, creationDate, faction, investigatorNumber
        
        var name: String {
            switch self {
            case .updateDate: return "Update Date"
            case .creationDate: return "Creation Date"
            case .faction: return "Faction"
            case .investigatorNumber: return "Investigator"
            }
        }
    }
    
    var column: Column
    var ascending: Bool
}
