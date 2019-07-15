//
//  Indicator.swift
//  Binance+
//
//  Created by Behnam Karimi on 2/19/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import os.log
import Foundation
import UIKit

class Indicator: NSObject, NSCoding {
    
    var indicatorType: Indicator.IndicatorType
    var properties = [String: Any]()
    var frameRow: Int = 0
    var frameHeightPercentage: Double
    var app: App? {
        let delegate = UIApplication.shared.delegate as? AppDelegate
        return delegate?.app
    }

    var indicatorValue = [Date: Any]()//(OPEN, VALUE)
    
    private struct Key {
        static let indicatorType = "indicatorType"
        static let properties = "properties"
        static let frameRow = "frameRow"
        static let frameHeightPercentage = "frameHeightPercentage"
    }
    
    init(indicatorType: Indicator.IndicatorType, properties: [String: Any], frameRow: Int, frameHeightPercentage: Double) {
        self.indicatorType = indicatorType
        
        //Set Default Properties:
        switch indicatorType {
        case .volume:
            self.properties = [PropertyKey.length: 8, PropertyKey.color_1: UIColor.fromHex(hex: "#caf8fc"), PropertyKey.color_2: UIColor.blue.withAlphaComponent(0.3), PropertyKey.line_width_1: CGFloat(1)]
        case .sma:
            self.properties = [PropertyKey.source: "Close", PropertyKey.length: 8, PropertyKey.color_1: UIColor.blue.withAlphaComponent(0.5), PropertyKey.line_width_1: CGFloat(1)]
        case .ema:
            self.properties = [PropertyKey.source: "Close", PropertyKey.length: 8, PropertyKey.color_1: UIColor.blue.withAlphaComponent(0.5), PropertyKey.line_width_1: CGFloat(1)]
        case .rsi:
            self.properties = [PropertyKey.source: "Close", PropertyKey.length: 14, PropertyKey.color_1: UIColor.blue.withAlphaComponent(0.5), PropertyKey.line_width_1: CGFloat(1)]
        case .macd:
            self.properties = [PropertyKey.source: "Close", PropertyKey.fastLength: 12, PropertyKey.slowLength: 26, PropertyKey.signalSmoothingLength: 9, PropertyKey.color_1: UIColor.blue, PropertyKey.color_2: UIColor.red, PropertyKey.line_width_1: CGFloat(1), PropertyKey.line_width_2: CGFloat(1), PropertyKey.color_3: UIColor.green, PropertyKey.color_4: UIColor.red]
        case .bollinger_bands:
            self.properties = [PropertyKey.source: "Close", PropertyKey.fastLength: 20, PropertyKey.slowLength: 2, PropertyKey.showMiddleBand: false, PropertyKey.color_1: UIColor.gray, PropertyKey.line_width_1: CGFloat(1)]
        }
        for (key, value) in properties {
            self.properties[key] = value
        }
        
        self.frameRow = frameRow
        self.frameHeightPercentage = frameHeightPercentage
        super.init()
        
    }
    
    
    
