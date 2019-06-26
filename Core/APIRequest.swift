//
//  APIRequest.swift
//  Core
//
//  Copyright © 2019 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

public protocol APIRequest {

    typealias Completion = ((Data?, HTTPURLResponse?, Error?) -> Void)
    
    func get(_ path: String, withParams params: [String: String]?, completion: @escaping APIRequest.Completion)
    
}

enum APIRequestErrors: Error {
    
    case noHttpResponse
    case invalidResponseCode(code: Int)
    
}

public class DefaultAPIRequest: APIRequest {
    
#if DEBUG
    let isDebugBuild = true
#else
    let isDebugBuild = false
#endif
    
    public init() { }
    
    public func get(_ path: String, withParams params: [String: String]?, completion: @escaping APIRequest.Completion) {
        var components = URLComponents(string: "https://duckduckgo.com")
        components?.path = path
        components?.queryItems = params?.map { URLQueryItem(name: $0.key, value: $0.value) }
        if isDebugBuild {
            var queryItems = components?.queryItems ?? []
            queryItems.append(URLQueryItem(name: "test", value: "1"))
            queryItems.append(URLQueryItem(name: "macos", value: "1"))
            components?.queryItems = queryItems
        }
        guard let url = components?.url else { return }
        
        var request = URLRequest(url: url)
        APIHeaders().addHeaders(to: &request)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                completion(nil, nil, error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(data, nil, APIRequestErrors.noHttpResponse)
                return
            }
            
            let statusCode = httpResponse.statusCode
            if statusCode < 200 || statusCode >= 300 {
                completion(data, httpResponse, APIRequestErrors.invalidResponseCode(code: statusCode))
                return
            }
            
            completion(data, httpResponse, nil)
        }
        task.resume()
    }
    
}

extension HTTPURLResponse {
    
    var etag: String? {
        return allHeaderFields[APIHeaders.Name.etag] as? String
    }
    
}