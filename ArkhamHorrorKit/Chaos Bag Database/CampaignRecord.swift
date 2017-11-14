//
//  Campaign.swift
//  ArkhamHorrorKit
//
//  Created by Tiago Bras on 10/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation
import GRDB
import TBSwiftKit

class CampaignRecord: Record {
    var id: Int?
    var name: String
    var iconName: String?
    var protected: Bool
    
    override class var databaseTableName: String {
        return "Campaign"
    }
    
    init(name: String, iconName: String?, protected: Bool) {
        self.name = name
        self.iconName = iconName
        self.protected = protected
        
        super.init()
    }
    
    required init(row: Row) {
        id = row["id"]
        name = row["name"]
        iconName = row["icon_name"]
        protected = row["protected"]
        
        super.init(row: row)
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = Int(rowID)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["name"] = name
        container["icon_name"] = iconName
        container["protected"] = protected
    }
}
