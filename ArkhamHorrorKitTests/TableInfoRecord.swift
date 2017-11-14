//
//  TableInfoRecord.swift
//  ArkhamHorrorKit
//
//  Created by Tiago Bras on 10/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation
import GRDB

enum ColumnType: String {
    case text, numeric, integer, real, blob, boolean
}

struct ColumnInfo {
    var cid: Int
    var name: String
    var type: ColumnType
    var notNull: Int
    var defaultValue: Any?
    var isPK: Bool
    
    init(row: Row) {
        cid = row["cid"]
        name = row["name"]
        
        let typeString = (row["type"]! as! String).lowercased()
        
        type = ColumnType(rawValue: typeString)!
        notNull = row["notnull"]
        defaultValue = row["dflt_value"]
        isPK = row["pk"]
    }
}

struct TableInfo {
    let rows: [ColumnInfo]
    
    subscript(columnName: String) -> ColumnInfo? {
        guard let index = rows.index(where: { $0.name == columnName }) else {
            return nil
        }
        
        return rows[index]
    }
    
    init(rows: [Row]) {
        self.rows = rows.map({ ColumnInfo(row: $0) })
    }
}

