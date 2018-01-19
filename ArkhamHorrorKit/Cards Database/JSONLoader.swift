import Foundation
import SwiftyJSON
import TBSwiftKit

public class JSONLoader {
    public enum JSONLoaderError: Error {
        case fileNotFound(URL)
        case invalidFilename(String)
    }
    
    public struct JSONLoaderResults: Comparable {
        public static func <(lhs: JSONLoader.JSONLoaderResults, rhs: JSONLoader.JSONLoaderResults) -> Bool {
            return lhs.filename < rhs.filename
        }
        
        public static func ==(lhs: JSONLoader.JSONLoaderResults, rhs: JSONLoader.JSONLoaderResults) -> Bool {
            guard lhs.filename == rhs.filename else { return false }
            guard lhs.checksum == rhs.checksum else { return false }
            
            return lhs.json == rhs.json
        }
        
        public let filename: String
        public let json: JSON
        public let checksum: String
        
        fileprivate init(filename: String, json: JSON, checksum: String) {
            self.filename = filename
            self.json = json
            self.checksum = checksum
        }
    }
    
    public class func load(url: URL) throws -> JSONLoaderResults {
        let data = try Data(contentsOf: url)
        
        return JSONLoaderResults(filename: url.lastPathComponent,
                                 json: JSON(data: data),
                                 checksum: CryptoHelper.sha256Hex(data: data))
    }
    
    public class func load(bundle: Bundle, resource: String, ext: String) throws -> JSONLoaderResults {
        guard let url = bundle.url(forResource: resource, withExtension: ext) else {
            let url = URL(fileURLWithPath: "\(bundle.bundlePath)/\(resource).\(ext)")
            
            throw JSONLoaderError.fileNotFound(url)
        }
        
        return try JSONLoader.load(url: url)
    }
    
    public class func load(bundle: Bundle, filename: String) throws -> JSONLoaderResults {
        let components = filename.split(separator: ".").map({ String($0) })
        
        if components.count != 2 {
            throw JSONLoaderError.invalidFilename(filename)
        }
        
        return try JSONLoader.load(bundle: bundle, resource: components[0], ext: components[1])
    }
}
