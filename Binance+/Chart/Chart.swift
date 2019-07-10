//
//  ChartView.swift
//  Binance+
//
//  Created by Behnam Karimi on 2/11/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class Chart: UIView {
    var app: App
    
    //MARK: - Properties
    
    var symbol: Symbol {
        get {
            return app.getSymbol(app.chartSymbol)!
        }
        set {
            app.chartSymbol = newValue.name
        }
    }
    var timeframe: Timeframe {
        get {
            return app.chartTimeframe
        }
        set {
            app.chartTimeframe = newValue
        }
    }
    var candles: [Candle] {
        get {
            return app.chartCandles
        }
        set {
            app.chartCandles = newValue
        }
    }
    var highestPrice: Decimal {
        get {
            if app.chartHighestPrice == nil {
                app.chartHighestPrice = highestPriceOf(candles)// * Decimal(1 + app.chartTopMargin / 100.0)
            }
            return app.chartHighestPrice
        }
        set {
            app.chartHighestPrice = newValue
        }
    }
    var lowestPrice: Decimal {
        get {
            if app.chartLowestPrice == nil {
                app.chartLowestPrice = lowestPriceOf(candles)// * Decimal(1 - app.chartBottomMargin / 100.0)
            }
            return app.chartLowestPrice
        }
        set {
            app.chartLowestPrice = newValue
        }
    }
    var candleWidth: CGFloat {
        get {
            return app.chartCandleWidth
        }
        set {
            app.chartCandleWidth = newValue
        }
    }
    var indicators: [Indicator] {
        get {
            return app.chartIndicators
        }
        set {
            app.chartIndicators = newValue
        }
    }
    
    
    var mainFramePercentage: Double {
        get {
            var per: Double = 0
            for indicator in indicators {
                if indicator.frameRow == 0 { continue }
                per += indicator.frameHeightPercentage
            }
            return 100 - per
        }
    }
    
    var latestX: CGFloat {
        get {
            return app.chartLatestX
        }
        set {
            app.chartLatestX = newValue
        }
    }
    
    
    //views
    var mainView: MainView!
    var priceView: ValueView!
    var timeView: TimeView!
    var indicatorViews = [IndicatorView]()
    
    var autoButton: UIButton!
    
    
    var valueViewWidth: CGFloat = 0
    //saved variables
    var panBeganLatestX: CGFloat = 0
    var panBeganHighestPrice: Decimal = 0
    var panBeganLowestPrice: Decimal = 0
    var pinchBeganCandleWidth: CGFloat = 4
    var longPressBeganY: CGFloat = 0
    var longPressBeganFramePercentage: Double = 0
    var longPressBaganMainFramePercentage: Double = 100
    var frameConstraints = [NSLayoutConstraint]()
    var chartVC: ChartVC!
    
    var isDownloadingExtraCandles = false
    
    var reframingIndicatorView: IndicatorView?
    
    var chartAndIndicatorViewGestureRecognizers = [UIGestureRecognizer]()
    
    
    
    //MARK: - Initialization
    init(frame: CGRect, app: App, chartVC: ChartVC) {
        self.app = app
        self.chartVC = chartVC
        super.init(frame: frame)
        
        self.clipsToBounds = true
        additionalInit()
        self.backgroundColor = .white
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    private func additionalInit() {
        setCandlesX(latestX: latestX)
        
        mainView = MainView(chart: self)
        addSubview(mainView)
        
        priceView = ValueView(chart: self, tickSize: symbol.tickSize, highestValue: highestPrice, lowestValue: lowestPrice)
        addSubview(priceView)


        timeView = TimeView(chart: self)
        addSubview(timeView)
        
        
        
        autoButton = UIButton(type: .system)
        autoButton.setTitle("auto", for: .normal)
        if app.chartAutoScale {
            autoButton.tintColor = UIColor.blue
        } else {
            autoButton.tintColor = UIColor.black
        }
        autoButton.addTarget(self, action: #selector(handleAuto), for: .touchUpInside)
        addSubview(autoButton)
        
        layoutChart()
        

        //Gesture Recognizers:
        let gr1 = UIPanGestureRecognizer(target: self, action: #selector(chartHandlePan(_:)))
        mainView.addGestureRecognizer(gr1)
        let gr2 = UIPinchGestureRecognizer(target: self, action: #selector(chartHandlePinch(_:)))
        mainView.addGestureRecognizer(gr2)
        let gr3 = UIPanGestureRecognizer(target: self, action: #selector(priceViewHandlePan(_:)))
        priceView.addGestureRecognizer(gr3)
        let gr4 = UIPanGestureRecognizer(target: self, action: #selector(timeViewHandlePan(_:)))
        timeView.addGestureRecognizer(gr4)
        let gr5 = UILongPressGestureRecognizer(target: self, action: #selector(chartHandleLongPress(_:)))
        addGestureRecognizer(gr5)
        
        chartAndIndicatorViewGestureRecognizers.append(contentsOf: [gr1, gr2, gr3, gr4])
    }
    
    
    // MARK : - layout chart
    
    func layoutChart() {
        setupIndicatorViews()
        setupConstraints()
        update()
    }
    
    private func setupIndicatorViews() {
        for v in indicatorViews {
            v.removeFromSuperview()
        }
        indicatorViews.removeAll()
        
        
        for indicator in indicators {
            let v = IndicatorView(chart: self, indicator: indicator)
            indicatorViews.append(v)
            addSubview(v)
            if indicator.frameRow > 0 {
                addSubview(v.valueView)
                let gr1 = UIPanGestureRecognizer(target: self, action: #selector(indicatorViewHandlePan(_:)))
                v.addGestureRecognizer(gr1)
                let gr2 = UIPinchGestureRecognizer(target: self, action: #selector(indicatorViewHandlePinch(_:)))
                v.addGestureRecognizer(gr2)
                chartAndIndicatorViewGestureRecognizers.append(contentsOf: [gr1, gr2])
            }
        }
        bringSubviewToFront(mainView)
    }
    
    
    func setupConstraints() {
        if !frameConstraints.isEmpty {
            NSLayoutConstraint.deactivate(frameConstraints)
            frameConstraints.removeAll()
        }
        
        autoButton.removeFromSuperview()
        mainView.frame = CGRect(x: 0, y: 0, width: frame.width - valueViewWidth, height: (frame.height - TimeView.getHeight()) * CGFloat(mainFramePercentage / 100))
        
        timeView.translatesAutoresizingMaskIntoConstraints = false
        frameConstraints.append(contentsOf: [
            timeView.heightAnchor.constraint(equalToConstant: TimeView.getHeight()),
            timeView.leftAnchor.constraint(equalTo: leftAnchor),
            timeView.bottomAnchor.constraint(equalTo: bottomAnchor),
            timeView.rightAnchor.constraint(equalTo: mainView.rightAnchor)
            ])
        
        priceView.translatesAutoresizingMaskIntoConstraints = false
        frameConstraints.append(contentsOf: [
            priceView.rightAnchor.constraint(equalTo: rightAnchor),
            priceView.topAnchor.constraint(equalTo: topAnchor),
            priceView.heightAnchor.constraint(equalTo: mainView.heightAnchor),
            priceView.leftAnchor.constraint(equalTo: mainView.rightAnchor)
            ])
        
        
        for i in 0 ..< (indicatorViews.count) {
            let indicatorView = indicatorViews[i]
            let row = indicatorView.indicator.frameRow

            let topV: UIView
            if row == 0 {
                topV = self
            } else if row == 1 {
                topV = mainView
            } else {
                topV = getIndicatorView(frameRow: row - 1)
            }
            var m = CGFloat(indicatorView.indicator.frameHeightPercentage / 100)
            if row == 0 {
                m = CGFloat(mainFramePercentage / 100)
            }
            let cLeft = NSLayoutConstraint(item: indicatorView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0.0)
            let cRight = NSLayoutConstraint(item: indicatorView, attribute: .right, relatedBy: .equal, toItem: mainView, attribute: .right, multiplier: 1.0, constant: 0.0)
            let cTop = NSLayoutConstraint(item: indicatorView, attribute: .top, relatedBy: .equal, toItem: topV, attribute: (row == 0) ? .top : .bottom, multiplier: 1.0, constant: 0.0)
            let cHeight = NSLayoutConstraint(item: indicatorView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: m, constant: -TimeView.getHeight() * m)
            indicatorView.translatesAutoresizingMaskIntoConstraints = false
            frameConstraints.append(contentsOf: [cLeft, cRight, cTop, cHeight])
        }
        for i in 0 ..< indicatorViews.count {
            let valueView = indicatorViews[i].valueView
            
            let row = indicators[i].frameRow
            let topV: UIView
            if row == 0 {
                continue
            } else if row == 1 {
                topV = mainView
            } else {
                topV = getIndicatorView(frameRow: row - 1)
            }
            let cWidth = NSLayoutConstraint(item: valueView, attribute: .width, relatedBy: .equal, toItem: priceView, attribute: .width, multiplier: 1.0, constant: 0.0)
            let cRight = NSLayoutConstraint(item: valueView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0.0)
            let cTop = NSLayoutConstraint(item: valueView, attribute: .top, relatedBy: .equal, toItem: topV, attribute: .bottom, multiplier: 1.0, constant: 0.0)
            let cHeight = NSLayoutConstraint(item: valueView, attribute: .height, relatedBy: .equal, toItem: indicatorViews[i], attribute: .height, multiplier: 1.0, constant: 0)
            
            valueView.translatesAutoresizingMaskIntoConstraints = false
            frameConstraints.append(contentsOf: [cWidth, cRight, cTop, cHeight])
        }
        
        if let iv = reframingIndicatorView, let v = iv.handleView {
            v.translatesAutoresizingMaskIntoConstraints = false
            let cL = v.leadingAnchor.constraint(equalTo: leadingAnchor)
            let cT = v.trailingAnchor.constraint(equalTo: trailingAnchor)
            let cC = v.centerYAnchor.constraint(equalTo: iv.topAnchor)
            let cH = v.heightAnchor.constraint(equalToConstant: 4)
            frameConstraints.append(contentsOf: [cL, cT, cC, cH])
        }
        
        
        addSubview(autoButton)
        autoButton.translatesAutoresizingMaskIntoConstraints = false
        let c1 = autoButton.bottomAnchor.constraint(equalTo: timeView.bottomAnchor)
        let c2 = autoButton.trailingAnchor.constraint(equalTo: trailingAnchor)
        let c3 = autoButton.leadingAnchor.constraint(equalTo: timeView.trailingAnchor)
        let c4 = autoButton.topAnchor.constraint(equalTo: timeView.topAnchor)
        frameConstraints.append(contentsOf: [c1, c2, c3, c4])
        
        NSLayoutConstraint.activate(frameConstraints)
    }
    
    
    
    //MARK: - Frame Update
    func update() {
        setCandlesX(latestX: mainView.latestCandleX)
        
        mainView.frame = CGRect(x: 0, y: 0, width: frame.width - valueViewWidth, height: (frame.height - TimeView.getHeight()) * CGFloat(mainFramePercentage / 100))
        
        if app.chartAutoScale {
            let visibleCandles = mainView.calculateVisibleCandles()
            highestPrice = highestPriceOf(visibleCandles)// * Decimal(1 + app.chartTopMargin / 100)
            lowestPrice = lowestPriceOf(visibleCandles)// * Decimal(1 - app.chartBottomMargin / 100)
            let diff = highestPrice - lowestPrice
            let u = diff * Decimal(app.chartTopMargin / 100)
            let l = diff * Decimal(app.chartBottomMargin / 100)
            highestPrice = highestPrice + u
            lowestPrice = lowestPrice - l
        }
        
        
        priceView.update(newhighestValue: highestPrice, newLowestValue: lowestPrice)
        timeView.update()
        
    }
    
    //MARK: - Handle Touches
    @IBAction func chartHandlePan(_ recognizer: UIPanGestureRecognizer) {
        let tr = recognizer.translation(in: self)
        let dx = tr.x
        let dy = tr.y
        
        switch recognizer.state {
        case .began:
            panBeganLatestX = mainView.latestCandleX
            panBeganLowestPrice = lowestPrice
            panBeganHighestPrice = highestPrice
            break
        case .changed:
            let newLatestCandleX = panBeganLatestX + dx
            let newFirstCandleX = newLatestCandleX - (candleWidth * 4 / 3) * CGFloat(candles.count)
            if !(newLatestCandleX > 0) {
                return
            }
            
            if newFirstCandleX >= 0 && !isDownloadingExtraCandles {
                self.chartVC.downloadExtraCandles(count: getNumberOfPossibleVisibleCandles())
                self.isDownloadingExtraCandles = true
            }
            mainView.latestCandleX = newLatestCandleX
            if !app.chartAutoScale {
                let d = Decimal(Double(dy / mainView.bounds.height))
                let priceDy = (panBeganHighestPrice - panBeganLowestPrice) * d
                highestPrice = panBeganHighestPrice + priceDy
                lowestPrice = panBeganLowestPrice + priceDy
                
            }
            update()
        case .ended, .failed, .cancelled:
            app.save()
        default:
            break
        }
    }
    
    
    @IBAction func chartHandlePinch(_ recognizer: UIPinchGestureRecognizer) {
        let scale = recognizer.scale
        
        
        switch recognizer.state {
        case .began:
            pinchBeganCandleWidth = candleWidth
            panBeganLatestX = mainView.latestCandleX
        case .changed:
            if pinchBeganCandleWidth * scale < 0.6 { return }
            candleWidth = pinchBeganCandleWidth * scale
            let newLatestCandleX = panBeganLatestX * (1 + scale) / 2
            let newFirstCandleX = newLatestCandleX - (candleWidth * 4 / 3) * CGFloat(candles.count)
            if !(newLatestCandleX > 0) {
                return
            }
            
            if newFirstCandleX >= 0 && !isDownloadingExtraCandles {
                self.chartVC.downloadExtraCandles(count: getNumberOfPossibleVisibleCandles())
                self.isDownloadingExtraCandles = true
            }
            mainView.latestCandleX = newLatestCandleX
            update()
        case .ended, .failed, .cancelled:
            app.save()
        default:
            break
        }
    }
    
    
    @IBAction func priceViewHandlePan(_ recognizer: UIPanGestureRecognizer) {
        let tr = recognizer.translation(in: self)
        let dy = tr.y
        
        switch recognizer.state {
        case .began:
            app.chartAutoScale = false
            autoButton.tintColor = UIColor.black
            
            panBeganLowestPrice = lowestPrice
            panBeganHighestPrice = highestPrice
        case .changed:
            let d = Decimal(Double(dy / UIScreen.main.bounds.height))
            highestPrice = panBeganHighestPrice * (1 + d)
            lowestPrice = panBeganLowestPrice * (1 - d)
            
            update()
        case .ended:
            break
        case .failed, .cancelled:
            app.chartAutoScale = true
            update()
        default:
            break
        }
    }
    
    @IBAction func timeViewHandlePan(_ recognizer: UIPanGestureRecognizer) {
        let tr = recognizer.translation(in: self)
        let dx = tr.x
        let scale = 1 - dx / timeView.bounds.width
        
        switch recognizer.state {
        case .began:
            pinchBeganCandleWidth = candleWidth
        case .changed:
            if pinchBeganCandleWidth * scale < 0.6 { return }
            candleWidth = pinchBeganCandleWidth * scale
            
            let newFirstCandleX = latestX - (candleWidth * 4 / 3) * CGFloat(candles.count)
            if newFirstCandleX >= 0 && !isDownloadingExtraCandles {
                self.chartVC.downloadExtraCandles(count: getNumberOfPossibleVisibleCandles())
                self.isDownloadingExtraCandles = true
            }
            
            update()
        case .ended, .cancelled, .failed:
            app.save()
        default:
            break
        }
    }
    
    
    
    @IBAction func indicatorViewHandlePan(_ recognizer: UIPanGestureRecognizer) {
        let tr = recognizer.translation(in: self)
        let dx = tr.x
        
        switch recognizer.state {
        case .began:
            panBeganLatestX = mainView.latestCandleX
            break
        case .changed:
            let newLatestCandleX = panBeganLatestX + dx
            let newFirstCandleX = newLatestCandleX - (candleWidth * 4 / 3) * CGFloat(candles.count)
            if !(newLatestCandleX > 0) {
                return
            }
            
            if newFirstCandleX >= 0 && !isDownloadingExtraCandles {
                self.chartVC.downloadExtraCandles(count: getNumberOfPossibleVisibleCandles())
                self.isDownloadingExtraCandles = true
            }
            mainView.latestCandleX = newLatestCandleX
            update()
        case .ended, .failed, .cancelled:
            app.save()
        default:
            break
        }
    }
    
    
    @IBAction func indicatorViewHandlePinch(_ recognizer: UIPinchGestureRecognizer) {
        let scale = recognizer.scale
        
        
        switch recognizer.state {
        case .began:
            pinchBeganCandleWidth = candleWidth
            panBeganLatestX = mainView.latestCandleX
        case .changed:
            if pinchBeganCandleWidth * scale < 0.6 { return }
            candleWidth = pinchBeganCandleWidth * scale
            let newLatestCandleX = panBeganLatestX * (1 + scale) / 2
            let newFirstCandleX = newLatestCandleX - (candleWidth * 4 / 3) * CGFloat(candles.count)
            if !(newLatestCandleX > 0) {
                return
            }
            
            if newFirstCandleX >= 0 && !isDownloadingExtraCandles {
                self.chartVC.downloadExtraCandles(count: getNumberOfPossibleVisibleCandles())
                self.isDownloadingExtraCandles = true
            }
            mainView.latestCandleX = newLatestCandleX
            update()
        case .ended, .cancelled, .failed:
            app.save()
        default:
            break
        }
    }
    
    @IBAction func chartHandleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        switch recognizer.state {
        case .began:
            for gr in chartAndIndicatorViewGestureRecognizers {
                gr.isEnabled = false
            }
            let l = recognizer.location(in: self)
            var indicatorView: IndicatorView?
            for iv in indicatorViews {
                if iv.indicator.frameRow == 0 { continue }
                let f = CGRect(x: iv.frame.origin.x, y: iv.frame.origin.y - 10, width: iv.frame.width, height: 20)
                if f.contains(l) {
                    indicatorView = iv
                    break
                }
            }
            
            guard let iv = indicatorView else {
                return
            }
            
            let v = UIView(frame: CGRect.zero)
            v.backgroundColor = UIColor.black
            addSubview(v)
            
            reframingIndicatorView = iv
            
            iv.handleView = v
            longPressBeganY = l.y
            longPressBeganFramePercentage = iv.indicator.frameHeightPercentage
            longPressBaganMainFramePercentage = mainFramePercentage
            
            setupConstraints()
            update()
        case .changed:
            guard let iv = reframingIndicatorView else { return }
            let l = recognizer.location(in: self)
            let dy = longPressBeganY - l.y
            let p = Double(dy / bounds.height) * 100
            let newP = p + longPressBeganFramePercentage
            if (longPressBaganMainFramePercentage + longPressBeganFramePercentage) - newP < 20 || newP < 5 {
                return
            }
            iv.indicator.frameHeightPercentage = newP
            setupConstraints()
            update()
        case .ended, .cancelled, .failed:
            for gr in chartAndIndicatorViewGestureRecognizers {
                gr.isEnabled = true
            }
            if let iv = reframingIndicatorView {
                iv.handleView.removeFromSuperview()
                iv.handleView = nil
                reframingIndicatorView = nil
            }
            setupConstraints()
            update()
            app.save()
        default:
            break
        }
    }
    
    
    
    
    
    

    @IBAction func handleAuto() {
        app.chartAutoScale = !app.chartAutoScale
        if app.chartAutoScale {
            autoButton.tintColor = UIColor.blue
        } else {
            autoButton.tintColor = UIColor.black
        }
        update()
    }
    //MARK: - Private Methods
    func isVisible(candle: Candle) -> Bool {
        return candle.x >= 0 && candle.x < mainView.bounds.width
    }
    
    
    private func setCandlesX(latestX: CGFloat) {
        let spacing = candleWidth / 3
        for j in 0 ... (candles.count - 1) {
            let i = (candles.count - 1) - j
            let candle = candles[i]
            let x = latestX - (spacing + candleWidth) * CGFloat(j)
            candle.x = x
        }
    }
    
    
    private func y(price: Decimal, frameHeight: CGFloat, highestPrice: Decimal, lowestPrice: Decimal) -> CGFloat {
        let ratio = ((highestPrice - price) / (highestPrice - lowestPrice)).cgFloatValue
        return frameHeight * ratio
    }
    
    
    private func highestPriceOf(_ candles: [Candle]) -> Decimal {
        var highestPrice: Decimal = -1
        for i in 0..<candles.count {
            let candle = candles[i]
            if candle.high > highestPrice {
                highestPrice = candle.high
            }
        }
        return highestPrice
    }
    
    private func lowestPriceOf(_ candles: [Candle]) -> Decimal {
        var lowestPrice = highestPriceOf(candles)
        for i in 0..<candles.count {
            let candle = candles[i]
            if candle.low < lowestPrice {
                lowestPrice = candle.low
            }
        }
        return lowestPrice
    }
    
    private func calculateTimeViewHeight() -> CGFloat {
        let l = UILabel()
        l.text = "HELLO|"
        l.sizeToFit()
        let h = l.bounds.height
        return h * 2
    }
    func calculateVisibleCandles() -> [Candle] {
        var result = [Candle]()
        for candle in candles {
            if candle.x >= 0 && candle.x < frame.width {
                result.append(candle)
            }
        }
        return result
    }
    
    private func getBottomView() -> UIView {
        var r = 0
        var result: UIView = mainView
        for iv in indicatorViews {
            if iv.indicator.frameRow >= r {
                r = iv.indicator.frameRow
                result = iv
            }
        }
        
        return result
    }
    
    private func getIndicatorView(frameRow: Int) -> IndicatorView {
        for iv in indicatorViews {
            if iv.indicator.frameRow == frameRow {
                return iv
            }
        }
        return indicatorViews[0]
    }
    
    func getNonZeroRowIndicatorViews() -> [IndicatorView] {
        var result = [IndicatorView]()
        for iv in indicatorViews {
            if iv.indicator.frameRow != 0 {
                result.append(iv)
            }
        }
        return result
    }
    
    func getNextRow() -> Int {
        var r = 0
        for iv in getNonZeroRowIndicatorViews() {
            if iv.indicator.frameRow > r {
                r = iv.indicator.frameRow
            }
        }
        return r + 1
    }
    
    func getNumberOfPossibleVisibleCandles() -> Int {
        if bounds.width > 0 {
            return Int(bounds.width / CGFloat(candleWidth * 4 / 3))
        } else {
            return Int(UIScreen.main.bounds.width / CGFloat(candleWidth * 4 / 3))
        }
    }
}
