//  Copyright © 2017 Tiago Bras. All rights reserved.

import TBSwiftKit
import SwiftyJSON

public class CardImageStore {
    private let cacheSize: Int
    #if os(iOS) || os(watchOS) || os(tvOS)
    public private(set) var cache = Cache<String, UIImage>()
    #elseif os(OSX)
    public private(set) var cache = Cache<String, NSImage>()
    #endif
    
    private var imagesNotFound = Set<String>()
    
    private let downloadManager = FileDownloadManager()
    private var batchDownloadManager: FileBatchDownload?
    
    public let serverDir: URL?
    public let localDir: URL
    public let authToken: String
    
    public init(serverDomain: URL, localDir: URL, authToken: String, cacheSize: Int) throws {
        if serverDomain == localDir {
            throw CardImageStoreError.serverAndLocalDirsCannotBeEqual
        }
        
        self.authToken = authToken
        self.serverDir = serverDomain
        self.localDir = localDir
        self.cacheSize = cacheSize >= 5 ? cacheSize : 10
    }
    
    public init(localDir: URL, cacheSize: Int) {
        self.authToken = ""
        self.serverDir = nil
        self.localDir = localDir
        self.cacheSize = cacheSize >= 5 ? cacheSize : 10
    }
    
    #if os(iOS) || os(watchOS) || os(tvOS)
    public typealias CompletionHandler = (UIImage?, Error?) -> ()
    #elseif os(OSX)
    public typealias CompletionHandler = (NSImage?, Error?) -> ()
    #endif
    public typealias ProgressHandler = (Int, Int) -> ()
    
    #if os(iOS) || os(watchOS) || os(tvOS)
    func getLocalImage(name: String, size: CGSize? = nil) -> UIImage? {
        let cacheName: String
        
        if let size = size {
            cacheName = "\(name)@\(size.width)x\(size.height)"
        } else {
            cacheName = name
        }
        
        if let image = cache.get(cacheName) {
            return image
        }
        
        let localPath = localDir.appendingPathComponent(name).path
        
        if FileManager.default.fileExists(atPath: localPath) {
            if let image = UIImage(contentsOfFile: localPath) {
                if let size = size {
                    let resizedImage = resizeImage(image: image, size: size)
                    
                    cache.set(cacheName, value: resizedImage)
                    
                    return resizedImage
                } else {
                    cache.set(cacheName, value: image)
                    
                    return image
                }
            } else {
                return nil
            }
        }
        
        return nil
    }
    
    public func getLocalFrontImage(card: Card) -> UIImage? {
        return getLocalImage(name: card.frontImageName)
    }
    
    public func getLocalBackImage(card: Card) -> UIImage? {
        guard let backImageName = card.backImageName else {
            return nil
        }
        
        return getLocalImage(name: backImageName)
    }
    #elseif os(OSX)
    func getLocalImage(name: String) -> NSImage? {
        if let image = cache.get(name) {
            return image
        }
        
        let localPath = localDir.appendingPathComponent(name).path
        
        if FileManager.default.fileExists(atPath: localPath) {
            if let image = NSImage(contentsOfFile: localPath) {
                cache.set(name, value: image)
                return image
            } else {
                return nil
            }
        }
    
        return nil
    }
    
    public func getLocalFrontImage(card: Card) -> NSImage? {
        return getLocalImage(name: card.frontImageName)
    }
    
    public func getLocalBackImage(card: Card) -> NSImage? {
        guard let backImageName = card.backImageName else {
            return nil
        }
    
        return getLocalImage(name: backImageName)
    }
    #endif
    
    public func getFrontImage(card: Card, completion: @escaping CompletionHandler) throws {
        try getImage(name: card.frontImageName, completion: completion)
    }
    
    public func getBackImage(card: Card, completion: @escaping CompletionHandler) throws {
        guard let backImageName = card.backImageName else {
            return completion(nil, CardImageStoreError.cardDoesNotHaveBackImage(card.name))
        }
        
        try getImage(name: backImageName, completion: completion)
    }
    
