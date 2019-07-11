//
//  Indicators.swift
//  Binance+
//
//  Created by Behnam Karimi on 2/18/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import Foundation
import Darwin

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
    
    
    
    
    
    
    
}
