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
    var visibleCandles: [Candle] {
        get {
            return chart.visibleCandles
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
    
    var candleWidth: CGFloat {
        get {
            return chart.candleWidth
        }
    }
    
    
    var latestCandleX: CGFloat {
        get {
            return chart.latestX
        }
        set {
            chart.latestX = newValue
        }
    }
    
    
    
    //MARK: - Initialization
    init(chart: Chart) {
        self.chart = chart
        self.app = chart.app
        super.init(frame: .zero)
        
        backgroundColor = .clear
        clipsToBounds = true
        
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
        
        for candle in visibleCandles {
            let y = self.y(price: candle.high, frameHeight: frame.height, highestPrice: highestPrice, lowestPrice: lowestPrice)
            let h = self.y(price: candle.low, frameHeight: frame.height, highestPrice: highestPrice, lowestPrice: lowestPrice) - y
            
            draw(candle: candle, in: CGRect(x: candle.x, y: y, width: candleWidth, height: h), using: ctx)
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
    
    
    
    
    
    private func draw(candle: Candle, in rect: CGRect, using ctx: CGContext) {
        let candleWidth = rect.width * 3 / 4
        let candleHeight = rect.height
        
        let isGreen = (candle.close >= candle.open)
        let color: UIColor
        if isGreen {
            color = app.bullCandleColor
        } else {
            color = app.bearCandleColor
        }
        
        let wickWidth: CGFloat = 0.75
        
        
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
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.fill(CGRect(x: rect.origin.x + candleWidth / 2 - wickWidth / 2, y: rect.origin.y, width: wickWidth, height: upperWickHeight))
        ctx.fill(CGRect(x: rect.origin.x, y: rect.origin.y + upperWickHeight, width: candleWidth, height: bodyHeight))
        ctx.fill(CGRect(x: rect.origin.x + candleWidth / 2 - wickWidth / 2, y: rect.origin.y + upperWickHeight + bodyHeight, width: wickWidth, height: lowerWickHeight))
        
    }
    
    
    private func drawGridLines(using ctx: CGContext) {
        if chart.timeView == nil || chart.priceView == nil { return }
        ctx.setStrokeColor(UIColor.fromHex(hex: "#DFEAF0").withAlphaComponent(0.5).cgColor)
//        for candle in chart.timeView.gridCandles {
//            ctx.strokeLineSegments(between: [CGPoint(x: candle.x, y: 0), CGPoint(x: candle.x, y: frame.height)])
//        }
//        
//        for y in chart.priceView.tickYs {
//            ctx.strokeLineSegments(between: [CGPoint(x: 0, y: y), CGPoint(x: frame.width, y: y)])
//        }
    }


}
