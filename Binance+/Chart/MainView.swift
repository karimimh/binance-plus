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
    
    var wholeCandleWidth: CGFloat {
        get {
            return chart.candleWidth
        }
    }
    
    var spacing: CGFloat = 0
    var candleWidth: CGFloat = 0
    var wickWidth: CGFloat = 0.75
    
    var latestCandleX: CGFloat {
        get {
            return chart.latestX
        }
        set {
            chart.latestX = newValue
        }
    }
    
    private var currentWholeCandleWidth: CGFloat = 0
    
    //MARK: - Initialization
    init(chart: Chart) {
        self.chart = chart
        self.app = chart.app
        super.init(frame: .zero)
        
        currentWholeCandleWidth = wholeCandleWidth
        
        backgroundColor = .clear
        clipsToBounds = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //MARK: - Draw
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if wholeCandleWidth < currentWholeCandleWidth {
            let diff = currentWholeCandleWidth - wholeCandleWidth
            if spacing >= diff {
                spacing -= diff
            } else {
                candleWidth = wholeCandleWidth * 3 / 4
                spacing = wholeCandleWidth * 1 / 4
            }
        } else {
            candleWidth = wholeCandleWidth * 3 / 4
            spacing = wholeCandleWidth * 1 / 4
        }
        currentWholeCandleWidth = wholeCandleWidth
        
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setLineWidth(2.0)
        ctx.strokeLineSegments(between: [CGPoint(x: 0, y: rect.height), CGPoint(x: rect.width, y: rect.height)])
        ctx.strokeLineSegments(between: [CGPoint(x: rect.width, y: 0), CGPoint(x: rect.width, y: rect.height)])
        ctx.setLineWidth(1.0)
        
        for candle in visibleCandles {
            let y = self.y(price: candle.high, frameHeight: frame.height, highestPrice: highestPrice, lowestPrice: lowestPrice)
            let h = self.y(price: candle.low, frameHeight: frame.height, highestPrice: highestPrice, lowestPrice: lowestPrice) - y
            
            if candle.high == candle.low {
                draw(candle: candle, in: CGRect(x: candle.x - wholeCandleWidth / 2, y: y, width: wholeCandleWidth, height: wickWidth), using: ctx)
            } else {
                draw(candle: candle, in: CGRect(x: candle.x - wholeCandleWidth / 2, y: y, width: wholeCandleWidth, height: h), using: ctx)
            }
        }
        

        //Draw Title, Value:
        
        let titleString = getMutableAttString(text: symbol.name, color: UIColor.black)
        if chart.crosshair.isEnabled {
            let candleIndex = chart.crosshair.currentCandleIndex
            let candle: Candle
            if candleIndex < visibleCandles.count && candleIndex >= 0 {
                candle = chart.visibleCandles[candleIndex]
            } else {
                candle = chart.candles.last!
            }
            let candleColor = candle.getColor(app)
            titleString.append(getAttString(text: "\nO: ", color: UIColor.gray.withAlphaComponent(0.75)))
            titleString.append(getAttString(text: "\(symbol.priceFormatted(candle.open))  ", color: candleColor))
            titleString.append(getAttString(text: "H: ", color: UIColor.gray.withAlphaComponent(0.75)))
            titleString.append(getAttString(text: "\(symbol.priceFormatted(candle.high))  ", color: candleColor))
            titleString.append(getAttString(text: "L: ", color: UIColor.gray.withAlphaComponent(0.75)))
            titleString.append(getAttString(text: "\(symbol.priceFormatted(candle.low))  ", color: candleColor))
            titleString.append(getAttString(text: "C: ", color: UIColor.gray.withAlphaComponent(0.75)))
            titleString.append(getAttString(text: "\(symbol.priceFormatted(candle.close))", color: candleColor))
            
            for indicator in chart.indicators {
                if indicator.frameRow != 0 { continue }
                titleString.append(getAttString(text: "\n" + indicator.getNameInFunctionForm(), color: UIColor.black))
                switch indicator.indicatorType {
                case .bollinger_bands:
                    let color = (indicator.properties[Indicator.PropertyKey.color_1] as! UIColor)
                    let bb = indicator.indicatorValue[candle.openTime] as! (Decimal, Decimal, Decimal)
                    titleString.append(getAttString(text: "  \(symbol.priceFormatted(bb.0))", color: color))
//                    titleString.append(getAttString(text: "  \(symbol.priceFormatted(bb.1))", color: color.withAlphaComponent(0.7)))
                    titleString.append(getAttString(text: "  \(symbol.priceFormatted(bb.2))", color: color))
                case .sma:
                    let color = indicator.properties[Indicator.PropertyKey.color_1] as! UIColor
                    let sma = indicator.indicatorValue[candle.openTime] as! Decimal
                    titleString.append(getAttString(text: "  \(symbol.priceFormatted(sma))", color: color))
                case .ema:
                    let color = indicator.properties[Indicator.PropertyKey.color_1] as! UIColor
                    let ema = indicator.indicatorValue[candle.openTime] as! Decimal
                    titleString.append(getAttString(text: "  \(symbol.priceFormatted(ema))", color: color))
                default:
                    break
                }
            }
        }
        let stringSize = titleString.size()
        let stringRect = CGRect(x: 5, y: 5, width: stringSize.width, height: stringSize.height)
        titleString.draw(in: stringRect)
        
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
        let candleHeight = rect.height
        
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setLineWidth(0)
        if candle.high == candle.low {
            ctx.setFillColor(app.bullCandleColor.cgColor)
            ctx.fill(CGRect(x: spacing / 2 + rect.origin.x, y: rect.origin.y, width: candleWidth, height: candleHeight))
            return
        }
        
        
        
        let isGreen = (candle.close >= candle.open)
        let color: UIColor
        if isGreen {
            color = app.bullCandleColor
        } else {
            color = app.bearCandleColor
        }
        
        
        var bodyHeight = ((candle.close - candle.open) / (candle.high - candle.low)).cgFloatValue * candleHeight
        if !isGreen {
            bodyHeight = -bodyHeight
        }
        if bodyHeight < wickWidth {
            bodyHeight = wickWidth
        }
        
        
        let upperWickHeight = ((candle.high - (isGreen ? candle.close : candle.open)) / (candle.high - candle.low)).cgFloatValue * candleHeight
        let lowerWickHeight = candleHeight - upperWickHeight - bodyHeight
        
        
        
        
        ctx.setFillColor(color.cgColor)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        if upperWickHeight > 0 {
            ctx.fill(CGRect(x: spacing / 2 + rect.origin.x + candleWidth / 2 - wickWidth / 2, y: rect.origin.y, width: wickWidth, height: upperWickHeight))
        }
        ctx.fill(CGRect(x: spacing / 2 + rect.origin.x, y: rect.origin.y + upperWickHeight, width: candleWidth, height: bodyHeight))
        if lowerWickHeight > 0 {
            ctx.fill(CGRect(x: spacing / 2 + rect.origin.x + candleWidth / 2 - wickWidth / 2, y: rect.origin.y + upperWickHeight + bodyHeight, width: wickWidth, height: lowerWickHeight))
        }
        
    }
    
    
    private func getAttString(text: String, color: UIColor) -> NSAttributedString {
        let attributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11.0),
            NSAttributedString.Key.foregroundColor: color
        ]
        
        let string = NSAttributedString(string: text, attributes: attributes)
        return string
    }
    
    private func getMutableAttString(text: String, color: UIColor) -> NSMutableAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: 11.0),
            .foregroundColor: color,
        ]
        
        let string = NSMutableAttributedString(string: text, attributes: attributes)
        return string
    }


}
