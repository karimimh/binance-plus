//
//  Indicators.swift
//  Binance+
//
//  Created by Behnam Karimi on 2/18/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import Darwin
import UIKit

class Indicators {
    
    static func sma(data: [Decimal], length: Int) -> [Decimal] {
        var result = [Decimal]()
        if length > data.count {
            for _ in 0..<data.count {
                result.append(0)
            }
            return result
        }
        var sum: Decimal = 0
        for i in 0..<length-1 {
            result.append(0)
            sum += data[i]
        }
        sum += data[length - 1]
        result.append(sum / Decimal(length))
        
        for i in length ..< data.count {
            sum -= data[i - length]
            sum += data[i]
            result.append(sum / Decimal(length))
        }
        return result
    }
    
    
    static func ema(data: [Decimal], length: Int) -> [Decimal] {
        var result = [Decimal]()
        if length > data.count {
            for _ in 0..<data.count {
                result.append(0)
            }
            return result
        }
        var sum: Decimal = 0
        for i in 0..<length-1 {
            result.append(0)
            sum += data[i]
        }
        sum += data[length - 1]
        result.append(sum / Decimal(length))
        
        let multiplier: Double = (2.0 / (Double(length) + 1))
        for i in length ..< data.count {
            let r = result[i - 1] + Decimal(multiplier) * (data[i] - result[i - 1])
            result.append(r)
        }
        return result
    }
    
    
    private static func standardDeviation(data: [Decimal]) -> Double {
        var sum: Decimal = 0
        for d in data {
            sum += d
        }
        let mean = sum / Decimal(data.count)
        
        var s: Decimal = 0
        for d in data {
            s += ((d - mean) * (d - mean))
        }
        s = s / Decimal(data.count)
        
        return sqrt(s.doubleValue)
    }
    
    private static func std(data: [Decimal], length: Int) -> [Decimal] {
        var result = [Decimal]()
        
        if length > data.count {
            for _ in 0..<data.count {
                result.append(0)
            }
            return result
        }
        var pickedData = [Decimal]()
        for i in 0..<length-1 {
            result.append(0)
            pickedData.append(data[i])
        }
        pickedData.append(data[length - 1])
        result.append(Decimal(standardDeviation(data: pickedData)))
        
        for i in length ..< data.count {
            for j in 0..<length {
                pickedData[j] = data[j + i - length + 1]
            }
            result.append(Decimal(standardDeviation(data: pickedData)))
        }
        return result
    }
    
    
    static func rsi(data: [Decimal], length: Int) -> [Decimal] {
        var result = [Decimal]()
        if length > data.count {
            for _ in 0..<data.count {
                result.append(0)
            }
            return result
        }
        
        var adv = [Decimal]()
        var dec = [Decimal]()
        
        for i in 0..<length {
            let change = data[i + 1] - data[i]
            if change > 0 {
                adv.append(change)
                dec.append(0)
            } else {
                adv.append(0)
                dec.append(-change)
            }
            result.append(0)
        }
        var avgGain: Decimal = 0
        for a in adv {
            avgGain += a
        }
        avgGain /= Decimal(length)
        var avgLoss: Decimal = 0
        for d in dec {
            avgLoss += d
        }
        avgLoss /= Decimal(length)
        
        var rs = avgGain / avgLoss
        var rsi = 100 * rs / (1 + rs)
        result.append(rsi)
        
        for i in length ..< data.count - 1 {
            let change = data[i + 1] - data[i]
            let ad = (change > 0) ? change : 0
            let de = (change > 0) ? 0 : -change
            avgGain = (avgGain * Decimal(length - 1) + ad) / Decimal(length)
            avgLoss = (avgLoss * Decimal(length - 1) + de) / Decimal(length)
            rs = avgGain / avgLoss
            rsi = 100 * rs / (1 + rs)
            result.append(rsi)
        }
        return result
    }
    
    
    
    static func macd(data: [Decimal], fastLength: Int, slowLength: Int, signalSmoothingLength: Int) -> [(Decimal, Decimal)] {
        var macd = [Decimal]()
        let emaSlow = ema(data: data, length: slowLength)
        let emaFast = ema(data: data, length: fastLength)
        
        for i in 0..<data.count {
            macd.append(emaFast[i] - emaSlow[i])
        }
        
        var signal = ema(data: macd, length: signalSmoothingLength)
        
        var result = [(Decimal, Decimal)]()
        for i in 0 ..< data.count {
            result.append((macd[i], signal[i]))
        }
        return result
    }
    
    /// return order: (upper, middle, lower)
    static func bollinger_bands(data: [Decimal], length: Int, stdDev: Int) -> [(Decimal, Decimal, Decimal)] {
        var result = [(Decimal, Decimal, Decimal)] ()
        if length > data.count {
            for _ in 0..<data.count {
                result.append((0, 0, 0))
            }
            return result
        }
        let sma = self.sma(data: data, length: length)
        let std = self.std(data: data, length: length)
        
        for i in 0..<data.count {
            result.append((sma[i] + Decimal(stdDev) * std[i], sma[i], sma[i] - Decimal(stdDev) * std[i]))
        }
        return result
    }
    
    
    
    
    /// returns best fitting trend line
    static func findTrendPoints(candles: [Candle]) -> [(candleIndex: Int, price: Decimal)] {
        var result = [(candleIndex: Int, price: Decimal)]()
        
        if candles.count < 2 { return result }
        
        var isBullish = true
        if candles[1].high > candles[0].high {
            isBullish = true
        } else if candles[1].low < candles[0].low {
            isBullish = false
        } else if candles[1].close > candles[0].close {
            isBullish = true
        } else if candles[1].close < candles[0].close {
            isBullish = false
        } else if candles[0].isGreen() {
            isBullish = true
        } else {
            isBullish = false
        }

        result.append((0, candles[0].open))
        if isBullish {
            result.append((1, candles[1].high))
        } else {
            result.append((1, candles[1].low))
        }
        
        var i = 2
        while i < candles.count {
            let candle = candles[i]
            
            if isBullish {
                if candle.high > result.last!.price { // Trend Continuation
                    result.removeLast()
                    result.append((i, candle.high))
                } else if candle.close < candles[result.last!.candleIndex].open { // Trend Reversal
                    isBullish = false
                    result.append((i, candle.low))
                }
            } else {// isBearish
                if candle.low < result.last!.price { // Trend Continuation
                    result.removeLast()
                    result.append((i, candle.low))
                } else if candle.close > candles[result.last!.candleIndex].open { // Trend Reversal
                    isBullish = true
                    result.append((i, candle.high))
                }
            }
            
            i += 1
        }
        if result.last!.candleIndex != candles.count - 1 {
            result.append((candleIndex: candles.count - 1, price: candles.last!.close))
        }
        return result
    }
    
    
    
