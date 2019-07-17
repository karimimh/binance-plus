//
//  Candle.swift
//  Binance+
//
//  Created by Behnam Karimi on 12/22/1397 AP.
//  Copyright © 1397 AP Behnam Karimi. All rights reserved.
//

import Foundation
import UIKit
import os.log


class Candle: Equatable, NSCoding {
    
    var symbol: Symbol
    var timeframe: Timeframe
    var open, close, high, low: Decimal
    var volume: Decimal
    var openTime, closeTime: Date
    var quoteAssetVolume: Decimal
    var numberOfTrades: Int64
    var takerBuyBaseAssetVolume: Decimal
    var takerBuyQuoteAssetVolume: Decimal
    
    //For chart
    var x: CGFloat = 0

    init(symbol: Symbol, timeframe: Timeframe, open: Decimal, high: Decimal, low: Decimal, close: Decimal, volume: Decimal, openTime: Date, closeTime: Date, quoteAssetVolume: Decimal, numberOfTrades: Int64, takerBuyBaseAssetVolume: Decimal, takerBuyQuoteAssetVolume: Decimal) {
        self.symbol = symbol
        self.timeframe = timeframe
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
        self.openTime = openTime.localToUTC()
        self.closeTime = closeTime.localToUTC()
        self.quoteAssetVolume = quoteAssetVolume
        self.numberOfTrades = numberOfTrades
        self.takerBuyBaseAssetVolume = takerBuyBaseAssetVolume
        self.takerBuyQuoteAssetVolume = takerBuyQuoteAssetVolume
    }
    
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(symbol, forKey: Key.symbol)
        aCoder.encode(timeframe.rawValue, forKey: Key.timeframe)
        aCoder.encode(open, forKey: Key.open)
        aCoder.encode(close, forKey: Key.close)
        aCoder.encode(high, forKey: Key.high)
        aCoder.encode(low, forKey: Key.low)
        aCoder.encode(volume, forKey: Key.volume)
        aCoder.encode(openTime, forKey: Key.openTime)
        aCoder.encode(closeTime, forKey: Key.closeTime)
        aCoder.encode(quoteAssetVolume, forKey: Key.quoteAssetVolume)
        aCoder.encode(numberOfTrades, forKey: Key.numberOfTrades)
        aCoder.encode(takerBuyBaseAssetVolume, forKey: Key.takerBuyBaseAssetVolume)
        aCoder.encode(takerBuyQuoteAssetVolume, forKey: Key.takerBuyQuoteAssetVolume)
        aCoder.encode(x, forKey: Key.x)
        
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let symbol = aDecoder.decodeObject(forKey: Key.symbol) as? Symbol else {
            os_log("Unable to decode the symbol for a Candle object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let timeframe = aDecoder.decodeObject(forKey: Key.timeframe) as? String else {
            os_log("Unable to decode the timeframe for a Candle object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let open = aDecoder.decodeObject(forKey: Key.open) as? Decimal else {
            os_log("Unable to decode the open for a Candle object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let close = aDecoder.decodeObject(forKey: Key.close) as? Decimal else {
            os_log("Unable to decode the close for a Candle object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let high = aDecoder.decodeObject(forKey: Key.high) as? Decimal else {
            os_log("Unable to decode the high for a Candle object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let low = aDecoder.decodeObject(forKey: Key.low) as? Decimal else {
            os_log("Unable to decode the low for a Candle object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let volume = aDecoder.decodeObject(forKey: Key.volume) as? Decimal else {
            os_log("Unable to decode the volume for a Candle object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let openTime = aDecoder.decodeObject(forKey: Key.openTime) as? Date else {
            os_log("Unable to decode the openTime for a Candle object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let closeTime = aDecoder.decodeObject(forKey: Key.closeTime) as? Date else {
            os_log("Unable to decode the closeTime for a Candle object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let quoteAssetVolume = aDecoder.decodeObject(forKey: Key.quoteAssetVolume) as? Decimal else {
            os_log("Unable to decode the quoteAssetVolume for a Candle object.", log: OSLog.default, type: .debug)
            return nil
        }
        let numberOfTrades = aDecoder.decodeInt64(forKey: Key.numberOfTrades)
        guard let takerBuyBaseAssetVolume = aDecoder.decodeObject(forKey: Key.takerBuyBaseAssetVolume) as? Decimal else {
            os_log("Unable to decode the takerBuyBaseAssetVolume for a Candle object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let takerBuyQuoteAssetVolume = aDecoder.decodeObject(forKey: Key.takerBuyQuoteAssetVolume) as? Decimal else {
            os_log("Unable to decode the takerBuyQuoteAssetVolume for a Candle object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let x = aDecoder.decodeObject(forKey: Key.x) as? CGFloat else {
            os_log("Unable to decode the x for a Candle object.", log: OSLog.default, type: .debug)
            return nil
        }
        self.init(symbol: symbol, timeframe: Timeframe(rawValue: timeframe)!, open: open, high: high, low: low, close: close, volume: volume, openTime: openTime, closeTime: closeTime, quoteAssetVolume: quoteAssetVolume, numberOfTrades: numberOfTrades, takerBuyBaseAssetVolume: takerBuyBaseAssetVolume, takerBuyQuoteAssetVolume: takerBuyQuoteAssetVolume)
        self.x = x
    }
    
    static func == (lhs: Candle, rhs: Candle) -> Bool {
        return lhs.symbol == rhs.symbol && lhs.openTime == rhs.openTime && lhs.closeTime == rhs.closeTime && lhs.open == rhs.open && lhs.close == rhs.close && lhs.high == rhs.high && lhs.low == rhs.low
    }
    
    func isGreen() -> Bool {
        return close > open
    }
    
    func nextCandleOpenTime() -> Date {
        let calendar = Calendar.current
        
        switch timeframe {
        case .oneMinute:
            return calendar.date(byAdding: .minute, value: 1, to: openTime)!
        case .threeMinutes:
            return calendar.date(byAdding: .minute, value: 3, to: openTime)!
        case .fiveMinutes:
            return calendar.date(byAdding: .minute, value: 5, to: openTime)!
        case .fifteenMinutes:
            return calendar.date(byAdding: .minute, value: 15, to: openTime)!
        case .thirtyMinutes:
            return calendar.date(byAdding: .minute, value: 30, to: openTime)!
        case .hourly:
            return calendar.date(byAdding: .hour, value: 1, to: openTime)!
        case .twoHourly:
            return calendar.date(byAdding: .hour, value: 2, to: openTime)!
        case .fourHourly:
            return calendar.date(byAdding: .hour, value: 4, to: openTime)!
        case .sixHourly:
            return calendar.date(byAdding: .hour, value: 6, to: openTime)!
        case .eightHourly:
            return calendar.date(byAdding: .hour, value: 8, to: openTime)!
        case .twelveHourly:
            return calendar.date(byAdding: .hour, value: 12, to: openTime)!
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: openTime)!
        case .threeDaily:
            return calendar.date(byAdding: .day, value: 3, to: openTime)!
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: openTime)!
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: openTime)!
        }
    }
    
    func getColor(_ app: App) -> UIColor {
        return isGreen() ? app.bullCandleColor : app.bearCandleColor
    }
    
    struct Key {
        static let symbol = "candle.symbol"
        static let timeframe = "candle.timeframe"
        static let open = "candle.open"
        static let close = "candle.close"
        static let high = "candle.high"
        static let low = "candle.low"
        static let volume = "candle.volume"
        static let openTime = "candle.openTime"
        static let closeTime = "candle.closeTime"
        static let quoteAssetVolume = "candle.quoteAssetVolume"
        static let numberOfTrades = "candle.numberOfTrades"
        static let takerBuyBaseAssetVolume = "candle.takerBuyBaseAssetVolume"
        static let takerBuyQuoteAssetVolume = "candle.takerBuyQuoteAssetVolume"
        static let x = "candle.x"
    }
    
}






