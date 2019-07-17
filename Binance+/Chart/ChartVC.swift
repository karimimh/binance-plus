//
//  ChartViewController.swift
//  Binance+
//
//  Created by Behnam Karimi on 12/22/1397 AP.
//  Copyright © 1397 AP Behnam Karimi. All rights reserved.
//

import UIKit
import SpriteKit
class ChartVC: UIViewController {
    
    // MARK: - Properties
    
    var app: App!
    var parentVC: ParentVC!
    
    var candles: [Candle] {
        get {
            return app.chartCandles
        }
        set {
            app.chartCandles = newValue
        }
    }
    var symbol: String! {
        get {
            return app.chartSymbol
        }
        set {
            app.chartSymbol = newValue
        }
    }
    var timeframe: Timeframe! {
        get {
            return app.chartTimeframe
        }
        set {
            app.chartTimeframe = newValue
        }
    }
    
    var symbolBBI: UIBarButtonItem!
    var timeframeBBI: UIBarButtonItem!
    var settingsBBI: UIBarButtonItem!
    
    var isRightContainerShowing: Bool = false
    
    var chart: Chart!
    
    
    var priceLineTimer: Timer?
    var candleWebSocket: WebSocket?
    
    private var currentChartSymbol: String = ""
    
    @IBOutlet weak var superV: UIView!
    @IBOutlet weak var chartView: UIView!
    @IBOutlet weak var rightContainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightContainer: UIView!
    @IBOutlet weak var rightContainerLeadingConstraint: NSLayoutConstraint!
    
    var rightContainerBestWidth: CGFloat {
        get {
            return rightContainerWidthConstraint.multiplier * UIScreen.main.bounds.width
        }
    }
    var rightContainerVC: UIViewController!
    
    var indicatorsVC: IndicatorsVC!
    var activeIndicator: Indicator?
    var navBarShadowLayer: CAShapeLayer!
    var colorPalletCVCCompletion: ((UIColor?) -> Void)?
    var coverView: UIView!
    var panBeganRightContainerX: CGFloat = 0
    
    var candleBadStreamCount = 0
    var currentKLineIsClosed = false
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.app = (UIApplication.shared.delegate as? AppDelegate)?.app
        self.parentVC = (UIApplication.shared.delegate as? AppDelegate)?.parentVC
        

        let rightContainerShadowLayer = CAShapeLayer()
        rightContainerShadowLayer.path = UIBezierPath(rect: rightContainer.bounds).cgPath
        rightContainerShadowLayer.shadowColor = UIColor.gray.cgColor
        rightContainerShadowLayer.shadowPath = rightContainerShadowLayer.path
        rightContainerShadowLayer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        rightContainerShadowLayer.shadowOpacity = 0.75
        rightContainerShadowLayer.shadowRadius = 15
        
        rightContainer.layer.insertSublayer(rightContainerShadowLayer, at: 0)
        
        
        
        let navBar = navigationController!.navigationBar
        
        navBarShadowLayer = CAShapeLayer()
        navBarShadowLayer.path = UIBezierPath(rect: navBar.bounds).cgPath
        navBarShadowLayer.shadowColor = UIColor.gray.cgColor
        navBarShadowLayer.shadowPath = navBarShadowLayer.path
        navBarShadowLayer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        navBarShadowLayer.shadowOpacity = 0.75
        navBarShadowLayer.shadowRadius = 5
        
