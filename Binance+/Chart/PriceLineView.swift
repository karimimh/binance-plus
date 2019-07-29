//
//  PriceLineView.swift
//  Binance+
//
//  Created by Behnam Karimi on 4/24/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class PriceLineView: UIView {
    var isEnabled = false
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
        
        let price = chart.visibleCandles.last!.close
        let y = self.y(price: price, frameHeight: chart.mainView.bounds.height, highestPrice: chart.highestPrice, lowestPrice: chart.lowestPrice)
        
        
        let ctx = UIGraphicsGetCurrentContext()!
        
        let path = UIBezierPath()
        let w = chart.bounds.width - chart.valueViewWidth
        path.move(to: CGPoint(x: 0, y: y))
        path.addLine(to: CGPoint(x: w, y: y))
        
        let color = (chart.visibleCandles.last!.isGreen() ? chart.app.bullCandleColor : chart.app.bearCandleColor)
        ctx.setLineWidth(0.25)
        ctx.setLineCap(.round)
        ctx.setLineDash(phase: 0, lengths: [0.5, 0.8])
        ctx.setStrokeColor(color.withAlphaComponent(0.75).cgColor)
        
        path.stroke()
        
        
        
        let str = getValueTickAttributedString(text: " " + chart.symbol.priceFormatted(price))
        let strWidth = chart.valueViewWidth
        let strHeight = str.size().height
        
        let strRect = CGRect(x: chart.frame.width + 6 - strWidth, y: y - strHeight / 2, width: strWidth, height: strHeight)
        let bgRect = CGRect(x: chart.frame.width - strWidth, y: y - strHeight * 0.75, width: strWidth, height: strHeight * 1.5)
        ctx.setFillColor(color.cgColor)
        ctx.fill(bgRect)
        ctx.setStrokeColor(UIColor.white.cgColor)
        ctx.strokeLineSegments(between: [CGPoint(x: chart.frame.width - strWidth, y: y), CGPoint(x: chart.frame.width - strWidth + 6, y: y)])
        str.draw(in: strRect)
        
        
        if chart.timeframe == .weekly || chart.timeframe == .monthly || chart.timeframe == .threeDaily {
            return
        }
        let time = Date(milliseconds: Date().toMillis() - chart.app.serverTimeOffset)
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.hour, .minute, .second], from: time, to: chart.candles.last!.nextCandleOpenTime().utcToLocal())
        var hour = comps.hour ?? 0
        var minute = comps.minute ?? 0
        var second = comps.second ?? 0
        
        if hour < 0 || minute < 0 || second < 0 {
            hour = 0
            minute = 0
            second = 0
        }
        let hourStr = String(format: "%02d", hour)
        let minuteStr = String(format: "%02d", minute)
        let secondStr = String(format:"%02d", second)
        
        var timeString: String?
        switch chart.timeframe {
        case .oneMinute, .threeMinutes, .fiveMinutes, .fifteenMinutes, .thirtyMinutes, .hourly:
            timeString = minuteStr + ":" + secondStr
        case .twoHourly, .fourHourly, .sixHourly, .eightHourly, .twelveHourly, .daily:
            timeString = hourStr + ":" + minuteStr + ":" + secondStr
        default:
            break
        }
        
        if let string = timeString {
            let s = getTimeTickAttributedString(text: " " + string)
            let sWidth = chart.valueViewWidth
            let sHeight = s.size().height
            
            let sRect = CGRect(x: chart.frame.width + 6 - sWidth, y: y + strHeight * 0.75 + sHeight * 0.25, width: sWidth, height: sHeight)
            let bgRect = CGRect(x: chart.frame.width - sWidth, y: y + strHeight * 0.75, width: sWidth, height: sHeight * 1.5)
            ctx.setFillColor(color.cgColor)
            ctx.fill(bgRect)
            s.draw(in: sRect)
        }
        
        
    }
    
    
    func update() {
        setNeedsDisplay()
    }
    
    private func y(price: Decimal, frameHeight: CGFloat, highestPrice: Decimal, lowestPrice: Decimal) -> CGFloat {
        let ratio = ((highestPrice - price) / (highestPrice - lowestPrice)).cgFloatValue
        return frameHeight * ratio
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
    
    
   
    
    func getTimeTickAttributedString(text: String) -> NSAttributedString {
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
    

}
