//
//  ScenarioChaosBag.swift
//  ArkhamHorrorKit
//
//  Created by Tiago Bras on 10/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation
import GRDB

class ScenarioChaosBagRecord: Record {
    var chaosBagId: Int
    var scenarioId: Int
    var difficulty: ChaosBagDifficulty
    
    override class var databaseTableName: String {
        return "ScenarioChaosBag"
    }
    
    init(chaosBagId: Int, scenarioId: Int, difficulty: ChaosBagDifficulty) {
        self.chaosBagId = chaosBagId
        self.scenarioId = scenarioId
        self.difficulty = difficulty
        
        super.init()
    }
    
    required init(row: Row) {
        chaosBagId = row["chaos_bag_id"]
        difficulty = ChaosBagDifficulty(rawValue: row["difficulty"]!)!
        scenarioId = row["scenario_id"]
        
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container["chaos_bag_id"] = chaosBagId
        container["scenario_id"] = scenarioId
        container["difficulty"] = difficulty.rawValue
    }
}
