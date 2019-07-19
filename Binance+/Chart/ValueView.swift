//
//  ValueView.swift
//  Binance+
//
//  Created by Behnam Karimi on 2/23/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class ValueView: UIView {
    var chart: Chart
    
    //MARK: - Properties
    var highestValue: Decimal
    var lowestValue: Decimal
    var tickSize: Decimal
    
    
    var maxNumberOfTicks: CGFloat = 0
    var minNumberOfTicks: CGFloat = 0
    var tickGap: Decimal
    var tickStrings = [NSAttributedString]()
    var tickPrices = [Decimal]()
    var numberOfTicks: Int = 1
    var precision = -1
    
    //for grids
    var tickYs = [CGFloat]()
    var requiredTickPrices = [Decimal]()
    
    
    // MARK: - Initialization
    init(chart: Chart, tickSize: Decimal, highestValue: Decimal, lowestValue: Decimal, requiredTickPrices: [Decimal] = [Decimal](), precision: Int = -1) {
        self.tickSize = tickSize
        self.highestValue = highestValue
        self.lowestValue = lowestValue
        self.chart = chart
        self.tickGap = tickSize
        self.requiredTickPrices = requiredTickPrices
        self.precision = precision
        super.init(frame: .zero)
        
        clipsToBounds = true
        
        backgroundColor = .white
        if tickSize > 0 {
            calculateTicks()
        } else {
            var width: CGFloat = 0
            for p in requiredTickPrices {
                let attrStr =  getTickAttributedString(text: " " + ((precision == -1) ? p.stringValue : p.formattedWith(fractionDigitCount: precision)))
                tickStrings.append(attrStr)
                if attrStr.size().width + 6 > width {
                    width = attrStr.size().width + 6
                }
                tickPrices.append(p)
            }
            if width > chart.valueViewWidth {
                chart.valueViewWidth = width
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: - Draw
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if tickSize > 0 {
            calculateTicks()
        }
        
        tickYs.removeAll()
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setLineWidth(2.0)
        ctx.strokeLineSegments(between: [CGPoint(x: 0, y: rect.height), CGPoint(x: rect.width, y: rect.height)])
        ctx.setLineWidth(1.0)
        
        for i in 0..<tickPrices.count {
            let string = tickStrings[i]
            let price = tickPrices[i]
            let stringSize = string.size()
            let y = self.y(price: price, frameHeight: rect.height, highestPrice: highestValue, lowestPrice: lowestValue)
            let stringRect = CGRect(x: 6, y: y - stringSize.height / 2, width: stringSize.width, height: stringSize.height)
            tickYs.append(y)
            ctx.strokeLineSegments(between: [CGPoint(x: 0, y: y), CGPoint(x: 6, y: y)])
            string.draw(in: stringRect)
        }
        chart.drawGridLines()
    }
    
    
    func update(newhighestValue: Decimal, newLowestValue: Decimal) {
        highestValue = newhighestValue
        lowestValue = newLowestValue
        setNeedsDisplay()
    }
    
    
    
    
    
    
    // MARK: - Private Methods
    
    private func calculateTicks() {
//        if tickPrices.count * 2 <= numberOfTicks || tickPrices.count > Int(maxNumberOfTicks) + 2 {
            calculateTickGap()
//        }
        tickStrings.removeAll()
        tickPrices.removeAll()
        var width: CGFloat = 0
        let m = Int((lowestValue / tickGap).doubleValue)
        
        var p = Decimal(m + 1) * tickGap
        while p < highestValue {
            let attrStr = getTickAttributedString(text: " " + ((precision == -1) ? p.stringValue : p.formattedWith(fractionDigitCount: precision)))
            tickStrings.append(attrStr)
            if attrStr.size().width + 6 > width {
                width = attrStr.size().width + 6
            }
            tickPrices.append(p)
            p += tickGap
        }
        for p in requiredTickPrices {
            let attrStr = getTickAttributedString(text: " " + ((precision == -1) ? p.stringValue : p.formattedWith(fractionDigitCount: precision)))
            tickStrings.append(attrStr)
            if attrStr.size().width + 6 > width {
                width = attrStr.size().width + 6
            }
            tickPrices.append(p)
        }
        if width > chart.valueViewWidth {
            chart.valueViewWidth = width
        }
    }
    
    
    private func calculateTickGap() {
        let diff = highestValue - lowestValue
        
        let n = diff / tickSize
        
        var m: [Decimal] = [1, 2, 4, 5]
        let p = Util.greatestPowerOfTenLess(than: n)
        
        
        if p >= 1 {
            for i in 1..<(p+1) {
                for j in 0..<4 {
                    let m1 = pow(10, i) * m[j]
                    if m1 < n {
                        m.append(m1)
                    }
                }
            }
        }
        
        m.reverse()
        
        let tickHeight = getTickAttributedString(text: "0.00002135").size().height
        if bounds.height > 0 {
            maxNumberOfTicks = bounds.height / (tickHeight * 3)
        } else {
            maxNumberOfTicks = 1
        }
        
        var bestM: Decimal = m.first!
        for m1 in m {
            numberOfTicks = Int((diff / (m1 * tickSize)).doubleValue)
            if numberOfTicks <= Int(maxNumberOfTicks) {
                bestM = m1
            } else {
                break
            }
        }
        
        tickGap = bestM * tickSize
    }
    
    
    func y(price: Decimal, frameHeight: CGFloat, highestPrice: Decimal, lowestPrice: Decimal) -> CGFloat {
        let ratio = ((highestPrice - price) / (highestPrice - lowestPrice)).cgFloatValue
        return frameHeight * ratio
    }
    
    
    func getTickAttributedString(text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        
        let attributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11.0),
            NSAttributedString.Key.foregroundColor: UIColor.black
        ]
        
        let string = NSAttributedString(string: text, attributes: attributes)
        return string
    }

}
