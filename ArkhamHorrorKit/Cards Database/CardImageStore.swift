//  Copyright © 2017 Tiago Bras. All rights reserved.

import TBSwiftKit

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
    
    public init(serverDir: URL, localDir: URL, cacheSize: Int) throws {
        if serverDir == localDir {
            throw CardImageStoreError.serverAndLocalDirsCannotBeEqual
        }
        
        self.serverDir = serverDir
        self.localDir = localDir
        self.cacheSize = cacheSize >= 5 ? cacheSize : 10
    }
    
    public init(localDir: URL, cacheSize: Int) {
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
                        cache.setCachedValue(name, value: image)
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
                let serverPath = serverDir.appendingPathComponent(name)
                
                try downloadManager.downloadFile(
                    at: serverPath,
                    storeIn: localDir,
                    completion: { [weak self] (url, error) in
                        if let error = error as? FileDownloadManager.DownloadManagerError {
                            return completion(nil, error)
                        }
                        
                        #if os(iOS) || os(watchOS) || os(tvOS)
                            if let image = UIImage(contentsOfFile: localPath) {
                                self?.cache.setCachedValue(name, value: image)
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
    
    public func missingImages(for cards: [Card]) throws -> [URL] {
        guard let serverDir = serverDir else { throw CardImageStoreError.serverDirNotDefined }
        
        var imageNames = [String]()
        imageNames.append(contentsOf: cards.map({ $0.frontImageName }))
        imageNames.append(contentsOf: cards.flatMap({ $0.backImageName }))
        
        return imageNames.flatMap { (name) -> URL? in
            let url = localDir.appendingPathComponent(name)
            
            if FileManager.default.fileExists(atPath: url.path) {
                return nil
            } else {
                return serverDir.appendingPathComponent(name)
            }
        }
    }
    
    @discardableResult
    public func downloadMissingImages(
        for cards: [Card],
        progress: FileBatchDownload.ProgressHandler?,
        completion: @escaping FileBatchDownload.CompletionHandler) throws -> FileBatchDownload {
        batchDownloadManager = FileBatchDownload(files: try missingImages(for: cards),
                                                 storeIn: localDir,
                                                 progress: progress,
                                                 completion: completion)
        
        try batchDownloadManager?.startDownload()
        
        return batchDownloadManager!
    }
    
    public enum CardImageStoreError: Error {
        case imageNotFound(String)
        case serverNotAvailable
        case serverAndLocalDirsCannotBeEqual
        case invalidImageData(String)
        case cardDoesNotHaveBackImage(String)
        case serverDirNotDefined
    }
}
