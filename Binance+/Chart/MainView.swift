//
//  MainView.swift
//  Binance+
//
//  Created by Behnam Karimi on 2/23/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class MainView: UIView {
    //MARK: - Properties
    var app: App
        
    var chart: Chart
    
    //MARK: Fields
    var symbol: Symbol {
        get {
            return chart.symbol
        }
    }
    var timeframe: Timeframe {
        get {
            return chart.timeframe
        }
    }
    var candles: [Candle] {
        get {
            return chart.candles
        }
    }
    var highestPrice: Decimal {
        get {
            return chart.highestPrice
        }
    }
    var lowestPrice: Decimal {
        get {
            return chart.lowestPrice
        }
    }
    var scrollDX: CGFloat = 0
    
    var candleWidth: CGFloat {
        get {
            return chart.candleWidth
        }
    }
    //touch handling properties
    var touchPreviousLocation = CGPoint.zero
    var latestCandleX: CGFloat {
        get {
            return app.chartLatestX
        }
        set {
            app.chartLatestX = newValue
        }
    }
    
    
    
    //MARK: - Initialization
    init(chart: Chart) {
        self.chart = chart
        self.app = chart.app
        super.init(frame: .zero)
        
        backgroundColor = .clear
        self.clipsToBounds = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //MARK: - Draw
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setLineWidth(2.0)
        ctx.strokeLineSegments(between: [CGPoint(x: 0, y: rect.height), CGPoint(x: rect.width, y: rect.height)])
        ctx.strokeLineSegments(between: [CGPoint(x: rect.width, y: 0), CGPoint(x: rect.width, y: rect.height)])
        ctx.setLineWidth(1.0)
        
        drawGridLines(using: ctx)
        for j in 0 ... (candles.count - 1) {
            let i = (candles.count - 1) - j
            let candle = candles[i]
            let y = self.y(price: candle.high, frameHeight: frame.height, highestPrice: highestPrice, lowestPrice: lowestPrice)
            let h = self.y(price: candle.low, frameHeight: frame.height, highestPrice: highestPrice, lowestPrice: lowestPrice) - y
            
            draw(candle: candle, in: CGRect(x: candle.x - candleWidth / 2, y: y, width: candleWidth, height: h), using: ctx)
        }

    }
    
    
    
    //MARK: - Update View
    func update() {
        setNeedsDisplay()
    }
    
    
    
    //MARK: - Private Methods
    
    private func y(price: Decimal, frameHeight: CGFloat, highestPrice: Decimal, lowestPrice: Decimal) -> CGFloat {
        let ratio = ((highestPrice - price) / (highestPrice - lowestPrice)).cgFloatValue
        return frameHeight * ratio 
    }
    
    
    
    
    
    func calculateVisibleCandles() -> [Candle] {
        var result = [Candle]()
        for candle in candles {
            if candle.x >= 0 && candle.x < bounds.width {
                result.append(candle)
            }
        }
        return result
    }
    
    private func draw(candle: Candle, in rect: CGRect, using ctx: CGContext) {
        let candleWidth = rect.width
        let candleHeight = rect.height
        
        let isGreen = (candle.close >= candle.open)
        let color: UIColor
        if isGreen {
            color = app.bullCandleColor
        } else {
            color = app.bearCandleColor
        }
        
        let wickWidth: CGFloat = 0.6
        
        
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
    
    
    private func drawGridLines(using ctx: CGContext) {
        if chart.timeView == nil || chart.priceView == nil { return }
        ctx.setStrokeColor(UIColor.fromHex(hex: "#DFEAF0").withAlphaComponent(0.5).cgColor)
        for candle in chart.timeView.gridCandles {
            ctx.strokeLineSegments(between: [CGPoint(x: candle.x, y: 0), CGPoint(x: candle.x, y: frame.height)])
        }
        
        for y in chart.priceView.tickYs {
            ctx.strokeLineSegments(between: [CGPoint(x: 0, y: y), CGPoint(x: frame.width, y: y)])
        }
    }


}
