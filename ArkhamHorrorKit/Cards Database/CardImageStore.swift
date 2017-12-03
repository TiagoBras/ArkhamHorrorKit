//
//  CardsDownloader.swift
//  ArkhamHorrorKit
//
//  Created by Tiago Bras on 26/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

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
    
    private let serverDir: URL?
    private let localDir: URL
    
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
        } else if let image = cache.getCachedValue(name) {
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
                        cache.setCachedValue(name, value: image)
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
                                self?.cache.setCachedValue(name, value: image)
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
    
    public enum CardImageStoreError: Error {
        case imageNotFound(String)
        case serverNotAvailable
        case serverAndLocalDirsCannotBeEqual
        case invalidImageData(String)
        case cardDoesNotHaveBackImage(String)
    }
}
