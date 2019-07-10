//
//  TimeView.swift
//  Binance+
//
//  Created by Behnam Karimi on 2/12/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class TimeView: UIView {
    var allPossibleTimeTicks = [[Int]]()
    var candles: [Candle]! {
        get {
            return chart.candles
        }
    }
    var chart: Chart
    var timeframe: Timeframe {
        get {
            return chart.timeframe
        }
    }
    var candleWidth: CGFloat {
        get {
            return chart.candleWidth
        }
    }
    
    var ticks = Set<Int>()
    var mainTicksIndex: Int = 3// use later (maybe, i d k!)
    
    
    //for grids:
    var gridCandles = [Candle]()
    
    init(chart: Chart) {
        self.chart = chart
        super.init(frame: .zero)
        
        self.backgroundColor = .white
        clipsToBounds = true
        
        calculateAllPossibleTimeTicks()
        findTimeTicks(frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //MARK: - DRAW
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        findTimeTicks(rect)
        gridCandles.removeAll()
        
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setLineWidth(2.0)
        ctx.strokeLineSegments(between: [CGPoint(x: rect.width, y: 0), CGPoint(x: rect.width, y: rect.height)])
        ctx.setLineWidth(1.0)
        
        
        var stringRects = [CGRect]()
        for tick in ticks {
            let candle = candles[tick]
            if candle.x < 0 || candle.x > rect.width { continue }
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attributes = [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11.0),
                NSAttributedString.Key.foregroundColor: UIColor.black
            ]
            
            let string = NSAttributedString(string: tickToText(tick: tick), attributes: attributes)
            let stringSize = string.size()
            let stringRect = CGRect(x: candle.x - stringSize.width / 2, y: stringSize.height, width: stringSize.width, height: stringSize.height)
            
            var enoughSpaceToAddTick = true
            for r in stringRects {
                let r1 = CGRect(x: r.origin.x - r.width / 2, y: r.origin.y, width: r.width * 2, height: r.height)
                if r1.intersects(stringRect) {
                    enoughSpaceToAddTick = false
                    break
                }
            }
            
            if !enoughSpaceToAddTick { continue }
            
            stringRects.append(stringRect)
            
            ctx.setStrokeColor(UIColor.black.cgColor)
            ctx.strokeLineSegments(between: [CGPoint(x: candle.x, y: 0), CGPoint(x: candle.x, y: stringSize.height * 0.6)])
            
            string.draw(in: stringRect)
            gridCandles.append(candle)
        }
        chart.mainView.update()
        for iv in chart.indicatorViews {
            iv.update()
        }
    }
    
    func update() {
        self.setNeedsDisplay()
    }
    

    
    private func findTimeTicks(_ rect: CGRect) {
        ticks.removeAll()
        if rect == .zero { return }
        let timeframesToMinutes: [Int] = [Timeframe.monthly.toMinutes() * 12 * 10, Timeframe.monthly.toMinutes() * 12 * 5, Timeframe.monthly.toMinutes() * 12 * 2, Timeframe.monthly.toMinutes() * 12, Timeframe.monthly.toMinutes() * 6, Timeframe.monthly.toMinutes() * 4, Timeframe.monthly.toMinutes() * 3, Timeframe.monthly.toMinutes() * 2, Timeframe.monthly.toMinutes(), Timeframe.daily.toMinutes() * 15, Timeframe.daily.toMinutes() * 10, Timeframe.daily.toMinutes() * 5, Timeframe.daily.toMinutes() * 3, Timeframe.daily.toMinutes() * 2, Timeframe.daily.toMinutes(), Timeframe.twelveHourly.toMinutes(), Timeframe.sixHourly.toMinutes(), Timeframe.fourHourly.toMinutes(), Timeframe.hourly.toMinutes() * 3, Timeframe.twoHourly.toMinutes(), Timeframe.hourly.toMinutes(), Timeframe.thirtyMinutes.toMinutes(), Timeframe.fifteenMinutes.toMinutes(), Timeframe.oneMinute.toMinutes() * 10, Timeframe.fiveMinutes.toMinutes(), Timeframe.threeMinutes.toMinutes(), Timeframe.oneMinute.toMinutes() * 2, Timeframe.oneMinute.toMinutes()]
        
        let maxNumberOfVisibleCandles = Int(rect.width / (candleWidth * 4 / 3))
        let gapN = maxNumberOfVisibleCandles / 6
        let gapInMinutes = gapN * timeframe.toMinutes()
        
        var index = 0
        for i in 1..<timeframesToMinutes.count {
            let t1 = timeframesToMinutes[i-1]
            let t2 = timeframesToMinutes[i]
            
            if gapInMinutes <= t1 && gapInMinutes >= t2 {
                index = i
                break
            }
        }
        for i in 0 ... index {
            let array = allPossibleTimeTicks[i]
            
            for tick in array {
                ticks.insert(tick)
            }
        }
        
    }
    
    
    
    private func tickToText(tick: Int) -> String {
        let candle = candles[tick]
        
        let time = candle.openTime
        var text = ""
        let minute = Calendar.current.component(.minute, from: time)
        let hour = Calendar.current.component(.hour, from: time)
        let day = Calendar.current.component(.day, from: time)
        let month = Calendar.current.component(.month, from: time)
        let year = Calendar.current.component(.year, from: time)
        
        if (minute % 60 == 0) && (hour % 24 == 0) && (day == 1) && (month == 1) {
            text = String(year)
        } else if (minute % 60 == 0) && (hour % 24 == 0) && (day == 1) {
            text = Calendar.current.monthSymbols[month - 1]
            text = String(text[text.startIndex ..< text.index(text.startIndex, offsetBy: 3)])
        } else if (minute % 60 == 0) && (hour % 24 == 0) {
            text = String(day)
        } else if (minute % 60 == 0) {
            text = String(hour) + ":00"
        } else {
            text = String(hour) + ":" + String(minute)
        }
        return text
    }
    
    
    func calculateAllPossibleTimeTicks() {
        var _10y = [Int]()
        var _5y = [Int]()
        var _2y = [Int]()
        var _1y = [Int]()
        var _6M = [Int]()
        var _4M = [Int]()
        var _3M = [Int]()
        var _2M = [Int]()
        var _1M = [Int]()
        var _15d = [Int]()
        var _10d = [Int]()
        var _5d = [Int]()
        var _3d = [Int]()
        var _2d = [Int]()
        var _1d = [Int]()
        var _12h = [Int]()
        var _6h = [Int]()
        var _4h = [Int]()
        var _3h = [Int]()
        var _2h = [Int]()
        var _1h = [Int]()
        var _30m = [Int]()
        var _15m = [Int]()
        var _10m = [Int]()
        var _5m = [Int]()
        var _3m = [Int]()
        var _2m = [Int]()
        var _1m = [Int]()
        
        
        
        for i in 0..<candles.count {
            let candle = candles[i]
            let candleDate = candle.openTime
            let minute = Calendar.current.component(.minute, from: candleDate)
            let hour = Calendar.current.component(.hour, from: candleDate)
            let day = Calendar.current.component(.day, from: candleDate)
            let month = Calendar.current.component(.month, from: candleDate)
            let year = Calendar.current.component(.year, from: candleDate)
            
            //10 yr
            if (year % 10 == 0) && (minute % 60 == 0) && (hour % 24 == 0) && (day == 1) && (month == 1) {
                _10y.append(i)
            }
            //5 yr
            if (year % 5 == 0) && (minute % 60 == 0) && (hour % 24 == 0) && (day == 1) && (month == 1) {
                _5y.append(i)
            }
            //2 yr
            if (year % 2 == 0) && (minute % 60 == 0) && (hour % 24 == 0) && (day == 1) && (month == 1) {
                _2y.append(i)
            }
            //1 yr
            if (minute % 60 == 0) && (hour % 24 == 0) && (day == 1) && (month == 1) {
                _1y.append(i)
            }
            //6M
            if (minute % 60 == 0) && (hour % 24 == 0) && (day == 1) && (month % 6 == 1) {
                _6M.append(i)
            }
            //4M
            if (minute % 60 == 0) && (hour % 24 == 0) && (day == 1) && (month % 4 == 1) {
                _4M.append(i)
            }
            //3M
            if (minute % 60 == 0) && (hour % 24 == 0) && (day == 1) && (month % 3 == 1) {
                _3M.append(i)
            }
            //2M
            if (minute % 60 == 0) && (hour % 24 == 0) && (day == 1) && (month % 2 == 1) {
                _2M.append(i)
            }
            //1M
            if (minute % 60 == 0) && (hour % 24 == 0) && (day == 1) {
                _1M.append(i)
            }
            //15d
            if (minute % 60 == 0) && (hour % 24 == 0) && (day == 16) {
                _15d.append(i)
            }
            //10d
            if (minute % 60 == 0) && (hour % 24 == 0) && (day == 11 || day == 21) {
                _10d.append(i)
            }
            //5d
            if (minute % 60 == 0) && (hour % 24 == 0) && (day == 6 || day == 26) {
                _5d.append(i)
            }
            //3d
            if (minute % 60 == 0) && (hour % 24 == 0) && (day == 4 || day == 7 || day == 10 || day == 13 || day == 19 || day == 22 || day == 25 || day == 28) {
                _3d.append(i)
            }
            //2d
            if (minute % 60 == 0) && (hour % 24 == 0) && (day % 2 == 1) {
                _2d.append(i)
            }
            //1d
            if (minute % 60 == 0) && (hour % 24 == 0) {
                _1d.append(i)
            }
            //12h
            if (minute % 60 == 0) && (hour % 12 == 0)  {
                _12h.append(i)
            }
            //6h
            if (minute % 60 == 0) && (hour % 6 == 0)  {
                _6h.append(i)
            }
            //4h
            if (minute % 60 == 0) && (hour % 4 == 0)  {
                _4h.append(i)
            }
            //3h
            if (minute % 60 == 0) && (hour % 3 == 0)  {
                _3h.append(i)
            }
            //2h
            if (minute % 60 == 0) && (hour % 2 == 0)  {
                _2h.append(i)
            }
            //1h
            if (minute % 60 == 0)  {
                _1h.append(i)
            }
            //30m
            if (minute % 30 == 0)  {
                _30m.append(i)
            }
            //15m
            if (minute % 15 == 0)  {
                _15m.append(i)
            }
            //10m
            if (minute % 10 == 0)  {
                _10m.append(i)
            }
            //5m
            if (minute % 5 == 0)  {
                _5m.append(i)
            }
            //3m
            if (minute % 3 == 0)  {
                _3m.append(i)
            }
            //2m
            if (minute % 2 == 0)  {
                _2m.append(i)
            }
            //1m
            _1m.append(i)
        }
        
        
        allPossibleTimeTicks = [_10y, _5y, _2y, _1y, _6M, _4M, _3M, _2M, _1M, _15d, _10d, _5d, _3d, _2d, _1d, _12h, _6h, _4h, _3h, _2h, _1h, _30m, _15m, _10m, _5m, _3m, _2m, _1m]
        
        
    }

    
    static func getHeight() -> CGFloat {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11.0),
            NSAttributedString.Key.foregroundColor: UIColor.black
        ]
        
        let string = NSAttributedString(string: "M2y", attributes: attributes)
        return string.size().height * 2
    }
}
