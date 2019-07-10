//
//  BinanceApi.swift
//  Binance+
//
//  Created by Behnam Karimi on 12/21/1397 AP.
//  Copyright © 1397 AP Behnam Karimi. All rights reserved.
//

import Foundation
import Network

class BinanaceApi {
    
    
    static func connect(completion: @escaping (Bool) -> Void) {
        let url = URL(string: "https://api.binance.com/api/v1/ping")!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard error == nil else {
                completion(false)
                return
            }
            
            guard let data = data else {
                completion(false)
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if json.isEmpty {
                        completion(true)
                    } else {
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            } catch {
                completion(false)
            }
            
        }
        task.resume()
    }
    
    static func getServerTime(completion: @escaping (Date?) -> Void) {
        let url = URL(string: "https://api.binance.com/api/v1/time")!
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
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if json.keys.contains("serverTime") {
                        let time = json["serverTime"] as! Double
                        let date = Date(timeIntervalSince1970: time)
                        completion(date)
                        return
                    } else {
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
            
        }
        task.resume()
    }
    
    
    static func getExchangeInfo(completion: @escaping ([String: Any]?) -> Void) {
        let url = URL(string: "https://api.binance.com/api/v1/exchangeInfo")!
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
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
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
    
    static func getCandles(symbol: Symbol, timeframe: Timeframe, startTime: Int64 = -1, endTime: Int64 = -1, limit: Int = -1, completion: @escaping ([Candle]?) -> Void) {
        var candles = [Candle]()
        var url = URLComponents(string: "https://api.binance.com/api/v1/klines")!
        url.queryItems = [URLQueryItem(name: "symbol", value: symbol.name),
                           URLQueryItem(name: "interval", value: timeframe.rawValue)]
        if startTime != -1 || endTime != -1 {
            url.queryItems?.append(URLQueryItem(name: "startTime", value: String(startTime)))
            url.queryItems?.append(URLQueryItem(name: "endTime", value: String(endTime)))
        }
        if limit != -1 {
            url.queryItems?.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        let request = URLRequest(url: url.url!)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print(error!)
                completion(nil)
                return
            }
            guard let data = data else {
                completion(nil)
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[Any]] {
                    //we got the data here
                    for array in json {
                        let openTime = array[0] as! Int64
                        let open = Decimal(string: array[1] as! String)!
                        let high = Decimal(string: array[2]  as! String)!
                        let low = Decimal(string: array[3] as! String)!
                        let close  = Decimal(string: array[4] as! String)!
                        let volume = Decimal(string: array[5] as! String)!
                        let closeTime = array[6] as! Int64
                        let quoteAssetVolume = Decimal(string: array[7] as! String)!
                        let numberOfTrades = array[8] as! Int64
                        let takerBuyBaseAssetVolume = Decimal(string: array[9] as! String)!
                        let takerBuyQuoteAssetVolume = Decimal(string: array[10] as! String)!
                        let candle = Candle(symbol: symbol, timeframe: timeframe, open: open, high: high, low: low, close: close, volume: volume, openTime: Date(timeIntervalSince1970: TimeInterval(openTime) / 1000), closeTime: Date(timeIntervalSince1970: TimeInterval(closeTime) / 1000), quoteAssetVolume: quoteAssetVolume, numberOfTrades: numberOfTrades, takerBuyBaseAssetVolume: takerBuyBaseAssetVolume, takerBuyQuoteAssetVolume: takerBuyQuoteAssetVolume)
                        candles.append(candle)
                    }
                    completion(candles)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
            
        }
        task.resume()
        
    }
    
    
    static func getCandlesForSymbols(_ symbols: [Symbol], timeframe: Timeframe, startTime: Int64 = -1, endTime: Int64 = -1, limit: Int = -1, completion: @escaping ([String: [Candle]]) -> Void) {
        
        let group = DispatchGroup()
        
        var result = [String: [Candle]]()
        for i in 0 ..< symbols.count {
            let symbol = symbols[i]
            group.enter()
            getCandles(symbol: symbol, timeframe: timeframe, startTime: startTime, endTime: endTime, limit: limit, completion: { (optionalCandles) in
                if let candles = optionalCandles {
                    result[symbol.name] = candles
                } else {
                    result[symbol.name] = []
                }
                group.leave()
            })
            
        }
        group.notify(queue: .main) {
            completion(result)
        }
        
    }
    
    
    
    
    static func getLatestCandle(symbol: Symbol, timeframe: Timeframe, completion: @escaping (Candle?) -> Void) {
        getCandles(symbol: symbol, timeframe: timeframe, limit: 1) { (optionalCandles) in
            completion(optionalCandles?.last)
        }
    }
    
    
    
    static func allMarketMiniTickersStream(completion: @escaping ([[String: Any]]?) -> Void) {
        let url = "wss://stream.binance.com:9443/ws/!miniTicker@arr"
        let webSocket = WebSocket(url)
        webSocket.event.message = { msg in
            guard let message = msg as? String  else {
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: message.data(using: .utf8)!, options: []) as? [[String: Any]] {
                    completion(json)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }
        
    }
    
    
    static func symbolMiniTickerStream(symbol: Symbol, completion: @escaping ([String: Any]?) -> Void) {
        let url = "wss://stream.binance.com:9443/ws/" + symbol.name + "@miniTicker"
        let webSocket = WebSocket(url)
        webSocket.event.message = { msg in
            guard let message = msg as? String  else {
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: message.data(using: .utf8)!, options: []) as? [String: Any] {
                    completion(json)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }
    }
    
    /// something like miniTicker but restful
    static func get24HPriceChagneStatistics(symbol: Symbol, completion: @escaping ([String: Any]?) -> Void) {
        var url = URLComponents(string: "https://api.binance.com/api/v1/ticker/24hr")!
        url.queryItems = [URLQueryItem(name: "symbol", value: symbol.name)]
        let request = URLRequest(url: url.url!)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                completion(nil)
                return
            }
            guard let data = data else {
                completion(nil)
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
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
    
    /// all minitickers restful
    static func all24HPriceChagneStatistics(completion: @escaping ([[String: Any]]?) -> Void) {
        let url = URLComponents(string: "https://api.binance.com/api/v1/ticker/24hr")!
        let request = URLRequest(url: url.url!)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
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
    
    
    static func currentAvgPrice(for symbol: String, completion: @escaping (Decimal?) -> Void) {
        var url = URLComponents(string: "https://api.binance.com/api/v3/avgPrice")!
        url.queryItems = [URLQueryItem(name: "symbol", value: symbol)]
        let request = URLRequest(url: url.url!)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                completion(nil)
                return
            }
            guard let data = data else {
                completion(nil)
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let p = json["price"] as? Decimal
                    completion(p)
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
