//
//  Symbol.swift
//  Binance+
//
//  Created by Behnam Karimi on 12/21/1397 AP.
//  Copyright © 1397 AP Behnam Karimi. All rights reserved.
//

import UIKit
import os.log

class Symbol: NSObject, NSCoding {
    private var _price: Decimal
    private var _volume: Decimal
    
    
    let name: String
    var price: Decimal {
        set {
            if newValue != _price {
                self.tickerChanged = true
            }
            self._price = newValue
        }
        get {
            return _price
        }
    }
    var volume: Decimal {
        set {
            if newValue != _volume {
                self.tickerChanged = true
            }
            self._volume = newValue
        }
        get {
            return _volume
        }
    }
    var percentChange: Decimal
    var quoteAssetVolume: Decimal



    var status: String
    let baseAsset: String
    let quoteAsset: String
    var baseAssetPrecision: Int
    var quoteAssetPrecision: Int
    
    
    var tickSize: Decimal!
    var stepSize: Decimal!
    var minQuantity: Decimal!
    var minPrice: Decimal!
    
    
    //for tableView
    var lastesThirtyDailyCandles: [Candle]?
    var iconImage: UIImage?
    var tickerChanged = false
    
    init(name: String, status: String, baseAsset: String, baseAssetPrecision: Int, quoteAsset: String, quoteAssetPrecision: Int) {
        self.name = name
        _price = -1
        _volume = -1
        quoteAssetVolume = -1
        percentChange = -1
        
        self.status = status
        self.baseAsset = baseAsset
        self.baseAssetPrecision = baseAssetPrecision
        self.quoteAsset = quoteAsset
        self.quoteAssetPrecision = quoteAssetPrecision
    }
    
    init(name: String, status: String, baseAsset: String, baseAssetPrecision: Int, quoteAsset: String, quoteAssetPrecision: Int, price: Decimal, volume: Decimal, quoteAssetVolume: Decimal, percentChange: Decimal, tickSize: Decimal?, stepSize: Decimal?, minQuantity: Decimal?, minPrice: Decimal?) {
        self.name = name
        self._price = price
        self._volume = volume
        self.quoteAssetVolume = quoteAssetVolume
        self.percentChange = percentChange
        
        self.status = status
        self.baseAsset = baseAsset
        self.baseAssetPrecision = baseAssetPrecision
        self.quoteAsset = quoteAsset
        self.quoteAssetPrecision = quoteAssetPrecision
        
        self.tickSize = tickSize
        self.stepSize = stepSize
        self.minQuantity = minQuantity
        self.minPrice = minPrice
    }
    

    
    
    func priceDividedByTicksize(price: Decimal) -> Int {
        return Int((price / tickSize).doubleValue)
    }
    
    
    static func == (lhs: Symbol, rhs: Symbol) -> Bool {
        return lhs.name == rhs.name
    }
    
    
    
