//
//  QuickChart.swift
//  Binance+
//
//  Created by Behnam Karimi on 2/22/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class QuickChart: UIView {
    
    //MARK: - Properties
    var app: App?
    
    //MARK: Fields
    var symbol: Symbol?
    var timeframe: Timeframe?
    var candles: [Candle]? {
        get {
            return symbol?.lastesThirtyDailyCandles
        }
    }
    var highestPrice: Decimal = -1
    var lowestPrice: Decimal = -1
    
    var candleWidth: CGFloat = 0

    
    
    //MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    //MARK: - Draw
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let candles = self.candles, let _ = self.app, let _ = self.symbol, let _ = self.timeframe else {
            return
        }
        if candles.isEmpty { print("Empty Canles for preview!"); return }
        self.highestPrice = self.highestPriceOf(candles)
        self.lowestPrice = self.lowestPriceOf(candles)
        candleWidth = (rect.width / 30) * 3 / 4
        
        let ctx = UIGraphicsGetCurrentContext()!
        for j in 0 ... (candles.count - 1) {
            let i = (candles.count - 1) - j
            let candle = candles[i]
            
            let x = frame.width - CGFloat(j + 1) * (candleWidth * 4 / 3)
            let y = self.y(price: candle.high, frameHeight: frame.height, highestPrice: highestPrice, lowestPrice: lowestPrice)
            let h = self.y(price: candle.low, frameHeight: frame.height, highestPrice: highestPrice, lowestPrice: lowestPrice) - y
            
            draw(candle: candle, in: CGRect(x: x, y: y, width: candleWidth, height: h), using: ctx)
        }
        
    }
    
    
    
    
    
    //MARK: - Private Methods
    
    private func y(price: Decimal, frameHeight: CGFloat, highestPrice: Decimal, lowestPrice: Decimal) -> CGFloat {
        let ratio = ((highestPrice - price) / (highestPrice - lowestPrice)).cgFloatValue
        return frameHeight * ratio
    }
    
    
    private func highestPriceOf(_ candles: [Candle]) -> Decimal {
        var highestPrice: Decimal = -1
        for i in 0..<candles.count {
            let candle = candles[i]
            if candle.high > highestPrice {
                highestPrice = candle.high
            }
        }
        return highestPrice
    }
    
    private func lowestPriceOf(_ candles: [Candle]) -> Decimal {
        var lowestPrice = highestPriceOf(candles)
        for i in 0..<candles.count {
            let candle = candles[i]
            if candle.low < lowestPrice {
                lowestPrice = candle.low
            }
        }
        return lowestPrice
    }
    
    
    private func draw(candle: Candle, in rect: CGRect, using ctx: CGContext) {
        let candleWidth = rect.width
        let candleHeight = rect.height
        
        let isGreen = (candle.close >= candle.open)
        let color: UIColor
        if isGreen {
            color = app!.bullCandleColor
        } else {
            color = app!.bearCandleColor
        }
        
        let wickWidth = candleWidth / 8
        
        
        var bodyHeight = ((candle.close - candle.open) / (candle.high - candle.low)).cgFloatValue * candleHeight
        if !isGreen {
            bodyHeight = -bodyHeight
        }
        if bodyHeight < wickWidth {
            bodyHeight = wickWidth
        }
        
        
        let upperWickHeight = ((candle.high - (isGreen ? candle.close : candle.open)) / (candle.high - candle.low)).cgFloatValue * candleHeight
        let lowerWickHeight = candleHeight - upperWickHeight - bodyHeight
        
        
        
        
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setLineWidth(0)
        ctx.setFillColor(color.cgColor)
        ctx.fill(CGRect(x: rect.origin.x + candleWidth / 2 - wickWidth / 2, y: rect.origin.y, width: wickWidth, height: upperWickHeight))
        ctx.fill(CGRect(x: rect.origin.x, y: rect.origin.y + upperWickHeight, width: candleWidth, height: bodyHeight))
        ctx.fill(CGRect(x: rect.origin.x + candleWidth / 2 - wickWidth / 2, y: rect.origin.y + upperWickHeight + bodyHeight, width: wickWidth, height: lowerWickHeight))
        
    }
}
