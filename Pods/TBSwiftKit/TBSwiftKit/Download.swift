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
}