    func calculateIndicatorValue(candles: [Candle]) {
        indicatorValue.removeAll()
        switch indicatorType {
        case .volume:
            var data = [Decimal]()
            for candle in candles {
                let v = app!.getVolumeInBTC(symbol: app!.getSymbol(app!.chartSymbol)!, baseVolume: candle.volume)
                data.append(v)
            }
            let smaLength = properties[PropertyKey.length] as! Int
            let sma = Indicators.sma(data: data, length: smaLength)
            for i in 0 ..< data.count {
                indicatorValue[candles[i].openTime] = (data[i], sma[i])
            }
        case .sma:
            var data = [Decimal]()
            let source = properties[PropertyKey.source] as! String
            for candle in candles {
                if source == "Open" {
                    data.append(candle.open)
                } else if source == "Low" {
                    data.append(candle.low)
                } else if source == "High" {
                    data.append(candle.high)
                } else {
                    data.append(candle.close)
                }
            }
            let smaLength = properties[PropertyKey.length] as! Int
            let sma = Indicators.sma(data: data, length: smaLength)
            for i in 0 ..< data.count {
                indicatorValue[candles[i].openTime] = sma[i]
            }
        case .ema:
            var data = [Decimal]()
            let source = properties[PropertyKey.source] as! String
            for candle in candles {
                if source == "Open" {
                    data.append(candle.open)
                } else if source == "Low" {
                    data.append(candle.low)
                } else if source == "High" {
                    data.append(candle.high)
                } else {
                    data.append(candle.close)
                }
            }
            let emaLength = properties[PropertyKey.length] as! Int
            let ema = Indicators.ema(data: data, length: emaLength)
            for i in 0 ..< data.count {
                indicatorValue[candles[i].openTime] = ema[i]
            }
        case .rsi:
            var data = [Decimal]()
            let source = properties[PropertyKey.source] as! String
            for candle in candles {
                if source == "Open" {
                    data.append(candle.open)
                } else if source == "Low" {
                    data.append(candle.low)
                } else if source == "High" {
                    data.append(candle.high)
                } else {
                    data.append(candle.close)
                }
            }
            let length = properties[PropertyKey.length] as! Int
            let rsi = Indicators.rsi(data: data, length: length)
            for i in 0 ..< rsi.count {
                indicatorValue[candles[i].openTime] = rsi[i]
            }
        case .macd:
            var data = [Decimal]()
            let source = properties[PropertyKey.source] as! String
            for candle in candles {
                if source == "Open" {
                    data.append(candle.open)
                } else if source == "Low" {
                    data.append(candle.low)
                } else if source == "High" {
                    data.append(candle.high)
                } else {
                    data.append(candle.close)
                }
            }
            let fastLength = properties[PropertyKey.fastLength] as! Int
            let slowLength = properties[PropertyKey.slowLength] as! Int
            let signalSmoothingLength = properties[Indicator.PropertyKey.signalSmoothingLength] as! Int
            let macd = Indicators.macd(data: data, fastLength: fastLength, slowLength: slowLength, signalSmoothingLength: signalSmoothingLength)
            for i in 0 ..< macd.count {
                indicatorValue[candles[i].openTime] = macd[i]
            }
        case .bollinger_bands:
            var data = [Decimal]()
            let source = properties[PropertyKey.source] as! String
            for candle in candles {
                if source == "Open" {
                    data.append(candle.open)
                } else if source == "Low" {
                    data.append(candle.low)
                } else if source == "High" {
                    data.append(candle.high)
                } else {
                    data.append(candle.close)
                }
            }
            let fastLength = properties[PropertyKey.fastLength] as! Int
            let slowLength = properties[PropertyKey.slowLength] as! Int
            let bb = Indicators.bollinger_bands(data: data, length: fastLength, stdDev: slowLength)
            for i in 0 ..< bb.count {
                indicatorValue[candles[i].openTime] = bb[i]
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(indicatorType.rawValue, forKey: Key.indicatorType)
        aCoder.encode(properties, forKey: Key.properties)
        aCoder.encode(frameRow, forKey: Key.frameRow)
        aCoder.encode(frameHeightPercentage, forKey: Key.frameHeightPercentage)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let indicatorType = aDecoder.decodeObject(forKey: Key.indicatorType) as? String else {
            os_log("Unable to decode the indicatorType for a Indicator object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let properties = aDecoder.decodeObject(forKey: Key.properties) as? [String: Any] else {
            os_log("Unable to decode the properties for a Indicator object.", log: OSLog.default, type: .debug)
            return nil
        }
        let frameRow = aDecoder.decodeInteger(forKey: Key.frameRow)
        let frameHeightPercentage = aDecoder.decodeDouble(forKey: Key.frameHeightPercentage)
        self.init(indicatorType: Indicator.IndicatorType(rawValue: indicatorType)!, properties: properties, frameRow: frameRow, frameHeightPercentage: frameHeightPercentage)
    }
    
    
    
    
    func getNameInFunctionForm() -> String {
        switch indicatorType {
        case .volume:
            return "Volume(\(properties[PropertyKey.length] as! Int))"
        case .sma:
            return "SMA(\(properties[PropertyKey.length] as! Int))"
        case .ema:
            return "EMA(\(properties[PropertyKey.length] as! Int))"
        case .rsi:
            return "RSI(\(properties[PropertyKey.length] as! Int))"
        case .macd:
            return "MACD(\(properties[PropertyKey.fastLength] as! Int), \(properties[PropertyKey.slowLength] as! Int))"
        case .bollinger_bands:
            return "BOLL(\(properties[PropertyKey.fastLength] as! Int), \(properties[PropertyKey.slowLength] as! Int))"
        }
    }
    
    func getColor() -> UIColor {
        return properties[PropertyKey.color_1] as! UIColor
    }
    
    //MARK: - Types
    
    enum IndicatorType: String {
        case volume
        case sma
        case ema
        case rsi
        case macd
        case bollinger_bands
    }
    
    struct PropertyKey: Hashable {
        static let length = "length"
        static let fastLength = "fastLength"
        static let slowLength = "slowLength"
        static let signalSmoothingLength = "signalSmoothingLength"
        static let source = "source"
        static let showMiddleBand = "showMiddleBand"
        
        static let color_1 = "color_1"
        static let line_width_1 = "line_width_1"
        static let color_2 = "color_2"
        static let line_width_2 = "line_width_2"
        static let color_3 = "color_3"
        static let line_width_3 = "line_width_3"
        static let color_4 = "color_4"
        
        static let bullishOrBearish = "bullish/bearish"
    }
}