        navBar.layer.insertSublayer(navBarShadowLayer, at: 0)
        
        
        if let navC = storyboard?.instantiateViewController(withIdentifier: "IndicatorsNavController") as? UINavigationController {
            addChild(navC)
            rightContainer.addSubview(navC.view)
            navC.didMove(toParent: self)
            navC.view.frame = CGRect(x: 0, y: 0, width: rightContainer.bounds.width, height: rightContainer.bounds.height + 49)
            navC.viewControllers.first?.view.frame = CGRect(x: 0, y: 0, width: rightContainer.bounds.width, height: rightContainer.bounds.height)

            if let indVC = navC.viewControllers.first as? IndicatorsVC {
                indVC.chartVC = self
                self.indicatorsVC = indVC
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self.chart = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.chart == nil || currentChartSymbol != app.chartSymbol {
            reloadChart()
        } else if let chart = self.chart {
            candleWebSocket?.open()
            priceLineTimer = Timer.scheduledTimer(timeInterval: TimeInterval(1), target: chart, selector: #selector(chart.handleCandleTimer), userInfo: nil, repeats: true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        candleWebSocket?.close()
        priceLineTimer?.invalidate()
    }
    
    
    // MARK: - Methods
    
    func reloadChart() {
        candleWebSocket?.close()
        candleWebSocket = nil
        priceLineTimer?.invalidate()
        priceLineTimer = nil
        self.candleBadStreamCount = 0

        
        if self.chart != nil {
            self.chart.alpha = 0.25
            
        }
//        for sv in chartView.subviews {
//            sv.removeFromSuperview()
//        }
        chartView.setNeedsLayout()
        
        
        setupBarButtons()
        settingsBBI.isEnabled = false
        
        let N = 500
        BinanaceApi.getCandles(symbol: app.getSymbol(app.chartSymbol)!, timeframe: app.chartTimeframe, limit: N < 1000 ? N : 1000) { (arr) in
            if let candles = arr {
                self.app.chartCandles = candles
                DispatchQueue.main.async {
                    if self.chart != nil {
                        self.chart.removeFromSuperview()
                        self.chart = nil
                    }
                    self.currentChartSymbol = self.app.chartSymbol
                    self.chart = Chart(frame: CGRect(x: 0, y: 0, width: 414, height: 623), app: self.app, chartVC: self)
                    self.chart.alpha = 1
                    self.chartView.addSubview(self.chart)
                    self.chart.translatesAutoresizingMaskIntoConstraints = false
                    self.chart.topAnchor.constraint(equalTo: self.chartView.topAnchor).isActive = true
                    self.chart.bottomAnchor.constraint(equalTo: self.chartView.bottomAnchor).isActive = true
                    self.chart.leadingAnchor.constraint(equalTo: self.chartView.leadingAnchor).isActive = true
                    self.chart.trailingAnchor.constraint(equalTo: self.chartView.trailingAnchor).isActive = true
                    self.indicatorsVC.indicatorsTableView.reloadData()
                    self.app.save()
                    self.settingsBBI.isEnabled = true
                }
            }
        }
        BinanaceApi.candlestickStream(symbolName: app.chartSymbol, timeframe: app.chartTimeframe) { (optionalWS, optionalJSON) in
            guard let json = optionalJSON else { optionalWS?.close(); return }
            guard self.chart != nil else { optionalWS?.close(); return }
            guard self.chart.isInitializationComplete else { optionalWS?.close(); return }
            self.candleWebSocket = optionalWS
            
            let symbolName = json["s"] as! String
            let kline = json["k"] as! [String: Any]
            
            let openTime = kline["t"] as! Int64
            let closeTime = kline["T"] as! Int64
            let interval = kline["i"] as! String
            
            let open = Decimal(string: kline["o"] as! String)!
            let close = Decimal(string: kline["c"] as! String)!
            let high = Decimal(string: kline["h"] as! String)!
            let low = Decimal(string: kline["l"] as! String)!
            
            let baseAssetVolume = Decimal(string: kline["v"] as! String)!
            let numberOfTrades = kline["n"] as! Int64
            let isThisKLineClosed = kline["x"] as! Bool
            let quoteAssetVolume = Decimal(string: kline["q"] as! String)!
            
            let latestCandleOpen = self.candles.last!.openTime.utcToLocal().toMillis()
            let nextCandleOpen = self.candles.last!.nextCandleOpenTime().utcToLocal().toMillis()
            
            if symbolName != self.symbol || interval != self.timeframe.rawValue ||
                (latestCandleOpen != openTime && nextCandleOpen != openTime) || (nextCandleOpen == openTime && !self.currentKLineIsClosed){
                self.candleBadStreamCount += 1
                if self.candleBadStreamCount <= 2 {
                    return
                }
                DispatchQueue.main.async {
                    self.reloadChart()
                }
                return
            }
            self.currentKLineIsClosed = isThisKLineClosed
            let candle = Candle(symbol: self.app.getSymbol(symbolName)!, timeframe: Timeframe(rawValue: interval)!, open: open, high: high, low: low, close: close, volume: baseAssetVolume, openTime: Date(timeIntervalSince1970: TimeInterval(openTime) / 1000), closeTime: Date(timeIntervalSince1970: TimeInterval(closeTime) / 1000), quoteAssetVolume: quoteAssetVolume, numberOfTrades: numberOfTrades, takerBuyBaseAssetVolume: 0, takerBuyQuoteAssetVolume: 0)
            
            if nextCandleOpen == openTime {
                self.candles.append(candle)
                self.chart.processVisibleCandles()
                for indicator in self.chart.indicators {
                    indicator.calculateIndicatorValue(candles: self.candles)
                }
                DispatchQueue.main.async {
                    self.chart.update()
                }
            } else {
                self.candles[self.candles.count - 1].closeTime =  Date(timeIntervalSince1970: TimeInterval(closeTime) / 1000)
                self.candles[self.candles.count - 1].open = open
                self.candles[self.candles.count - 1].close = close
                self.candles[self.candles.count - 1].high = high
                self.candles[self.candles.count - 1].low = low
                self.candles[self.candles.count - 1].volume = baseAssetVolume
                self.candles[self.candles.count - 1].quoteAssetVolume = quoteAssetVolume
                self.candles[self.candles.count - 1].numberOfTrades = numberOfTrades
                self.chart.processVisibleCandles()
                for indicator in self.chart.indicators {
                    indicator.calculateIndicatorValue(candles: self.candles)
                }
                DispatchQueue.main.async {
                    self.chart.update()
                }
            }
            
        }
    }
    
    
    
    func downloadExtraCandles(count: Int) {
        let N = (count < 1000) ? count : 1000
        let endTime = app.chartCandles.first!.openTime.utcToLocal().toMillis() - Int64(app.chartTimeframe.toMinutes()) * 60 * 1000
        let beginTime: Int64 = endTime - Int64(N) * Int64(app.chartTimeframe.toMinutes()) * 60 * 1000
        
        BinanaceApi.getCandles(symbol: app.getSymbol(app.chartSymbol)!, timeframe: app.chartTimeframe, startTime: beginTime, endTime: endTime) { (arr) in
            if let extraCandles = arr {
                DispatchQueue.main.sync {
                    self.app.chartCandles.insert(contentsOf: extraCandles, at: 0)
                    self.chart.firstVisibleCandleIndex += extraCandles.count
                    self.chart.latestVisibleCandleIndex += extraCandles.count
                    for indicator in self.chart.indicators {
                        indicator.calculateIndicatorValue(candles: self.chart.candles)
                    }
                    self.chart.update()
                    self.indicatorsVC.indicatorsTableView.reloadData()
                }
            }
            self.chart.isDownloadingExtraCandles = false
        }
    }
    
    
    
    
    
    // MARK: - Private Methods
    
    private func setupBarButtons() {
        symbolBBI = UIBarButtonItem(title: app.chartSymbol, style: .plain, target: self, action: #selector(searchBBIClicked(_:)))
        symbolBBI.tintColor = UIColor.black
        
        timeframeBBI = UIBarButtonItem(title: app.chartTimeframe.rawValue, style: .plain, target: self, action: #selector(timeframeBBIClicked(_:)))
        
        
        navigationController?.navigationBar.barTintColor = UIColor.white
        navigationItem.leftBarButtonItems = [symbolBBI, timeframeBBI]
        
        
        settingsBBI = UIBarButtonItem(image: UIImage(named: "menu"), style: .plain, target: self, action: #selector(settingsBBIClicked(_:)))
        
        
        
        navigationItem.rightBarButtonItems = [settingsBBI]
    }
    
    @IBAction func searchBBIClicked(_ sender: UIBarButtonItem) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "ChartSymbolVC") as? ChartSymbolVC else { return }
        vc.app = self.app
        vc.chartVC = self
        self.present(vc, animated: true, completion: nil)
    }
    

    @IBAction func timeframeBBIClicked(_ sender: UIBarButtonItem) {
        var options: [String] = Timeframe.allValues()
        parentVC.slideUpOptionsChooser(options: options, title: "Select Timeframe") { (index) in
//            self.priceLineTimer?.invalidate()
//            self.priceLineTimer = nil
//            self.candleWebSocket?.close()
//            self.candleWebSocket = nil
//
//            self.chart.removeFromSuperview()
//            self.chart = nil
//            self.chartView.setNeedsLayout()
            self.app.chartTimeframe = Timeframe(rawValue: options[index])!
            DispatchQueue.main.async {
                self.reloadChart()
                self.timeframeBBI.title = options[index]
            }
        }
        
    }

    @IBAction func settingsBBIClicked(_ sender: UIBarButtonItem) {
        if chart == nil { return }
        indicatorsVC.indicatorsTableView.reloadData()
        if !isRightContainerShowing {
            slideLeft()
        } else {
            slideRight()
        }
    }
    
    
    
    
    //MARK: - SlideLeft

    func slideLeft() {
        navBarShadowLayer.isHidden = true
        timeframeBBI.isEnabled = false
        symbolBBI.isEnabled = false
        isRightContainerShowing = true
        rightContainerLeadingConstraint.constant = -rightContainerBestWidth

        coverView = UIView(frame: chartView.bounds)
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .transitionCurlUp, animations: {
             self.view.layoutIfNeeded()
        }) { (_) in
            self.chartView.addSubview(self.coverView)
            self.coverView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:))))
            self.coverView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:))))
        }
    }
    
    
    func slideRight(completion: @escaping () -> Void = {}) {
        navBarShadowLayer.isHidden = false
        isRightContainerShowing = false
        rightContainerLeadingConstraint.constant = 15
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .transitionCurlUp, animations: {
            self.view.layoutIfNeeded()
        }) { (_) in
            self.coverView.removeFromSuperview()
            self.timeframeBBI.isEnabled = true
            self.symbolBBI.isEnabled = true
            self.app.save()
            completion()
        }
    }
    
    
    func slideBackLeft() {
        rightContainerLeadingConstraint.constant = -rightContainerBestWidth
        UIView.animate(withDuration: 0.1, delay: 0, options: .transitionCurlUp, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let indVC as IndicatorsVC:
            indVC.chartVC = self
            self.indicatorsVC = indVC
        case self:
            self.app.save()
        default:
            break
        }
    }
    
    
    
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        slideRight()
    }
    
    
    @IBAction func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let dx = recognizer.translation(in: self.view).x
        
        switch recognizer.state {
        case .began:
            panBeganRightContainerX = rightContainer.frame.origin.x
        case .changed:
            if panBeganRightContainerX + dx < chartView.bounds.width && panBeganRightContainerX + dx > chartView.bounds.width - rightContainerBestWidth {
                moveContainerView(by: dx)
            }
        case .ended:
            if dx > rightContainerBestWidth / 3 {
                slideRight()
            } else {
                slideBackLeft()
            }
        case .failed, .cancelled:
            slideRight()
        default:
            break
        }
    }
    
    private func moveContainerView(by dx: CGFloat) {
        rightContainerLeadingConstraint.constant = -rightContainerBestWidth + dx
        self.view.layoutIfNeeded()
    }
    
    
    
}
