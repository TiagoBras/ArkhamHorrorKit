//
//  BatchFileDownload.swift
//  TBSwiftKit
//
//  Created by Tiago Bras on 25/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation

public class FileBatchDownload {
    private let dm = FileDownloadManager()
    private var files: [URL]
    private var filesDownloaded = [URL]()
    private var filesNotDownloaded = [URL]()
    private var directory: URL
    
    public private(set) var hasStartedDownload = false
    
    private lazy var totalFiles: Int = {
        return files.count
    }()
    
    public typealias FilesDownloaded = Int
    public typealias TotalFiles = Int
    public typealias ProgressHandler = (FilesDownloaded, TotalFiles) -> ()
    public typealias CompletionHandler = (DownloadReport, Error?) -> ()
    
    private var progress: ProgressHandler?
    private var completion: CompletionHandler
    private var completed: Bool = false
    
    public init(files: [URL], storeIn directory: URL, progress: ProgressHandler?, completion: @escaping CompletionHandler) {
        self.files = files
        self.directory = directory
        self.progress = progress
        self.completion = completion
    }
    
    private let queue = DispatchQueue(label: UUID().uuidString,
                                      qos: DispatchQoS.background,
                                      attributes: DispatchQueue.Attributes.concurrent,
                                      autoreleaseFrequency: .inherit,
                                      target: nil)
    
    public func startDownload() throws {
        if !hasStartedDownload && !completed {
            hasStartedDownload = true
            
            try files.forEach { (url) in
                try dm.downloadFile(at: url, storeIn: directory, completion: { [weak self] (fileUrl, error) in
                    self?.queue.sync {
                        if fileUrl != nil {
                            self?.filesDownloaded.append(url)
                        } else {
                            self?.filesNotDownloaded.append(url)
                        }
                        
                        guard let downloaded = self?.filesDownloaded,
                            let notDownloaded = self?.filesNotDownloaded,
                            let totalFiles = self?.totalFiles else {
                                return
                        }
                        
                        self?.progress?(downloaded.count, totalFiles)
                        
                        if downloaded.count + notDownloaded.count == totalFiles {
                            self?.completed = true
                            self?.completion(DownloadReport(filesDownloaded: downloaded,
                                                    filesNotDownloaded: notDownloaded), error)
                        }
                    }
                })
            }
        }
    }
    
    public func cancelDownload() {
        queue.sync {
            if !self.completed {
                self.dm.cancelAllDownloads()
            }
        }
    }
    
    public struct DownloadReport {
        public var filesDownloaded: [URL]
        public var filesNotDownloaded: [URL]
    }
    
    public enum FileBatchDownloadError: Error {
        case downloadCancelled
    }
}
