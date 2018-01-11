//
//  SingleFileDownloader.swift
//  TBSwiftKit iOS
//
//  Created by Tiago Bras on 25/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation

public class FileDownloadManager: NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
    private var activeDownloads: [URL: Download] = [:]
    
    private lazy var downloadSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: UUID().uuidString)
        
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    #if os(iOS) || os(watchOS) || os(tvOS)
    public var backgroundSessionCompletionHandler: (() -> ())?
    
    public init(backgroundSessionCompletionHandler: (() -> ())? = nil) {
        self.backgroundSessionCompletionHandler = backgroundSessionCompletionHandler
    }
    #endif
    
    public typealias CompletionHandler = (URL?, Error?) -> ()
    public typealias ProgressHandler = ((Float) -> ())
    
    private let queue = DispatchQueue(label: UUID().uuidString,
                                      qos: DispatchQoS.background,
                                      attributes: DispatchQueue.Attributes.concurrent,
                                      autoreleaseFrequency: .inherit,
                                      target: nil)
    
    public func downloadFile(at url: URL, storeIn directory: URL, completion: @escaping CompletionHandler) throws {
        try downloadFile(at: url, storeIn: directory, progress: nil, completion: completion)
    }
    
    public func downloadFile(at url: URL,
                      storeIn directory: URL,
                      progress: ProgressHandler?,
                      completion: @escaping CompletionHandler) throws {
        try queue.sync {
            let download: Download
            
            if let activeDownload = activeDownloads[url] {
                download = activeDownload
            } else {
                download = Download()
                download.task = downloadSession.downloadTask(with: url)
                
                activeDownloads[url] = download
            }
            
            var isDir: ObjCBool = false
            
            if !FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDir) || !isDir.boolValue {
                throw DownloadManagerError.notADirectory(directory.path)
            }
            
            // Add new handler
            var handlers = Download.Handlers()
            handlers.completion = completion
            handlers.progress = progress
            handlers.storeInDirectory = directory
            
            download.completionHandlers.append(handlers)
            download.task?.resume()
            download.isDownloading = true
        }
    }
    
    public func cancelDownload(url: URL) {
        queue.sync {
            guard let download = activeDownloads.removeValue(forKey: url) else { return }
            
            download.task?.cancel()
            download.completeAll(url: nil, error: DownloadManagerError.downloadCancelled)
        }
    }
    
    public func cancelAllDownloads() {
        queue.sync {
            for (_, download) in activeDownloads {
                download.task?.cancel()
                download.completeAll(url: nil, error: DownloadManagerError.downloadCancelled)
            }
            
            activeDownloads.removeAll()
        }
    }
    
    public func pauseDownload(url: URL) {
        queue.sync {
            guard let download = activeDownloads[url] else { return }
            
            if download.isDownloading {
                download.task?.cancel(byProducingResumeData: { (data) in
                    download.resumeData = data
                })
                download.isDownloading = true
            }
        }
    }
    
    public func resumeDownload(url: URL) {
        queue.sync {
            guard let download = activeDownloads[url] else { return }
            
            if let resumeData = download.resumeData {
                download.task = downloadSession.downloadTask(withResumeData: resumeData)
            } else {
                download.task = downloadSession.downloadTask(with: url)
            }
            
            download.task?.resume()
            download.isDownloading = true
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        queue.sync {
            guard let url = downloadTask.originalRequest?.url else { return }
            guard let download = activeDownloads.removeValue(forKey: url) else { return }
            guard let response = downloadTask.response as? HTTPURLResponse else { return }
            
            let fm = FileManager.default
            
            var deleteFileAtLocation = true
            
            for handler in download.completionHandlers {
                if response.statusCode != 200 {
                    handler.completion?(nil, DownloadManagerError.httpStatusCode(response.statusCode))
                } else if let directory = handler.storeInDirectory {
                    let destinationURL = directory.appendingPathComponent(url.lastPathComponent)
                    
                    do {
                        try? fm.removeItem(at: destinationURL)
                        
                        try fm.copyItem(at: location, to: destinationURL)
                        
                        handler.completion?(destinationURL, nil)
                    } catch {
                        handler.completion?(nil, error)
                    }
                } else {
                    // Since we won't copy the file to a new location, don't delete it
                    deleteFileAtLocation = false
                    
                    handler.completion?(location, nil)
                }
            }
            
            if deleteFileAtLocation {
                try? fm.removeItem(at: location)
            }
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        queue.sync {
            guard let url = downloadTask.originalRequest?.url else { return }
            guard let download = activeDownloads[url] else { return }
            
            let doublePercentage = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            
            download.progressAll(progress: Float(doublePercentage))
        }
    }
    
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        queue.sync {
            if let error = error {
                print(error)
            }
            
            for (_, download) in activeDownloads {
                download.completeAll(url: nil, error: DownloadManagerError.sessionBecameInvalid)
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        queue.sync {
            if let error = error {
                print(error)
            }
            
            guard let url = task.originalRequest?.url else { return }
            guard let download = activeDownloads.removeValue(forKey: url) else { return }
            
            download.completeAll(url: nil, error: DownloadManagerError.internetNotAvailable)
        }
    }
    
    #if os(iOS) || os(watchOS) || os(tvOS)
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.backgroundSessionCompletionHandler?()
        }
    }
    #endif
    
    public enum DownloadManagerError: Error {
        case notADirectory(String)
        case httpStatusCode(Int)
        case sessionBecameInvalid
        case internetNotAvailable
        case downloadCancelled
    }
}
