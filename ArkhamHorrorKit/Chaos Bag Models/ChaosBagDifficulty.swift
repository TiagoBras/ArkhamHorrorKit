//
//  ChaosBagDifficulty.swift
//  ArkhamHorrorKit iOS
//
//  Created by Tiago Bras on 10/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation

// Don't modify this enumeration since its values are used by ScenarioChaosBag
public enum ChaosBagDifficulty: String {
    case easy, normal, hard, expert, standalone
    
    public static let allValues: [ChaosBagDifficulty] = [
        .easy, .normal, .hard, .expert, .standalone
    ]
    
    var name: String {
        return rawValue.capitalized
    }
}
