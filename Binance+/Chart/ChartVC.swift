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
    
    var symbolBBI: UIBarButtonItem!
    var timeframeBBI: UIBarButtonItem!
    var settingsBBI: UIBarButtonItem!
    
    var isRightContainerShowing: Bool = false
    
    var chart: Chart!
    var tabbarVC: TabBarVC!
    var parentVC: ParentVC!
    
    
    
    var priceLineTimer: Timer!
    
    
    
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
    
    var colorPalletCVCCompletion: ((UIColor?) -> Void)?
    var blurEffectView: UIVisualEffectView!
    var panBeganRightContainerX: CGFloat = 0
    
    
    
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()

            
        tabbarVC = tabBarController as? TabBarVC
        parentVC = tabbarVC.parentVC
        
        app = tabbarVC.app!
        
        let rightContainerShadowLayer = CAShapeLayer()
        rightContainerShadowLayer.path = UIBezierPath(rect: rightContainer.bounds).cgPath
        rightContainerShadowLayer.shadowColor = UIColor.gray.cgColor
        rightContainerShadowLayer.shadowPath = rightContainerShadowLayer.path
        rightContainerShadowLayer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        rightContainerShadowLayer.shadowOpacity = 0.75
        rightContainerShadowLayer.shadowRadius = 15
        
        rightContainer.layer.insertSublayer(rightContainerShadowLayer, at: 0)
        
        
        
        let navBar = navigationController!.navigationBar
        
        let navBarShadowLayer = CAShapeLayer()
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if app != nil && self.chart == nil && self.chartView != nil {
            reloadChart()
        } else {
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                delegate.candleWebSocket?.open()
            }
            if priceLineTimer != nil {
                if let chart = self.chart {
                    priceLineTimer = Timer.scheduledTimer(timeInterval: TimeInterval(1), target: chart, selector: #selector(chart.handleCandleTimer), userInfo: nil, repeats: true)
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.candleWebSocket?.close()
        }
        if priceLineTimer != nil && priceLineTimer.isValid {
            priceLineTimer.invalidate()
        }
    }
    
    
    // MARK: - Methods
    
    func reloadChart() {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.candleWebSocket?.close()
            delegate.candleWebSocket = nil
        }
        if priceLineTimer != nil {
            priceLineTimer.invalidate()
            priceLineTimer = nil
        }
        if app == nil {
            tabbarVC = tabBarController as? TabBarVC
            parentVC = tabbarVC.parentVC
            app = tabbarVC.app!
        }
        
        
        if self.chart != nil {
            chart.removeFromSuperview()
            chart = nil
        }
        for sv in chartView.subviews {
            sv.removeFromSuperview()
        }
        chartView.setNeedsLayout()
        
        
        setupBarButtons()
        settingsBBI.isEnabled = false
        
        let N = 500
        BinanaceApi.getCandles(symbol: app.getSymbol(app.chartSymbol)!, timeframe: app.chartTimeframe, limit: N < 1000 ? N : 1000) { (arr) in
            if let candles = arr {
                self.app.chartCandles = candles
                DispatchQueue.main.async {
                    self.chart = Chart(frame: CGRect(x: 0, y: 0, width: 414, height: 623), app: self.app, chartVC: self)
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
        
        
        settingsBBI = UIBarButtonItem(image: UIImage(named: "menu"), style: .plain, target: self, action: #selector(indicatorsBBIClicked(_:)))
        
        
        
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
            self.app.chartTimeframe = Timeframe(rawValue: options[index])!
            self.timeframeBBI.title = options[index]
            self.app.save()
            self.reloadChart()
        }
        
    }

    @IBAction func indicatorsBBIClicked(_ sender: UIBarButtonItem) {
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
        timeframeBBI.isEnabled = false
        symbolBBI.isEnabled = false
        isRightContainerShowing = true
        rightContainerLeadingConstraint.constant = -rightContainerBestWidth
        
        let blurEffect = UIBlurEffect(style: .prominent)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = chartView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.alpha = 0.5
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .transitionCurlUp, animations: {
             self.view.layoutIfNeeded()
        }) { (_) in
            self.chartView.addSubview(self.blurEffectView)
            self.blurEffectView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:))))
            self.blurEffectView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:))))
        }
    }
    
    
    func slideRight(completion: @escaping () -> Void = {}) {
        isRightContainerShowing = false
        rightContainerLeadingConstraint.constant = 15
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .transitionCurlUp, animations: {
            self.view.layoutIfNeeded()
        }) { (_) in
            self.blurEffectView.removeFromSuperview()
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
