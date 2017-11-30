//
//  Image.swift
//  TBSwiftKit
//
//  Created by Tiago Bras on 24/04/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

#if os(iOS) || os(watchOS) || os(tvOS)
    import UIKit
#elseif os(OSX)
    import Cocoa
#endif

public typealias ImageNameWithoutExtension = String
public typealias ImageNameWithExtension = String

public enum Image {
    case atURL(URL)
    case inBundle(ImageNameWithoutExtension, Bundle)
    case inMainBundle(ImageNameWithoutExtension)
    case inDocumentsDirectory(ImageNameWithExtension)
    
    #if os(iOS) || os(watchOS) || os(tvOS)
    
    public var uiImage: UIImage? {
        switch self {
        case .atURL(let url):
            guard let data = try? Data(contentsOf: url) else { return nil }
            
            return UIImage(data: data)
        case .inBundle(let name, let bundle):
            return UIImage(named: name, in: bundle, compatibleWith: nil)
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
    
    #elseif os(OSX)
    
    public var nsImage: NSImage? {
        switch self {
        case .atURL(let url):
            guard let data = try? Data(contentsOf: url) else { return nil }
            
            return NSImage(data: data)
        case .inBundle(let name, let bundle):
            return bundle.image(forResource: NSImage.Name(rawValue: name))
        case .inMainBundle(let name):
            return NSImage(named: NSImage.Name(rawValue: name))
        case .inDocumentsDirectory(let name):
            guard let fileURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask).first?.appendingPathComponent(name) else {
                    return nil
            }
            
            guard let data = try? Data(contentsOf: fileURL) else { return nil }
            
            return NSImage(data: data)
        }
    }
    
    #endif
}
