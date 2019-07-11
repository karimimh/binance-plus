//
//  ScannerFilter.swift
//  Binance+
//
//  Created by Behnam Karimi on 2/17/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import Foundation

class ScannerFilter {
    var timeframe: Timeframe = .daily
    var type: FilterType
    var relationship: FilterRelationship = .greaterThan
    var rValue: Decimal = 0
    
    var properties: [String: Any] = [:]
    
    
    
    init(type: FilterType) {
        self.type = type
        
        switch type {
        case .volume24h:
            break
        case .price:
            break
        case .avg_volume:
            properties[Indicator.PropertyKey.length] = 20
        case .relative_volume:
            properties[Indicator.PropertyKey.length] = 20
            rValue = 1.0
        case .ema_difference:
            properties[Indicator.PropertyKey.fastLength] = 9
            properties[Indicator.PropertyKey.slowLength] = 20
        case .upper_boll_band_minus_candle_close:
            properties[Indicator.PropertyKey.fastLength] = 20
            properties[Indicator.PropertyKey.slowLength] = 2
        case .lower_boll_band_minus_candle_close:
            properties[Indicator.PropertyKey.fastLength] = 20
            properties[Indicator.PropertyKey.slowLength] = 2
        case .macd_bar:
            properties[Indicator.PropertyKey.fastLength] = 12
            properties[Indicator.PropertyKey.slowLength] = 26
            properties[Indicator.PropertyKey.signalSmoothingLength] = 9
        case .macd_line:
            properties[Indicator.PropertyKey.fastLength] = 12
            properties[Indicator.PropertyKey.slowLength] = 26
            properties[Indicator.PropertyKey.signalSmoothingLength] = 9
        case .macd_signal:
            properties[Indicator.PropertyKey.fastLength] = 12
            properties[Indicator.PropertyKey.slowLength] = 26
            properties[Indicator.PropertyKey.signalSmoothingLength] = 9
        case .rsi:
            properties[Indicator.PropertyKey.length] = 14
            relationship = .lessThan
            rValue = Decimal(30)
        case .green_candle:
            rValue = 0
        }
    }


    
    func toString() -> String {
        switch type {
        case .volume24h:
            return "24h_Volume \(relationship.toString()) \(rValue)"
        case .price:
            return "Latest_Price \(relationship.toString()) \(rValue)"
        case .avg_volume:
            return "Avg_Volume(\(properties[Indicator.PropertyKey.length] as! Int)) \(relationship.toString()) \(rValue) ; [\(timeframe.rawValue)]"
        case .relative_volume:
            return "Relative_Volume(\(properties[Indicator.PropertyKey.length] as! Int)) \(relationship.toString()) \(rValue) ; [\(timeframe.rawValue)]"
        case .ema_difference:
            return "EMA(\(properties[Indicator.PropertyKey.fastLength] as! Int)) - EMA(\(properties[Indicator.PropertyKey.slowLength] as! Int)) \(relationship.toString()) \(rValue) ; [\(timeframe.rawValue)]"
        case .upper_boll_band_minus_candle_close:
            return "UpperBOLL(\(properties[Indicator.PropertyKey.fastLength] as! Int), \(properties[Indicator.PropertyKey.slowLength] as! Int)) - Close \(relationship.toString()) \(rValue) ; [\(timeframe.rawValue)]"
        case .lower_boll_band_minus_candle_close:
            return "LowerBOLL(\(properties[Indicator.PropertyKey.fastLength] as! Int), \(properties[Indicator.PropertyKey.slowLength] as! Int)) - Close \(relationship.toString()) \(rValue) ; [\(timeframe.rawValue)]"
        case .macd_bar:
            return "MACD_Bar(\(properties[Indicator.PropertyKey.fastLength] as! Int), \(properties[Indicator.PropertyKey.slowLength] as! Int), \(properties[Indicator.PropertyKey.signalSmoothingLength] as! Int)) \(relationship.toString()) \(rValue) ; [\(timeframe.rawValue)]"
        case .macd_line:
            return "MACD_Line(\(properties[Indicator.PropertyKey.fastLength] as! Int), \(properties[Indicator.PropertyKey.slowLength] as! Int), \(properties[Indicator.PropertyKey.signalSmoothingLength] as! Int)) \(relationship.toString()) \(rValue) ; [\(timeframe.rawValue)]"
        case .macd_signal:
            return "MACD_Signal(\(properties[Indicator.PropertyKey.fastLength] as! Int), \(properties[Indicator.PropertyKey.slowLength] as! Int), \(properties[Indicator.PropertyKey.signalSmoothingLength] as! Int)) \(relationship.toString()) \(rValue) ; [\(timeframe.rawValue)]"
        case .rsi:
            return "RSI(\(properties[Indicator.PropertyKey.length] as! Int)) \(relationship.toString()) \(rValue) ; [\(timeframe.rawValue)]"
        case .green_candle:
            return "Close - Open \(relationship.toString()) \(rValue) ; [\(timeframe.rawValue)]"
        }
    }
    
    
    enum FilterType: String {
        case volume24h = "24 Hour Volume"
        case avg_volume = "Average Volume"
        case relative_volume = "Relative Volume"
        case price = "Latest Price"
        case rsi = "Relative Strength Index"
        case macd_bar = "MACD Bar"
        case macd_line = "MACD Line"
        case macd_signal = "MACD Signal"
        case upper_boll_band_minus_candle_close = "upperBollBand - closePrice"
        case lower_boll_band_minus_candle_close = "lowerBollBand - closePrice"
        case ema_difference = "EMA1 - EMA2"
        case green_candle = "Close - Open"
        
        static func allTypes() -> [String] {
            return ["24 Hour Volume", "Average Volume", "Relative Volume", "Latest Price", "Relative Strength Index", "MACD Bar", "MACD Line", "MACD Signal", "upperBollBand - closePrice", "lowerBollBand - closePrice", "EMA1 - EMA2", "Close - Open"]
        }
    }
    
    enum FilterRelationship: Int {
        case greaterThan
        case lessThan
        
        func toString() -> String {
            switch self {
            case .greaterThan:
                return ">"
            case .lessThan:
                return "<"
            }
        }
    }
}

