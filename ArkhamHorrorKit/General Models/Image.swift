//
//  Image.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 24/04/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

#if os(iOS) || os(watchOS) || os(tvOS)
    import UIKit
#elseif os(OSX)
    import Cocoa
#endif


enum Image {
    case atURL(URL)
    case inMainBundle(String)
    case inDocumentsDirectory(String)
}

extension Image {
    var uiImage: UIImage? {
        switch self {
        case .atURL(let url):
            guard let data = try? Data(contentsOf: url) else { return nil}
            
            return UIImage(data: data)
        case .inMainBundle(let name):
            return UIImage(named: name)
        case .inDocumentsDirectory(let name):
            guard let fileURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask).first?.appendingPathComponent(name) else {
                return nil
            }
            
            guard let data = try? Data(contentsOf: fileURL) else { return nil }
            
            return UIImage(data: data)
        }
    }
}
