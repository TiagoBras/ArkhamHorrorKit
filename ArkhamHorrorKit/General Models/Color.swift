//
//  Color.swift
//  ArkhamHorrorCompanion
//
//  Created by Tiago Bras on 08/05/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

#if os(iOS) || os(watchOS) || os(tvOS)
    import UIKit
#elseif os(OSX)
    import Cocoa
#endif

class Color: Equatable, CustomStringConvertible {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
    
    static let white: Color = Color(red: 1, green: 1, blue: 1, alpha: 1)
    static let black: Color = Color(red: 0, green: 0, blue: 0, alpha: 1)
    
    init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    convenience init?(hexString hex: String ) {
        var red: String!
        var green: String!
        var blue: String!
        var alpha: String!
        
        let chars = Array(hex)
        
        switch chars.count {
        case 1:
            red = "\(chars[0])\(chars[0])"
            green = "\(chars[0])\(chars[0])"
            blue = "\(chars[0])\(chars[0])"
            alpha = "\(chars[0])\(chars[0])"
        case 3:
            red = "\(chars[0])\(chars[0])"
            green = "\(chars[1])\(chars[1])"
            blue = "\(chars[2])\(chars[2])"
            alpha = "ff"
        case 4:
            red = "\(chars[0])\(chars[0])"
            green = "\(chars[1])\(chars[1])"
            blue = "\(chars[2])\(chars[2])"
            alpha = "\(chars[3])\(chars[3])"
        case 6:
            red = "\(chars[0])\(chars[1])"
            green = "\(chars[2])\(chars[3])"
            blue = "\(chars[4])\(chars[5])"
            alpha = "ff"
        case 8:
            red = "\(chars[0])\(chars[1])"
            green = "\(chars[2])\(chars[3])"
            blue = "\(chars[4])\(chars[5])"
            alpha = "\(chars[6])\(chars[7])"
        default: return nil
        }
        
        self.init(red: Double(Int(red, radix: 16)!) / 255,
                  green: Double(Int(green, radix: 16)!) / 255,
                  blue: Double(Int(blue, radix: 16)!) / 255,
                  alpha: Double(Int(alpha, radix: 16)!) / 255)
    }
    
    var hex: String {
        let r = String(format: "%02X", Int(self.red * 255))
        let g = String(format: "%02X", Int(self.green * 255))
        let b = String(format: "%02X", Int(self.blue * 255))
        let a = String(format: "%02X", Int(self.alpha * 255))
        
        return "\(r)\(g)\(b)\(a)"
    }
    
    enum ColorKey: String {
        case red, green, blue, alpha
    }
    
    var dictionaryRepresentation: [String: Double] {
        var d: [String: Double] = [:]
        d[ColorKey.red.rawValue] = red
        d[ColorKey.green.rawValue] = green
        d[ColorKey.blue.rawValue] = blue
        d[ColorKey.alpha.rawValue] = alpha
        
        return d
    }
    
    static func fromDictionaryRepresentation(_ d: [String: Double]) -> Color? {
        guard let red = d[ColorKey.red.rawValue] else { return nil }
        guard let green = d[ColorKey.green.rawValue] else { return nil }
        guard let blue = d[ColorKey.blue.rawValue] else { return nil }
        guard let alpha = d[ColorKey.alpha.rawValue] else { return nil }
        
        return Color(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    var description: String {
        return "(\(red), \(green), \(blue), \(alpha))"
    }
    
    static func ==(lhs: Color, rhs: Color) -> Bool {
        return lhs.hex == rhs.hex
    }
    
    #if os(iOS) || os(watchOS) || os(tvOS)
    var uiColor: UIColor {
        return UIColor(red: CGFloat(red),
                       green: CGFloat(green),
                       blue: CGFloat(blue),
                       alpha: CGFloat(alpha))
    }
    #elseif os(OSX)
    var nsColor: NSColor {
        return NSColor(red: CGFloat(red),
                       green: CGFloat(green),
                       blue: CGFloat(blue),
                       alpha: CGFloat(alpha))
    }
    #endif
}