    struct Key {
        static let name = "symbol.name"
        static let status = "symbol.status"
        static let baseAsset = "symbol.baseAsset"
        static let baseAssetPrecision = "symbol.baseAssetPrecision"
        static let quoteAsset = "symbol.quoteAsset"
        static let quoteAssetPrecision = "symbol.quoteAssetPrecision"
        static let price = "symbol.price"
        static let volume = "symbol.volume"
        static let quoteAssetVolume = "symbol.quoteAssetVolume"
        static let percentChange = "symbol.percentChange"
        static let tickSize = "symbol.tickSize"
        static let stepSize = "symbol.stepSize"
        static let minQuantity = "symbol.minQuantity"
        static let minPrice = "symbol.minPrice"
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: Key.name)
        aCoder.encode(status, forKey: Key.status)
        aCoder.encode(baseAsset, forKey: Key.baseAsset)
        aCoder.encode(baseAssetPrecision, forKey: Key.baseAssetPrecision)
        aCoder.encode(quoteAsset, forKey: Key.quoteAsset)
        aCoder.encode(quoteAssetPrecision, forKey: Key.quoteAssetPrecision)
        aCoder.encode(_price, forKey: Key.price)
        aCoder.encode(_volume, forKey: Key.volume)
        aCoder.encode(quoteAssetVolume, forKey: Key.quoteAssetVolume)
        aCoder.encode(percentChange, forKey: Key.percentChange)
        aCoder.encode(tickSize, forKey: Key.tickSize)
        aCoder.encode(stepSize, forKey: Key.stepSize)
        aCoder.encode(minQuantity, forKey: Key.minQuantity)
        aCoder.encode(minPrice, forKey: Key.minPrice)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(forKey: Key.name) as? String else {
            os_log("Unable to decode the name for a Symbol object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let status = aDecoder.decodeObject(forKey: Key.status) as? String else {
            os_log("Unable to decode the status for a Symbol object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let baseAsset = aDecoder.decodeObject(forKey: Key.baseAsset) as? String else {
            os_log("Unable to decode the baseAsset for a Symbol object.", log: OSLog.default, type: .debug)
            return nil
        }
        let baseAssetPrecision = aDecoder.decodeInteger(forKey: Key.baseAssetPrecision)
        
        guard let quoteAsset = aDecoder.decodeObject(forKey: Key.quoteAsset) as? String else {
            os_log("Unable to decode the quoteAsset for a Symbol object.", log: OSLog.default, type: .debug)
            return nil
        }
        let quoteAssetPrecision = aDecoder.decodeInteger(forKey: Key.quoteAssetPrecision)
        
        guard let price = aDecoder.decodeObject(forKey: Key.price) as? Decimal else {
            os_log("Unable to decode the price for a Symbol object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let volume = aDecoder.decodeObject(forKey: Key.volume) as? Decimal else {
            os_log("Unable to decode the volume for a Symbol object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let quoteAssetVolume = aDecoder.decodeObject(forKey: Key.quoteAssetVolume) as? Decimal else {
            os_log("Unable to decode the quoteAssetVolume for a Symbol object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let percentChange = aDecoder.decodeObject(forKey: Key.percentChange) as? Decimal else {
            os_log("Unable to decode the percentChange for a Symbol object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        let tickSize = aDecoder.decodeObject(forKey: Key.price) as? Decimal
        
        let stepSize = aDecoder.decodeObject(forKey: Key.stepSize) as? Decimal
        
        let minQuantity = aDecoder.decodeObject(forKey: Key.minQuantity) as? Decimal
        
        let minPrice = aDecoder.decodeObject(forKey: Key.minPrice) as? Decimal
        
        
        
        
        self.init(name: name, status: status, baseAsset: baseAsset, baseAssetPrecision: baseAssetPrecision, quoteAsset: quoteAsset, quoteAssetPrecision: quoteAssetPrecision, price: price, volume: volume, quoteAssetVolume: quoteAssetVolume, percentChange: percentChange, tickSize: tickSize, stepSize: stepSize, minQuantity: minQuantity, minPrice: minPrice)
    }
    
    func priceTruncatedInTickSize(_ p: Decimal) -> Decimal {
        let n = Int((p / tickSize).doubleValue)
        return Decimal(n) * tickSize
    }
    
    
    func btcVolume(_ app: App!) -> Decimal {
        if quoteAsset == "BTC" {
             return quoteAssetVolume
        } else {
            return app.getVolumeInBTC(symbol: self, baseVolume: self.volume)
        }
    }
    
    func btcPrice(_ app: App!) -> Decimal {
        return app.getPriceInBTC(symbol: self)
    }
    
    func priceFormatted(_ p: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = tickSize.significantFractionalDecimalDigits
        formatter.numberStyle = .currency
        formatter.currencyGroupingSeparator = ""
        formatter.maximumFractionDigits = tickSize.significantFractionalDecimalDigits
        formatter.currencySymbol = ""
        let str = formatter.string(from: p as NSNumber)!
        return str
    }
    
    func volumeFormatted(_ v: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = stepSize.significantFractionalDecimalDigits
        formatter.numberStyle = .currency
        formatter.currencyGroupingSeparator = ""
        formatter.maximumFractionDigits = stepSize.significantFractionalDecimalDigits
        formatter.currencySymbol = ""
        let str = formatter.string(from: v as NSNumber)!
        return str
    }
    
}
