//
//  CrosshairView.swift
//  Binance+
//
//  Created by Behnam Karimi on 4/23/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class CrosshairView: UIView {
    var position = CGPoint.zero
    var initialPosition = CGPoint.zero
    var isEnabled = false
    
    var currentCandleIndex = -1
    
    let chart: Chart
    
    init(chart: Chart) {
        self.chart = chart
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if !isEnabled { return }
        if chart.timeView == nil || chart.priceView == nil { return }
        
        let ctx = UIGraphicsGetCurrentContext()!
        
        let path = UIBezierPath()
        
        let w = chart.bounds.width - chart.valueViewWidth
        let h = chart.bounds.height - TimeView.getHeight()
        
        
        path.move(to: CGPoint(x: position.x, y: 0))
        path.addLine(to: CGPoint(x: position.x, y: h))
        
        path.move(to: CGPoint(x: 0, y: position.y))
        path.addLine(to: CGPoint(x: w, y: position.y))
        
        ctx.setLineDash(phase: 0, lengths: [5.0, 3.0])
        ctx.setLineWidth(0.75)
        ctx.setStrokeColor(UIColor.black.cgColor)
        
        path.stroke()
        
        
        //Draw Time:
        currentCandleIndex = Int((position.x - chart.visibleCandles.first!.x) / chart.candleWidth)
        let string = timeToText(tick: currentCandleIndex)
        let stringSize = string.size()
        let bgTRect = CGRect(x: position.x - stringSize.width / 2, y: chart.timeView.frame.origin.y, width: stringSize.width, height: TimeView.getHeight())
        let strRect = CGRect(x: position.x - stringSize.width / 2, y: chart.timeView.frame.origin.y + (TimeView.getHeight() - stringSize.height) / 2, width: stringSize.width, height: stringSize.height)
        ctx.setFillColor(UIColor.black.withAlphaComponent(0.75).cgColor)
        ctx.fill(bgTRect)
        string.draw(in: strRect)
        
        //Draw Price
        
        if chart.mainView.frame.contains(position) {
            let f = chart.mainView.frame
            let price = chart.highestPrice - Decimal(Double(position.y - f.origin.y)) / Decimal(Double(f.height)) * (chart.highestPrice - chart.lowestPrice)
            let str = getValueTickAttributedString(text: " " + chart.symbol.priceFormatted(price))
            let strWidth = chart.valueViewWidth
            let strHeight = str.size().height
            
            let strRect = CGRect(x: self.frame.width + 6 - strWidth, y: position.y - strHeight / 2, width: strWidth, height: strHeight)
            let bgRect = CGRect(x: self.frame.width - strWidth, y: position.y - strHeight * 0.75, width: strWidth, height: strHeight * 1.5)
            ctx.setFillColor(UIColor.black.withAlphaComponent(0.75).cgColor)
            ctx.fill(bgRect)
            ctx.setStrokeColor(UIColor.white.cgColor)
            ctx.strokeLineSegments(between: [CGPoint(x: self.frame.width - strWidth, y: position.y), CGPoint(x: self.frame.width - strWidth + 6, y: position.y)])
            str.draw(in: strRect)
        } else {
            var indicatorView: IndicatorView?
            for iv in chart.indicatorViews {
                if iv.indicator.frameRow == 0 { continue }
                let f = iv.frame
                if f.contains(position) {
                    indicatorView = iv
                    break
                }
            }
            if let v = indicatorView {
                let f = v.frame
                let value = v.valueView.highestValue - Decimal(Double(position.y - f.origin.y)) / Decimal(Double(f.height)) * (v.valueView.highestValue - v.valueView.lowestValue)
                let str: NSAttributedString
                switch v.indicator.indicatorType {
                case .bollinger_bands, .macd:
                    str = getValueTickAttributedString(text: " " + chart.symbol.priceFormatted(value))
                case .rsi:
                    str = getValueTickAttributedString(text: " " + value.formattedWith(fractionDigitCount: 2))
                case .volume:
                    str = getValueTickAttributedString(text: " " + chart.symbol.volumeFormatted(value))
                default:
                    str = getValueTickAttributedString(text: " ")
                }
                
                let strWidth = chart.valueViewWidth
                let strHeight = str.size().height

                let strRect = CGRect(x: self.frame.width + 6 - strWidth, y: position.y - strHeight / 2, width: strWidth, height: strHeight)
                let bgRect = CGRect(x: self.frame.width - strWidth, y: position.y - strHeight * 0.75, width: strWidth, height: strHeight * 1.5)
                ctx.setFillColor(UIColor.black.withAlphaComponent(0.75).cgColor)
                ctx.fill(bgRect)
                ctx.setStrokeColor(UIColor.white.cgColor)
                ctx.strokeLineSegments(between: [CGPoint(x: self.frame.width - strWidth, y: position.y), CGPoint(x: self.frame.width - strWidth + 6, y: position.y)])
                str.draw(in: strRect)
            }
        }
        

        

        
    }

    
    func getValueTickAttributedString(text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        
        let attributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11.0),
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
        
        let string = NSAttributedString(string: text, attributes: attributes)
        return string
    }
    
    
    func timeToText(tick: Int) -> NSAttributedString {
        var time: Date
        if tick < chart.visibleCandles.count {
            time = chart.visibleCandles[tick].openTime
        } else {
            time = chart.visibleCandles.last!.openTime
            for _ in chart.visibleCandles.count ... tick {
                time = time.nextCandleOpenTime(timeframe: chart.timeframe)
            }
        }
        let timeLocal = time.utcToLocal()
        let day = Calendar.current.component(.day, from: time)
        let month = Calendar.current.component(.month, from: time)
        let year = Calendar.current.component(.year, from: time)
        let minuteL = Calendar.current.component(.minute, from: timeLocal)
        let hourL = Calendar.current.component(.hour, from: timeLocal)
        
        
        let text = Calendar.current.monthSymbols[month - 1]
        let m = String(text[text.startIndex ..< text.index(text.startIndex, offsetBy: 3)])
        
        let d = String(format: "%02d", day)
        let h = String(format: "%02d", hourL)
        let min = String(format: "%02d", minuteL)
        return getTimeTickAttributedString(text: "  \(d) \(m) \(year)  \(h):\(min)  ")
    }
    
    func getTimeTickAttributedString(text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10.0),
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
        
        let string = NSAttributedString(string: text, attributes: attributes)
        return string
    }
    
}
