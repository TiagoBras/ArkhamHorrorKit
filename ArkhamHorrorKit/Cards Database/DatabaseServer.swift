//
//  URLRequestHelper.swift
//  ArkhamHorrorKit
//
//  Created by Tiago Bras on 18/01/2018.
//  Copyright © 2018 Tiago Bras. All rights reserved.
//

import Foundation
import SwiftyJSON

public struct UpdateReport {
    public let jsonFilesUpdateAvailable: Bool
    public let imagesUpdateAvailable: Bool
    
    init(jsonFilesUpdateAvailable: Bool, imagesUpdateAvailable: Bool) {
        self.jsonFilesUpdateAvailable = jsonFilesUpdateAvailable
        self.imagesUpdateAvailable = imagesUpdateAvailable
    }
}

public class DatabaseServer {
    public enum DatabaseServerError: Error {
        case invalidURLTaskData
        case httpStatusCode(Int)
    }
    
    public private(set) var domain: URL
    private var authenticationToken: String
    
    public init(domain: URL, authenticationToken: String) {
        self.domain = domain
        self.authenticationToken = authenticationToken
    }
    
    private func createPostRequest(url: URL, httpBody: [String: Any]) throws -> URLRequest {
        var request = URLRequest(url: url,
                                 cachePolicy: .useProtocolCachePolicy,
                                 timeoutInterval: 20)
        request.setValue("Bearer \(authenticationToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: httpBody)
        
        return request
    }
    
    public func checkUpdates(jsonChecksum: String?,
                             imagesChecksum: String?,
                             completion: @escaping (UpdateReport?, Error?) -> ()) {
        DispatchQueue.global().async { [weak self] in
            guard jsonChecksum != nil || imagesChecksum != nil else {
                let report = UpdateReport(jsonFilesUpdateAvailable: false, imagesUpdateAvailable: false)
                
                return completion(report, nil)
            }
            
            do {
                var bodyData = [String: String]()
                
                if let jsonChecksum = jsonChecksum {
                    bodyData["json_hash"] = jsonChecksum
                }
                
                if let imagesChecksum = imagesChecksum {
                    bodyData["images_hash"] = imagesChecksum
                }
                
                guard let url = self?.domain.appendingPathComponent("/ahc/check_updates") else { return }
                guard let request = try self?.createPostRequest(url: url, httpBody: bodyData) else {
                    return
                }
                
                let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    if let error = error {
                        return completion(nil, error)
                    }
                    
                    guard let data = data else {
                        return completion(nil, DatabaseServerError.invalidURLTaskData)
                    }
                    
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                        return completion(nil, DatabaseServerError.httpStatusCode(httpStatus.statusCode))
                    }
                    
                    do {
                        let json = try JSON(data: data)
                        let shouldUpdateJson = json["json_update_available"].boolValue
                        let shouldUpdateImages = json["images_update_available"].boolValue
                        
                        let report = UpdateReport(jsonFilesUpdateAvailable: shouldUpdateJson,
                                                  imagesUpdateAvailable: shouldUpdateImages)
                        
                        completion(report, nil)
                    } catch {
                        completion(nil, error)
                    }
                    
                }
                
                task.resume()
            } catch {
                completion(nil, error)
            }
        }
    }
    
    public func checkMissingImages(imagesDirectory: URL, completion: @escaping ([URL]?, Error?) -> ()) {
        DispatchQueue.global().async { [weak self] in
            do {
                let paths = FileManager.default.contentsOf(
                    directory: imagesDirectory,
                    fileExtension: "jpeg").sorted { (a, b) -> Bool in
                        return a.path < b.path
                }
                
                let imagesNames = paths.map({ $0.lastPathComponent })
                
                guard let url = self?.domain.appendingPathComponent("/ahc/update") else { return }
                guard let request = try self?.createPostRequest(url: url,
                                                                httpBody: ["images": imagesNames]) else {
                    return
                }
                
                let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    if let error = error {
                        return completion(nil, error)
                    }
                    
                    guard let data = data else {
                        return completion(nil, DatabaseServerError.invalidURLTaskData)
                    }
                    
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                        return completion(nil, DatabaseServerError.httpStatusCode(httpStatus.statusCode))
                    }
                    
                    do {
                        let json = try JSON(data: data)
                        
                        if let imageURL = json["images_url"].string,
                            let images = json["images"].arrayObject as? [String] {
                            
                            if let url = URL(string: imageURL) {
                                let fullpaths = images.map({ url.appendingPathComponent($0) })
                                
                                return completion(fullpaths, nil)
                            }
                        }
                        
                        return completion([], nil)
                    } catch {
                        return completion(nil, error)
                    }
                }
                
                task.resume()
            } catch {
                completion(nil, error)
            }
        }
    }
    
    public func checkUpdatedJsonFiles(jsonFilesChecksums: [String: String],
                                      completion: @escaping ([URL]?, Error?) -> ()) {
        DispatchQueue.global().async { [weak self] in
            do {
                guard let url = self?.domain.appendingPathComponent("/ahc/update") else { return }
                guard let request = try self?.createPostRequest(
                    url: url,
                    httpBody: ["json_files": jsonFilesChecksums]) else {
                        return
                }
                
                let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    if let error = error {
                        return completion(nil, error)
                    }
                    
                    guard let data = data else {
                        return completion(nil, DatabaseServerError.invalidURLTaskData)
                    }
                    
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                        return completion(nil, DatabaseServerError.httpStatusCode(httpStatus.statusCode))
                    }
                    
                    do {
                        let json = try JSON(data: data)
                        
                        if let jsonURL = json["json_url"].string,
                            let jsonFiles = json["json_files"].arrayObject as? [String] {
                            
                            if let url = URL(string: jsonURL) {
                                let fullpaths = jsonFiles.map({ url.appendingPathComponent($0) })
                                
                                return completion(fullpaths, nil)
                            }
                        }
                        
                        return completion([], nil)
                    } catch {
                        return completion(nil, error)
                    }
                }
                
                task.resume()
            } catch {
                completion(nil, error)
            }
        }
    }
}
