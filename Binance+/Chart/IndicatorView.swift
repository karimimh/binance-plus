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
    var candles: [Candle] {
        get {
            return chart.candles
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
                if candle.volume > highestVolume { highestVolume = candle.volume }
            }
            valueView = ValueView(chart: chart, tickSize: chart.symbol.stepSize, highestValue: highestVolume * 1.2, lowestValue: 0)
        case .rsi:
            valueView = ValueView(chart: chart, tickSize: -1.0, highestValue: 100, lowestValue: 0, requiredTickPrices: [30, 70])
        case .macd:
            valueView = ValueView(chart: chart, tickSize: -1.0, highestValue: 100, lowestValue: 0, requiredTickPrices: [0])
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
            drawGridLines(using: ctx)
            drawVolume(in: rect, using: ctx)
        case .sma:
            drawSMA(in: rect, using: ctx)
        case .ema:
            drawEMA(in: rect, using: ctx)
        case .rsi:
            drawGridLines(using: ctx)
            drawRSI(in: rect, using: ctx)
        case .macd:
            drawGridLines(using: ctx)
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
        let candles = self.candles
        var data = [Decimal]()
        var highestVolume: Decimal = 0
        for candle in candles {
            data.append(candle.volume)
            if chart.isVisible(candle: candle) && candle.volume > highestVolume { highestVolume = candle.volume }
        }
        highestVolume *= 1.2
        valueView.update(newhighestValue: highestVolume, newLowestValue: 0)
        
        var color = UIColor.lightGray
        if let c = properties[Indicator.PropertyKey.color_1] as? UIColor {
            color = c
        }
        var smaColor = UIColor.blue
        if let cc = properties[Indicator.PropertyKey.color_2] as? UIColor {
            smaColor = cc
        }
        var smaLineWidth: CGFloat = 1
        if let w = properties[Indicator.PropertyKey.line_width_1] as? CGFloat {
            smaLineWidth = w
        }
        
        var smaLength: Int = 8
        if let l = properties[Indicator.PropertyKey.length] as? Int {
            smaLength = l
        }
        let sma = Indicators.sma(data: data, length: smaLength)
        
        var smaPoints = [CGPoint]()
        ctx.setFillColor(color.withAlphaComponent(0.5).cgColor)
        for i in 0..<candles.count {
            let candle = candles[i]
            let height: CGFloat = (candle.volume / highestVolume).cgFloatValue * frame.height
            ctx.fill(CGRect(x: candle.x - chart.candleWidth / 2, y: frame.height - height, width: chart.candleWidth * 2 / 3, height: height))
            if i >= smaLength {
                smaPoints.append(CGPoint(x: candle.x, y: frame.height - (sma[i] / highestVolume).cgFloatValue * frame.height))
            }
        }
        if smaPoints.isEmpty {
            return
        }
        
        ctx.setStrokeColor(smaColor.withAlphaComponent(0.5).cgColor)
        ctx.setLineWidth(smaLineWidth)
        ctx.setLineJoin(.round)
        
        ctx.move(to: smaPoints[0])
        for point in smaPoints {
            ctx.addLine(to: point)
        }
        ctx.strokePath()
        
    }
    
    
    
    private func drawSMA(in rect: CGRect, using ctx: CGContext) {
        let candles = self.candles
        var source: String = "Close"
        if let s = properties[Indicator.PropertyKey.source] as? String {
            source = s
        }
        var data = [Decimal]()
        
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
        
        
        var length: Int = 8
        if let l = properties[Indicator.PropertyKey.length] as? Int {
            length = l
        }
        
        let sma = Indicators.sma(data: data, length: length)
        if length >= candles.count {
            return
        }
        
        var points = [CGPoint]()
        for i in length..<candles.count {
            let point = CGPoint(x: candles[i].x, y: Util.y(price: sma[i], frameHeight: frame.height, highestPrice: chart.highestPrice, lowestPrice: chart.lowestPrice))
            points.append(point)
        }
        
        
        var color = UIColor.black
        if let c = properties[Indicator.PropertyKey.color_1] as? UIColor {
            color = c
        }
        
        var lineWidth: CGFloat = 1
        if let w = properties[Indicator.PropertyKey.line_width_1] as? CGFloat {
            lineWidth = w
        }
        ctx.setStrokeColor(color.withAlphaComponent(0.5).cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.setLineJoin(.round)
        
        ctx.move(to: points[0])
        for point in points {
            ctx.addLine(to: point)
        }
        ctx.strokePath()
    }
    
    
    
    private func drawEMA(in rect: CGRect, using ctx: CGContext) {
        let candles = self.candles
        var source: String = "Close"
        if let s = properties[Indicator.PropertyKey.source] as? String {
            source = s
        }

        var data = [Decimal]()
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
        
        
        var length: Int = 8
        if let l = properties[Indicator.PropertyKey.length] as? Int {
            length = l
        }
        
        let ema = Indicators.ema(data: data, length: length)
        
        if length >= candles.count {
            return
        }
        var points = [CGPoint]()
        for i in length..<candles.count {
            let point = CGPoint(x: candles[i].x, y: Util.y(price: ema[i], frameHeight: frame.height, highestPrice: chart.highestPrice, lowestPrice: chart.lowestPrice))
            points.append(point)
        }
        
        
        var color = UIColor.black
        if let c = properties[Indicator.PropertyKey.color_1] as? UIColor {
            color = c
        }
        
        var lineWidth: CGFloat = 1
        if let w = properties[Indicator.PropertyKey.line_width_1] as? CGFloat {
            lineWidth = w
        }
        ctx.setStrokeColor(color.withAlphaComponent(0.5).cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.setLineJoin(.round)
        
        ctx.move(to: points[0])
        for point in points {
            ctx.addLine(to: point)
        }
        ctx.strokePath()
    }
    
    
    
    
    
    private func drawRSI(in rect: CGRect, using ctx: CGContext) {
        let candles = self.candles
        var source: String = "Close"
        if let s = properties[Indicator.PropertyKey.source] as? String {
            source = s
        }
        var data = [Decimal]()
        
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
        
        
        var length: Int = 14
        if let l = properties[Indicator.PropertyKey.length] as? Int {
            length = l
        }
        
        let rsi = Indicators.rsi(data: data, length: length)
        if length >= candles.count {
            return
        }
        
        var points = [CGPoint]()
        for i in length..<candles.count {
            let point = CGPoint(x: candles[i].x, y: Util.y(price: rsi[i], frameHeight: frame.height, highestPrice: Decimal(100), lowestPrice: Decimal(0)))
            points.append(point)
        }
        
        
        var color = UIColor.black
        if let c = properties[Indicator.PropertyKey.color_1] as? UIColor {
            color = c
        }
        
        var lineWidth: CGFloat = 1
        if let w = properties[Indicator.PropertyKey.line_width_1] as? CGFloat {
            lineWidth = w
        }
        ctx.setStrokeColor(color.withAlphaComponent(0.5).cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.setLineJoin(.round)
        
        ctx.move(to: points[0])
        for point in points {
            ctx.addLine(to: point)
        }
        ctx.strokePath()
    }
    
    
    private func drawMACD(in rect: CGRect, using ctx: CGContext) {
        let candles = self.candles
        var source: String = "Close"
        if let s = properties[Indicator.PropertyKey.source] as? String {
            source = s
        }
        var data = [Decimal]()
        
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
        
        
        var fastLength: Int = 12
        if let l = properties[Indicator.PropertyKey.fastLength] as? Int {
            fastLength = l
        }
        
        var slowLength: Int = 26
        if let l = properties[Indicator.PropertyKey.slowLength] as? Int {
            slowLength = l
        }
        
        var signalSmoothingLength = 9
        if let l = properties[Indicator.PropertyKey.signalSmoothingLength] as? Int {
            signalSmoothingLength = l
        }
        if data.count <= slowLength + signalSmoothingLength {
            return
        }
        let macd = Indicators.macd(data: data, fastLength: fastLength, slowLength: slowLength, signalSmoothingLength: signalSmoothingLength)
        //compute lowestMACD & highestMACD
        var lowestMACD = chart.highestPrice
        var highestMACD = -chart.highestPrice
        for i in (slowLength + signalSmoothingLength)..<macd.count {
            if !chart.isVisible(candle: candles[i]) { continue }
            if macd[i].0 > highestMACD { highestMACD = macd[i].0 }
            if macd[i].0 < lowestMACD { lowestMACD = macd[i].0 }
            if macd[i].1 > highestMACD { highestMACD = macd[i].1 }
            if macd[i].1 < lowestMACD { lowestMACD = macd[i].1 }
            if (macd[i].0 - macd[i].1) > highestMACD { highestMACD = macd[i].0 - macd[i].1 }
            if (macd[i].0 - macd[i].1) < lowestMACD { lowestMACD = macd[i].0 - macd[i].1 }
        }
        
        highestMACD = highestMACD + (highestMACD - lowestMACD) * 0.1
        lowestMACD = lowestMACD - (highestMACD - lowestMACD) * 0.1
        valueView.update(newhighestValue: highestMACD, newLowestValue: lowestMACD)
        var macdPoints = [CGPoint]()
        var signalPoints = [CGPoint]()
        var diffPoints = [CGPoint]()
        for i in 0..<candles.count {
            let macdPoint = CGPoint(x: candles[i].x, y: Util.y(price: macd[i].0, frameHeight: frame.height, highestPrice: highestMACD, lowestPrice: lowestMACD))
            macdPoints.append(macdPoint)
            
            let signalPoint = CGPoint(x: candles[i].x, y: Util.y(price: macd[i].1, frameHeight: frame.height, highestPrice: highestMACD, lowestPrice: lowestMACD))
            signalPoints.append(signalPoint)
            
            let diffPoint = CGPoint(x: candles[i].x, y: Util.y(price: macd[i].0 - macd[i].1, frameHeight: frame.height, highestPrice: highestMACD, lowestPrice: lowestMACD))
            diffPoints.append(diffPoint)
        }
        
        
        var macdColor = UIColor.blue
        if let c = properties[Indicator.PropertyKey.color_1] as? UIColor {
            macdColor = c
        }
        
        var signalColor = UIColor.red
        if let c = properties[Indicator.PropertyKey.color_2] as? UIColor {
            signalColor = c
        }
        
        var macdLineWidth: CGFloat = 1
        if let w = properties[Indicator.PropertyKey.line_width_1] as? CGFloat {
            macdLineWidth = w
        }
        
        var signalLineWidth: CGFloat = 1
        if let w = properties[Indicator.PropertyKey.line_width_2] as? CGFloat {
            signalLineWidth = w
        }
        
        var diffPositiveColor = UIColor.green
        if let c = properties[Indicator.PropertyKey.color_3] as? UIColor {
            diffPositiveColor = c
        }
        
        var diffNegativeColor = UIColor.red
        if let c = properties[Indicator.PropertyKey.color_4] as? UIColor {
            diffNegativeColor = c
        }
        
        
        
        if candles.count < slowLength + signalSmoothingLength { return }
        
        //draw bars
        for i in (slowLength + signalSmoothingLength) ..< candles.count {
            let zeroY =  Util.y(price: Decimal(0), frameHeight: frame.height, highestPrice: highestMACD, lowestPrice: lowestMACD)
            let color: UIColor = (diffPoints[i].y >= zeroY) ? diffNegativeColor : diffPositiveColor
            ctx.setFillColor(color.withAlphaComponent(0.5).cgColor)
            ctx.fill(CGRect(x: candles[i].x - chart.candleWidth / 2, y: diffPoints[i].y, width: chart.candleWidth, height: zeroY - diffPoints[i].y))
        }
        
        //draw macd line
        ctx.setLineJoin(.round)
        ctx.setStrokeColor(macdColor.withAlphaComponent(0.5).cgColor)
        ctx.setLineWidth(macdLineWidth)
        ctx.beginPath()
        ctx.move(to: macdPoints[slowLength])
        for i in slowLength ..< macdPoints.count {
            let point = macdPoints[i]
            ctx.addLine(to: point)
        }
        ctx.strokePath()
        
        
        
        //draw signal line
        ctx.setStrokeColor(signalColor.withAlphaComponent(0.5).cgColor)
        ctx.setLineWidth(signalLineWidth)
        ctx.beginPath()
        ctx.move(to: signalPoints[slowLength + signalSmoothingLength])
        for i in (slowLength + signalSmoothingLength) ..< signalPoints.count {
            let point = signalPoints[i]
            ctx.addLine(to: point)
        }
        ctx.strokePath()
        
        
        
    }
    
    
    
    
    
    private func drawBollingerBands(in rect: CGRect, using ctx: CGContext) {
        let candles = self.candles
        var source: String = "Close"
        if let s = properties[Indicator.PropertyKey.source] as? String {
            source = s
        }
        var data = [Decimal]()
        
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
        
        
        var length: Int = 20
        if let l = properties[Indicator.PropertyKey.fastLength] as? Int {
            length = l
        }
        
        var stdDev: Int = 2
        if let l = properties[Indicator.PropertyKey.slowLength] as? Int {
            stdDev = l
        }
        
        var showsMiddleBand: Bool = true
        if let b = properties[Indicator.PropertyKey.showMiddleBand] as? Bool {
            showsMiddleBand = b
        }
        
        let bb = Indicators.bollinger_bands(data: data, length: length, stdDev: stdDev)
        
        if data.count <= length {
            return
        }
        
        var upperPoints = [CGPoint]()
        var middlePoints = [CGPoint]()
        var lowerPoints = [CGPoint]()
        
        for i in 0..<candles.count {
            upperPoints.append(CGPoint(x: candles[i].x, y: Util.y(price: bb[i].0, frameHeight: frame.height, highestPrice: chart.highestPrice, lowestPrice: chart.lowestPrice)))
            middlePoints.append(CGPoint(x: candles[i].x, y: Util.y(price: bb[i].1, frameHeight: frame.height, highestPrice: chart.highestPrice, lowestPrice: chart.lowestPrice)))
            lowerPoints.append(CGPoint(x: candles[i].x, y: Util.y(price: bb[i].2, frameHeight: frame.height, highestPrice: chart.highestPrice, lowestPrice: chart.lowestPrice)))
        }
        
        
        var color = UIColor.lightGray
        if let c = properties[Indicator.PropertyKey.color_1] as? UIColor {
            color = c
        }
        
        var lineWidth: CGFloat = 1
        if let w = properties[Indicator.PropertyKey.line_width_1] as? CGFloat {
            lineWidth = w
        }

        
        
        
        
        
        ctx.setStrokeColor(color.withAlphaComponent(0.5).cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.setLineJoin(.round)
        ctx.beginPath()
        ctx.move(to: upperPoints[length - 1])
        for i in length ..< upperPoints.count {
            let point = upperPoints[i]
            ctx.addLine(to: point)
        }
        ctx.strokePath()

        ctx.beginPath()
        ctx.move(to: lowerPoints[length - 1])
        for i in length..<lowerPoints.count {
            let point = lowerPoints[i]
            ctx.addLine(to: point)
        }
        ctx.strokePath()
        
        
        ctx.setLineWidth(0)
        ctx.setFillColor(color.withAlphaComponent(0.25).cgColor)
        for i in length ..< upperPoints.count {
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
            ctx.move(to: middlePoints[length - 1])
            for i in length ..< middlePoints.count {
                let point = middlePoints[i]
                ctx.addLine(to: point)
            }
            ctx.strokePath()
        }
        
        
    }
    
    
    
    
    private func drawGridLines(using ctx: CGContext) {
        if chart.timeView == nil { return }
        ctx.setStrokeColor(UIColor.fromHex(hex: "#DFEAF0").withAlphaComponent(0.5).cgColor)
        for candle in chart.timeView.gridCandles {
            ctx.strokeLineSegments(between: [CGPoint(x: candle.x, y: 0), CGPoint(x: candle.x, y: frame.height)])
        }
        
        for y in valueView.tickYs {
            ctx.strokeLineSegments(between: [CGPoint(x: 0, y: y), CGPoint(x: frame.width, y: y)])
        }
        
    }
    
    
    
    
    
}
