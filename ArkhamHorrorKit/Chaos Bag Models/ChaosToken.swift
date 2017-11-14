//
//  ChaosToken.swift
//  ArkhamHorrorKit iOS
//
//  Created by Tiago Bras on 10/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation

public enum ChaosToken: String {
    case p1, zero, m1, m2, m3, m4, m5, m6, m7, m8
    case skull, autofail, tablet, cultist, eldersign, elderthing
    
    public static let allValues: [ChaosToken] = [
        .p1, .zero, .m1, .m2, .m3, .m4, .m5, .m6, .m7, .m8, .skull,
        .autofail, .tablet, .cultist, .eldersign, .elderthing
    ]
}