    static func mergeSmallTrendLines(points: [(candleIndex: Int, price: Decimal)]) -> [(candleIndex: Int, price: Decimal)] {
        if points.count < 3 { return points }
        var result = [(candleIndex: Int, price: Decimal)]()
        
        var trendLines = [TrendLine]()
        for i in 1..<points.count {
            trendLines.append(TrendLine(initialPoint: points[i - 1], endPoint: points[i]))
        }
        result.append(points[0])
        result.append(points[1])
        result.append(points[2])
        
        if trendLines.count <= 2 { return result }
        
        var isBullish = trendLines[1].endPoint.price > trendLines[0].initialPoint.price
        
        var i = 2
        while i < trendLines.count {
            if isBullish {
                if trendLines[i].isBearish() {
                    if trendLines[i].endPoint.price < trendLines[i - 1].initialPoint.price {
                        isBullish = false
                        result.append(trendLines[i].endPoint)
                    }
                } else {
                    if trendLines[i].endPoint.price < trendLines[i - 1].initialPoint.price {
                        isBullish = false
                        result.append(trendLines[i].initialPoint)
                    } else {
                        result.removeLast()
                        result.append(trendLines[i].endPoint)
                    }
                }
            } else { // isBearish:
                if trendLines[i].isBullish() {
                    if trendLines[i].endPoint.price > trendLines[i - 1].initialPoint.price {
                        isBullish = true
                        result.append(trendLines[i].endPoint)
                    }
                } else {
                    if trendLines[i].endPoint.price > trendLines[i - 1].initialPoint.price {
                        isBullish = true
                        result.append(trendLines[i].initialPoint)
                    } else {
                        result.removeLast()
                        result.append(trendLines[i].endPoint)
                    }
                }
            }
            
            i += 1
        }
        return result
    }
    
    
    static func findBestFittingLineEndPoint(points: [CGPoint]) -> CGPoint {
        let xs = points.map { (point) -> CGFloat in
            return point.x
        }
        let ys = points.map { (point) -> CGFloat in
            return point.y
        }
        let X = xs.reduce(0) { r, x in
            r + x
        } / CGFloat(xs.count)
        let Y = ys.reduce(0) { r, y in
            r + y
        } / CGFloat(ys.count)
        
        var numSum: CGFloat = 0
        var denumSum: CGFloat = 0
        for i in 0..<points.count {
            numSum += (xs[i] - X) * (ys[i] - Y)
            denumSum += (xs[i] - X) * (xs[i] - X)
        }
        
        let m = numSum / denumSum
        let y0 = Y - m * X
        
        let endX = points.last!.y
        let endY = m * endX + y0
        
        return CGPoint(x: endX, y: endY)
    }
    
    
    static func findTrendPoints2(candles: [Candle]) -> [(candleIndex: Int, price: Decimal)] {
        var result = [(candleIndex: Int, price: Decimal)]()
        
        if candles.count < 2 { return result }
        
        var isBullish = true
        if candles[1].close >= candles[0].open {
            isBullish = true
        } else {
            isBullish = false
        }
        
        result.append((0, candles[0].open))
        result.append((1, candles[1].close))
        
        var i = 2
        while i < candles.count {
            let candle = candles[i]
            let latestTrendPointCandle = candles[result.last!.candleIndex]
            
            if isBullish {
                if candle.close > latestTrendPointCandle.close { // Trend Continuation
                    result.removeLast()
                    result.append((i, candle.high))
                } else if candle.close < latestTrendPointCandle.open { // Trend Reversal
                    isBullish = false
                    result.append((i, candle.low))
                }
            } else {// isBearish
                if candle.close < latestTrendPointCandle.close { // Trend Continuation
                    result.removeLast()
                    result.append((i, candle.low))
                } else if candle.close > latestTrendPointCandle.open { // Trend Reversal
                    isBullish = true
                    result.append((i, candle.high))
                }
            }
            
            i += 1
        }
        if result.last!.candleIndex != candles.count - 1 {
            result.append((candleIndex: candles.count - 1, price: candles.last!.close))
        }
        return result
    }
    
}

class TrendLine {
    var initialPoint: (candleIndex: Int, price: Decimal)
    var endPoint: (candleIndex: Int, price: Decimal)
    init(initialPoint: (Int, Decimal), endPoint: (Int, Decimal)) {
        self.initialPoint = initialPoint
        self.endPoint = endPoint
    }
    func isBullish() -> Bool {
        return endPoint.price >= initialPoint.price
    }
    func isBearish() -> Bool {
        return !isBullish()
    }
}
