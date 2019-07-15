//
//  TimeView.swift
//  Binance+
//
//  Created by Behnam Karimi on 2/12/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class TimeView: UIView {
    
    var visibleCandles: [Candle] {
        get {
            return chart.visibleCandles
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
    
    //for grids:
    var gridCandles = [Candle]()
    
    init(chart: Chart) {
        self.chart = chart
        super.init(frame: .zero)
        
        self.backgroundColor = .white
        clipsToBounds = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //MARK: - DRAW
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let visibleCandles = self.visibleCandles
        if visibleCandles.isEmpty { return }
        findTicks()
        gridCandles.removeAll()
        
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setLineWidth(2.0)
        ctx.strokeLineSegments(between: [CGPoint(x: rect.width, y: 0), CGPoint(x: rect.width, y: rect.height)])
        ctx.setLineWidth(1.0)
        
        
        var stringRects = [CGRect]()
        for tick in ticks {
            let candle = visibleCandles[tick]
            
            let string = getTickAttributedString(text: tickToText(tick: tick))
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
        chart.drawGridLines()
    }
    
    func update() {
        self.setNeedsDisplay()
    }
    

    
    
    
    
    
    
    
    
    func findTicks() {
        ticks.removeAll()
        
        let visibleCandles = self.visibleCandles
        
        let minDistance = getTickAttributedString(text: "20:30").size().width * 2.5
        let minDistanceTimeSpan = CGFloat(timeframe.toMinutes()) * minDistance / candleWidth
        
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
        let timespansInMinutes: [Int] = [Timeframe.monthly.toMinutes() * 12 * 2, Timeframe.monthly.toMinutes() * 12, Timeframe.monthly.toMinutes() * 6, Timeframe.monthly.toMinutes() * 4, Timeframe.monthly.toMinutes() * 3, Timeframe.monthly.toMinutes() * 2, Timeframe.monthly.toMinutes(), Timeframe.daily.toMinutes() * 15, Timeframe.daily.toMinutes() * 10, Timeframe.daily.toMinutes() * 5, Timeframe.daily.toMinutes() * 3, Timeframe.daily.toMinutes() * 2, Timeframe.daily.toMinutes(), Timeframe.twelveHourly.toMinutes(), Timeframe.sixHourly.toMinutes(), Timeframe.fourHourly.toMinutes(), Timeframe.hourly.toMinutes() * 3, Timeframe.twoHourly.toMinutes(), Timeframe.hourly.toMinutes(), Timeframe.thirtyMinutes.toMinutes(), Timeframe.fifteenMinutes.toMinutes(), Timeframe.oneMinute.toMinutes() * 10, Timeframe.fiveMinutes.toMinutes(), Timeframe.threeMinutes.toMinutes(), Timeframe.oneMinute.toMinutes() * 2, Timeframe.oneMinute.toMinutes()]
        
        var timeSpanIndex = 0
        for i in 0..<timespansInMinutes.count {
            let timespan = timespansInMinutes[i]
            if CGFloat(timespan) > minDistanceTimeSpan {
                timeSpanIndex = i
            }
        }
        
        
        
        for i in 0..<visibleCandles.count {
            let candle = visibleCandles[i]
            let candleDate = candle.openTime
            let minute = Calendar.current.component(.minute, from: candleDate)
            let hour = Calendar.current.component(.hour, from: candleDate)
            let day = Calendar.current.component(.day, from: candleDate)
            let month = Calendar.current.component(.month, from: candleDate)
            let year = Calendar.current.component(.year, from: candleDate)
            
            
            
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
        
        
        let allPossibleTimeTicks = [_2y, _1y, _6M, _4M, _3M, _2M, _1M, _15d, _10d, _5d, _3d, _2d, _1d, _12h, _6h, _4h, _3h, _2h, _1h, _30m, _15m, _10m, _5m, _3m, _2m, _1m]
        
        for tick in allPossibleTimeTicks[timeSpanIndex] {
            ticks.insert(tick)
        }
    }
    
    
    func tickToText(tick: Int) -> String {
        let candle = visibleCandles[tick]
        
        let time = candle.openTime
        let timeLocal = time.utcToLocal()
        var text = ""
        let minute = Calendar.current.component(.minute, from: time)
        let hour = Calendar.current.component(.hour, from: time)
        let day = Calendar.current.component(.day, from: time)
        let month = Calendar.current.component(.month, from: time)
        let year = Calendar.current.component(.year, from: time)
        let minuteL = Calendar.current.component(.minute, from: timeLocal)
        let hourL = Calendar.current.component(.hour, from: timeLocal)
        
        if (minute % 60 == 0) && (hour % 24 == 0) && (day == 1) && (month == 1) {
            text = String(year)
        } else if (minute % 60 == 0) && (hour % 24 == 0) && (day == 1) {
            text = Calendar.current.monthSymbols[month - 1]
            text = String(text[text.startIndex ..< text.index(text.startIndex, offsetBy: 3)])
        } else if (minute % 60 == 0) && (hour % 24 == 0) {
            text = String(day)
        } else if (minute % 60 == 0) {
            text = "\(hourL):\(minuteL)"
        } else {
            text = "\(hourL):\(minuteL)"
        }
        return text
    }
    
    
    
    
    func getTickAttributedString(text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11.0),
            NSAttributedString.Key.foregroundColor: UIColor.black
        ]
        
        let string = NSAttributedString(string: text, attributes: attributes)
        return string
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