    func getImage(name: String, completion: @escaping CompletionHandler) throws {
        if imagesNotFound.contains(name) {
            completion(nil, CardImageStoreError.imageNotFound(name))
        } else if let image = cache.get(name) {
            completion(image, nil)
        } else {
            let localPath = localDir.appendingPathComponent(name).path
            
            // Check if image exists locally
            if FileManager.default.fileExists(atPath: localPath) {
                #if os(iOS) || os(watchOS) || os(tvOS)
                    if let image = UIImage(contentsOfFile: localPath) {
                        cache.set(name, value: image)
                        completion(image, nil)
                    } else {
                        imagesNotFound.insert(name)
                        completion(nil, CardImageStoreError.invalidImageData(name))
                    }
                #elseif os(OSX)
                    if let image = NSImage(contentsOfFile: localPath) {
                        cache.set(name, value: image)
                        completion(image, nil)
                    } else {
                        imagesNotFound.insert(name)
                        completion(nil, CardImageStoreError.invalidImageData(name))
                    }
                #endif
            } else if let serverDir = serverDir {
                // Try downloading image from source (only if source is diferent than destination
                let serverPath = serverDir.appendingPathComponent("images/\(name)")
                
                try downloadManager.downloadFile(
                    at: serverPath,
                    storeIn: localDir,
                    completion: { [weak self] (url, error) in
                        if let error = error as? FileDownloadManager.DownloadManagerError {
                            return completion(nil, error)
                        }
                        
                        #if os(iOS) || os(watchOS) || os(tvOS)
                            if let image = UIImage(contentsOfFile: localPath) {
                                self?.cache.set(name, value: image)
                                completion(image, nil)
                            } else {
                                self?.imagesNotFound.insert(name)
                                completion(nil, CardImageStoreError.invalidImageData(name))
                            }
                        #elseif os(OSX)
                            if let image = NSImage(contentsOfFile: localPath) {
                                self?.cache.set(name, value: image)
                                completion(image, nil)
                            } else {
                                self?.imagesNotFound.insert(name)
                                completion(nil, CardImageStoreError.invalidImageData(name))
                            }
                        #endif
                })
            } else {
                imagesNotFound.insert(name)
                completion(nil, CardImageStoreError.imageNotFound(name))
            }
        }
    }
    
    private var server: DatabaseServer?
    
    public func missingImages(completion: @escaping ([URL]?, Error?) -> ()) {
        guard let serverDomain = serverDir else {
            return completion(nil, CardImageStoreError.serverDomainNotDefined)
        }
        
        server = DatabaseServer(domain: serverDomain, authenticationToken: authToken)
        server?.checkMissingImages(imagesDirectory: localDir, completion: completion)
    }
    
    public func downloadImages(
        urls: [URL],
        start: ((FileBatchDownload) -> ())?,
        progress: FileBatchDownload.ProgressHandler?,
        completion: @escaping (FileBatchDownload.DownloadReport?, Error?) -> ()) {
        DispatchQueue.global().async { [weak self] in
            guard let localDir = self?.localDir else { return }
            
            if let dm = self?.batchDownloadManager {
                dm.cancelDownload()
            }
            
            self?.batchDownloadManager = FileBatchDownload(files: urls,
                                                           storeIn: localDir,
                                                           progress: progress,
                                                           completion: completion)
            do {
                if let dm = self?.batchDownloadManager {
                    try dm.startDownload()
                    start?(dm)
                }
            } catch {
                completion(nil, error)
            }
        }
    }
    
    public enum CardImageStoreError: Error {
        case imageNotFound(String)
        case serverNotAvailable
        case serverAndLocalDirsCannotBeEqual
        case invalidImageData(String)
        case cardDoesNotHaveBackImage(String)
        case serverDomainNotDefined
        case httpStatusCode(Int)
        case invalidURLTaskData
    }
    
    #if os(iOS) || os(watchOS) || os(tvOS)
    func resizeImage(image: UIImage, size target: CGSize, opaque: Bool = false) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(target, opaque, 0)
        
        let size = image.size
        let scale = min(abs(target.width / size.width), abs(target.height / size.height))
        
        image.draw(in: CGRect(x: 0.5 * (target.width - (size.width * scale)),
                    y: 0.5 * (target.height - (size.height * scale)),
                    width: size.width * scale,
                    height: size.height * scale))
        
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    #endif
    
}
