//
//  BitmexApi.swift
//  Binance+
//
//  Created by Behnam Karimi on 5/5/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import Foundation

class BitmexAPI: NSObject {
    static let baseURL = "https://www.bitmex.com/api/v1"
    
    static func getActiveInstruments(completion: @escaping ([[String: Any]]?) -> Void) {
        let url = URL(string: baseURL + "/instrument/active")!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard error == nil else {
                completion(nil)
                return
            }
            guard let data = data else {
                completion(nil)
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    completion(json)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
            
        }
        task.resume()
    }
    
}
