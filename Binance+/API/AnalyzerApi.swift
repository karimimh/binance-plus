//
//  AnalyzerApi.swift
//  Binance+
//
//  Created by Behnam Karimi on 5/8/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import Foundation

class AnalyzerAPI {
    static func get_rsi_divergence() {
        var url = URLComponents(string: "http://88.99.20.164:8088/btcusdt")!
        url.queryItems = [URLQueryItem(name: "timeframe", value: "1h")]
        let request = URLRequest(url: url.url!)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                return
            }
            guard let data = data else {
                return
            }
            let str = String(bytes: data, encoding: .utf8)
            print(str!)
            
        }
        task.resume()
    }
}
