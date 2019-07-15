//
//  IndicatorView.swift
//  Binance+
//
//  Created by Behnam Karimi on 2/12/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class IndicatorView: UIView {

    let chart: Chart
    //MARK: - Properties
    var indicatorType: Indicator.IndicatorType {
        get {
            return indicator.indicatorType
        }
    }
    var visibleCandles: [Candle] {
        get {
            return chart.visibleCandles
        }
    }
    var properties: [String: Any] {
        get {
            return indicator.properties
        }
    }
    var indicator: Indicator
    
    var valueView: ValueView
    
    var handleView: UIView!
    
    
    
    //MARK: - Initialization
    init(chart: Chart, indicator: Indicator) {
        self.chart = chart
        self.indicator = indicator
        
        switch indicator.indicatorType {
        case .ema, .sma, .bollinger_bands:
            valueView = chart.priceView
        case .volume:
            var highestVolume: Decimal = 0
            for candle in chart.candles {
                if chart.app.getVolumeInBTC(symbol: chart.symbol, baseVolume: candle.volume) > highestVolume {
                    highestVolume = chart.app.getVolumeInBTC(symbol: chart.symbol, baseVolume: candle.volume)
                }
            }
            valueView = ValueView(chart: chart, tickSize: chart.symbol.stepSize, highestValue: highestVolume * 1.2, lowestValue: 0, precision: chart.symbol.stepSize.significantFractionalDecimalDigits)
        case .rsi:
            valueView = ValueView(chart: chart, tickSize: -1.0, highestValue: 100, lowestValue: 0, requiredTickPrices: [30, 70], precision: 2)
        case .macd:
            valueView = ValueView(chart: chart, tickSize: -1.0, highestValue: 100, lowestValue: 0, requiredTickPrices: [0], precision: chart.symbol.tickSize.significantFractionalDecimalDigits)
        }
        
        super.init(frame: .zero)
        
        if indicator.frameRow == 0 {
            isUserInteractionEnabled = false
        }
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
        switch indicatorType {
        case .volume:
            drawVolume(in: rect, using: ctx)
        case .sma:
            drawSMA(in: rect, using: ctx)
        case .ema:
            drawEMA(in: rect, using: ctx)
        case .rsi:
            drawRSI(in: rect, using: ctx)
        case .macd:
            drawMACD(in: rect, using: ctx)
        case .bollinger_bands:
            drawBollingerBands(in: rect, using: ctx)
        }
        ctx.setStrokeColor(UIColor.black.cgColor)
        ctx.setLineWidth(2.0)
        ctx.strokeLineSegments(between: [CGPoint(x: 0, y: rect.height), CGPoint(x: rect.width, y: rect.height)])
        ctx.strokeLineSegments(between: [CGPoint(x: rect.width, y: 0), CGPoint(x: rect.width, y: rect.height)])
        
    }
    
    func update() {
        setNeedsDisplay()
        if indicator.frameRow > 0 {
            valueView.setNeedsDisplay()
        }
    }

    
    
    
    
    
    //MARK: - Private Methods
    
    private func drawVolume(in rect: CGRect, using ctx: CGContext) {
        let visibleCandles = self.visibleCandles
        var highestVolume: Decimal = 0
        for candle in visibleCandles {
            if chart.app.getVolumeInBTC(symbol: chart.symbol, baseVolume: candle.volume) > highestVolume {
                highestVolume = chart.app.getVolumeInBTC(symbol: chart.symbol, baseVolume: candle.volume)
            }
        }
        highestVolume *= 1.2
        valueView.update(newhighestValue: highestVolume, newLowestValue: 0)
        if highestVolume == 0 {
            return
        }
        let color = properties[Indicator.PropertyKey.color_1] as! UIColor
        let smaColor = properties[Indicator.PropertyKey.color_2] as! UIColor
        let smaLineWidth = properties[Indicator.PropertyKey.line_width_1] as! CGFloat
        let smaLength = properties[Indicator.PropertyKey.length] as! Int
        
        if visibleCandles.isEmpty { return }
        
        var smaPoints = [CGPoint]()
        ctx.setFillColor(color.withAlphaComponent(0.5).cgColor)
        for i in 0..<visibleCandles.count {
            let candle = visibleCandles[i]
            let pair = indicator.indicatorValue[candle.openTime] as! (Decimal, Decimal)
            let volume = pair.0
            let sma = pair.1
            let height: CGFloat = (volume / highestVolume).cgFloatValue * frame.height
            ctx.fill(CGRect(x: candle.x, y: frame.height - height, width: chart.candleWidth * 2 / 3, height: height))
            
            let candleIndex =  i + chart.firstVisibleCandleIndex
            if candleIndex < smaLength { continue }
            smaPoints.append(CGPoint(x: candle.x, y: frame.height - (sma / highestVolume).cgFloatValue * frame.height))
        }
        
        if chart.candles.count < smaLength  || smaPoints.isEmpty { return }
        
        ctx.setStrokeColor(smaColor.cgColor)
        ctx.setLineWidth(smaLineWidth)
        ctx.setLineJoin(.round)
        ctx.beginPath()
        ctx.move(to: smaPoints[0])
        for i in 0 ..< smaPoints.count {
            ctx.addLine(to: smaPoints[i])
        }
        ctx.strokePath()
        
    }
    
    
    
    private func drawSMA(in rect: CGRect, using ctx: CGContext) {
        let visibleCandles = self.visibleCandles
        
        let length = properties[Indicator.PropertyKey.length] as! Int
        
        if length > chart.candles.count { return }
        if visibleCandles.isEmpty { return }
        
        var points = [CGPoint]()
        for i in 0..<visibleCandles.count {
            let candle = visibleCandles[i]
            let candleIndex =  i + chart.firstVisibleCandleIndex
            if candleIndex < length { continue }
            let sma = indicator.indicatorValue[candle.openTime] as! Decimal
            let point = CGPoint(x: candle.x, y: Util.y(price: sma, frameHeight: frame.height, highestPrice: chart.highestPrice, lowestPrice: chart.lowestPrice))
            points.append(point)
        }
        if points.isEmpty { return }
        let color = properties[Indicator.PropertyKey.color_1] as! UIColor
        
        let lineWidth = properties[Indicator.PropertyKey.line_width_1] as! CGFloat
        
        
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.setLineJoin(.round)
        ctx.beginPath()
        ctx.move(to: points[0])
        for i in 0 ..< points.count {
            ctx.addLine(to: points[i])
        }
        ctx.strokePath()
    }
    
    
    
    private func drawEMA(in rect: CGRect, using ctx: CGContext) {
        let visibleCandles = self.visibleCandles
        
        let length = properties[Indicator.PropertyKey.length] as! Int
        
        if length > chart.candles.count { return }
        if visibleCandles.isEmpty { return }
        
        var points = [CGPoint]()
        for i in 0..<visibleCandles.count {
            let candle = visibleCandles[i]
            let candleIndex =  i + chart.firstVisibleCandleIndex
            if candleIndex < length { continue }
            let ema = indicator.indicatorValue[candle.openTime] as! Decimal
            let point = CGPoint(x: candle.x, y: Util.y(price: ema, frameHeight: frame.height, highestPrice: chart.highestPrice, lowestPrice: chart.lowestPrice))
            points.append(point)
        }
        if points.isEmpty { return }
        let color = properties[Indicator.PropertyKey.color_1] as! UIColor
        
        let lineWidth = properties[Indicator.PropertyKey.line_width_1] as! CGFloat
        
        
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.setLineJoin(.round)
        ctx.beginPath()
        ctx.move(to: points[0])
        for i in 0 ..< points.count {
            ctx.addLine(to: points[i])
        }
        ctx.strokePath()
    }
    
    
    
    
    
    private func drawRSI(in rect: CGRect, using ctx: CGContext) {
        let visibleCandles = self.visibleCandles
        
        let length = properties[Indicator.PropertyKey.length] as! Int
        
        if length > chart.candles.count { return }
        if visibleCandles.isEmpty { return }
        
        var points = [CGPoint]()
        for i in 0..<visibleCandles.count {
            let candle = visibleCandles[i]
            let candleIndex =  i + chart.firstVisibleCandleIndex
            if candleIndex < length { continue }
            let rsi = indicator.indicatorValue[candle.openTime] as! Decimal
            let point = CGPoint(x: candle.x, y: Util.y(price: rsi, frameHeight: frame.height, highestPrice: 100, lowestPrice: 0))
            points.append(point)
        }
        if points.isEmpty { return }
        let color = properties[Indicator.PropertyKey.color_1] as! UIColor
        
        let lineWidth = properties[Indicator.PropertyKey.line_width_1] as! CGFloat
        
        
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.setLineJoin(.round)
        ctx.beginPath()
        ctx.move(to: points[0])
        for i in 0 ..< points.count {
            ctx.addLine(to: points[i])
        }
        ctx.strokePath()
    }
    
    
    private func drawMACD(in rect: CGRect, using ctx: CGContext) {
        let visibleCandles = self.visibleCandles
        
        
        let slowLength = properties[Indicator.PropertyKey.slowLength] as! Int
        let signalSmoothingLength = properties[Indicator.PropertyKey.signalSmoothingLength] as! Int
        
        if visibleCandles.isEmpty { return }
        if chart.candles.count <= slowLength + signalSmoothingLength {
            return
        }
        let length = slowLength + signalSmoothingLength
        //compute lowestMACD & highestMACD
        var lowestMACD = chart.highestPrice
        var highestMACD = -chart.highestPrice
        for i in 0 ..< visibleCandles.count {
            let candle = visibleCandles[i]
            let candleIndex =  i + chart.firstVisibleCandleIndex
            if candleIndex < length { continue }
            
            let macd = indicator.indicatorValue[candle.openTime] as! (Decimal, Decimal)
            if macd.0 > highestMACD { highestMACD = macd.0 }
            if macd.0 < lowestMACD { lowestMACD = macd.0 }
            if macd.1 > highestMACD { highestMACD = macd.1 }
            if macd.1 < lowestMACD { lowestMACD = macd.1 }
            if (macd.0 - macd.1) > highestMACD { highestMACD = macd.0 - macd.1 }
            if (macd.0 - macd.1) < lowestMACD { lowestMACD = macd.0 - macd.1 }
        }
        
        highestMACD = highestMACD + (highestMACD - lowestMACD) * 0.1
        lowestMACD = lowestMACD - (highestMACD - lowestMACD) * 0.1
        valueView.update(newhighestValue: highestMACD, newLowestValue: lowestMACD)
        
        if highestMACD == 0 && lowestMACD == 0 {
            return
        }
        
        var macdPoints = [CGPoint]()
        var signalPoints = [CGPoint]()
        var diffPoints = [CGPoint]()
        for i in 0..<visibleCandles.count {
            let candle = visibleCandles[i]
            let candleIndex =  i + chart.firstVisibleCandleIndex
            if candleIndex < length { continue }
            
            let macd = indicator.indicatorValue[candle.openTime] as! (Decimal, Decimal)
            
            let macdPoint = CGPoint(x: candle.x, y: Util.y(price: macd.0, frameHeight: frame.height, highestPrice: highestMACD, lowestPrice: lowestMACD))
            macdPoints.append(macdPoint)
            
            let signalPoint = CGPoint(x: candle.x, y: Util.y(price: macd.1, frameHeight: frame.height, highestPrice: highestMACD, lowestPrice: lowestMACD))
            signalPoints.append(signalPoint)
            
            let diffPoint = CGPoint(x: candle.x, y: Util.y(price: macd.0 - macd.1, frameHeight: frame.height, highestPrice: highestMACD, lowestPrice: lowestMACD))
            diffPoints.append(diffPoint)
        }
        if diffPoints.isEmpty { return }
        let macdColor = properties[Indicator.PropertyKey.color_1] as! UIColor
        let signalColor = properties[Indicator.PropertyKey.color_2] as! UIColor
        let macdLineWidth = properties[Indicator.PropertyKey.line_width_1] as! CGFloat
        let signalLineWidth = properties[Indicator.PropertyKey.line_width_2] as! CGFloat
        let diffPositiveColor = properties[Indicator.PropertyKey.color_3] as! UIColor
        let diffNegativeColor = properties[Indicator.PropertyKey.color_4] as! UIColor
        
        
        //draw bars
        for i in 0 ..< diffPoints.count {
            let zeroY =  Util.y(price: Decimal(0), frameHeight: frame.height, highestPrice: highestMACD, lowestPrice: lowestMACD)
            let color: UIColor = (diffPoints[i].y >= zeroY) ? diffNegativeColor : diffPositiveColor
            ctx.setFillColor(color.withAlphaComponent(0.5).cgColor)
            ctx.fill(CGRect(x: diffPoints[i].x, y: diffPoints[i].y, width: chart.candleWidth, height: zeroY - diffPoints[i].y))
        }
        
        //draw macd line
        ctx.setLineJoin(.round)
        ctx.setStrokeColor(macdColor.withAlphaComponent(0.5).cgColor)
        ctx.setLineWidth(macdLineWidth)
        ctx.beginPath()
        ctx.move(to: macdPoints[0])
        for i in 0 ..< macdPoints.count {
            let point = macdPoints[i]
            ctx.addLine(to: point)
        }
        ctx.strokePath()
        
        
        
        //draw signal line
        ctx.setStrokeColor(signalColor.withAlphaComponent(0.5).cgColor)
        ctx.setLineWidth(signalLineWidth)
        ctx.beginPath()
        ctx.move(to: signalPoints[0])
        for i in 0 ..< signalPoints.count {
            let point = signalPoints[i]
            ctx.addLine(to: point)
        }
        ctx.strokePath()
        
        
        
    }
    
    
    
    
    
    private func drawBollingerBands(in rect: CGRect, using ctx: CGContext) {
        let visibleCandles = self.visibleCandles
        
        
        
        let length = properties[Indicator.PropertyKey.fastLength] as! Int
        
        let showsMiddleBand = properties[Indicator.PropertyKey.showMiddleBand] as! Bool
        
        if chart.candles.count <= length || visibleCandles.isEmpty {
            return
        }
        
        var upperPoints = [CGPoint]()
        var middlePoints = [CGPoint]()
        var lowerPoints = [CGPoint]()
        
        for i in 0..<visibleCandles.count {
            let candleIndex =  i + chart.firstVisibleCandleIndex
            if candleIndex < length { continue }
            
            let bb = indicator.indicatorValue[visibleCandles[i].openTime] as! (Decimal, Decimal, Decimal)
            upperPoints.append(CGPoint(x: visibleCandles[i].x, y: Util.y(price: bb.0, frameHeight: frame.height, highestPrice: chart.highestPrice, lowestPrice: chart.lowestPrice)))
            middlePoints.append(CGPoint(x: visibleCandles[i].x, y: Util.y(price: bb.1, frameHeight: frame.height, highestPrice: chart.highestPrice, lowestPrice: chart.lowestPrice)))
            lowerPoints.append(CGPoint(x: visibleCandles[i].x, y: Util.y(price: bb.2, frameHeight: frame.height, highestPrice: chart.highestPrice, lowestPrice: chart.lowestPrice)))
        }
        
        if upperPoints.count < 2 { return }
        
        let color = properties[Indicator.PropertyKey.color_1] as! UIColor
        
        let lineWidth = properties[Indicator.PropertyKey.line_width_1] as! CGFloat
        
        
        
        ctx.setStrokeColor(color.withAlphaComponent(0.5).cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.setLineJoin(.round)
        ctx.beginPath()
        ctx.move(to: upperPoints[0])
        for i in 0 ..< upperPoints.count {
            let point = upperPoints[i]
            ctx.addLine(to: point)
        }
        ctx.strokePath()

        ctx.beginPath()
        ctx.move(to: lowerPoints[0])
        for i in 0 ..< lowerPoints.count {
            let point = lowerPoints[i]
            ctx.addLine(to: point)
        }
        ctx.strokePath()
        
        
        
        ctx.setLineWidth(0)
        ctx.setFillColor(color.withAlphaComponent(0.25).cgColor)
        for i in 1 ..< upperPoints.count {
            ctx.beginPath()
            ctx.move(to: upperPoints[i - 1])
            let p1 = upperPoints[i]
            let p2 = lowerPoints[i]
            let p3 = lowerPoints[i - 1]
            ctx.addLine(to: p1)
            ctx.addLine(to: p2)
            ctx.addLine(to: p3)
            ctx.closePath()
            ctx.fillPath()
        }

        
        ctx.setLineWidth(lineWidth)
        ctx.setLineJoin(.round)
        
        if showsMiddleBand {
            ctx.beginPath()
            ctx.setStrokeColor(color.withAlphaComponent(0.7).withAlphaComponent(0.5).cgColor)
            ctx.move(to: middlePoints[0])
            for i in 0 ..< middlePoints.count {
                let point = middlePoints[i]
                ctx.addLine(to: point)
            }
            ctx.strokePath()
        }
        
        
    }
    
    
    
    
    
    
    
    
    
}
