//
//  Download.swift
//  TBSwiftKit
//
//  Created by Tiago Bras on 25/11/2017.
//  Copyright © 2017 Tiago Bras. All rights reserved.
//

import Foundation

class Download {
    typealias CompletionHandler = (URL?, Error?) -> ()
    typealias ProgressHandler = (Float) -> ()
    
    struct Handlers {
        var completion: CompletionHandler?
        var progress: ProgressHandler?
        var storeInDirectory: URL?
    }
    
    var task: URLSessionDownloadTask?
    var isDownloading = false
    var resumeData: Data?
    
    var completionHandlers: [Handlers] = []
    
    func completeAll(url: URL?, error: Error?) {
        for handler in completionHandlers {
            handler.completion?(url, error)
        }
    }
    
    func progressAll(progress: Float) {
        for handler in completionHandlers {
            handler.progress?(progress)
        }
    }
}
