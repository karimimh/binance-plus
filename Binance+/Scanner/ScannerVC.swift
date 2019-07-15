//
//  ScannerVC.swift
//  Binance+
//
//  Created by Behnam Karimi on 2/16/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class ScannerVC: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    @IBOutlet weak var scannerResultTableView: UITableView!
    
    @IBOutlet weak var listBBI: UIBarButtonItem!
    var tabBarVC: TabBarVC!
    var parentVC: ParentVC!
    var app: App! {
        get {
            return parentVC.app
        }
    }
    
    var symbolsFound = [String]()
    var filterIndex = 0
    
    var tableSymbols = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBarVC = (tabBarController as? TabBarVC)
        parentVC = (tabBarVC.parent as? ParentVC)
        
        
        scannerResultTableView.delegate = self
        scannerResultTableView.dataSource = self
        scannerResultTableView.allowsSelection = true
        scannerResultTableView.tableFooterView = UIView()
        
        
        if app.scannerList == nil {
            app.scannerList = app.activeList
        }
        listBBI.title = app.scannerList.name
        
        
        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = .fromHex(hex: "#D0D0D0")
        refreshControl.addTarget(self, action: #selector(refreshButtonPressed(_:)), for: .valueChanged)
        scannerResultTableView.refreshControl = refreshControl
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if symbolsFound.isEmpty {
            tableView.setEmptyView(title: "No Symbols Found ⚠︎", message: "Modify Filters")
        }
        else {
            tableView.restore()
        }
        return tableSymbols.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScannerSymbolTVCell", for: indexPath) as! PickSymbolTVCell
        let symbolName = tableSymbols[indexPath.row]
        cell.label.text = symbolName
        let symbol = app.getSymbol(symbolName)!
        if let image = symbol.iconImage {
            cell.iconIV.image = image
        } else {
            if let image = UIImage(named: symbol.baseAsset.lowercased() + ".png") {
                symbol.iconImage = image
            } else {
                symbol.iconImage = UIImage()
            }
            cell.iconIV.image = symbol.iconImage
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell  = tableView.cellForRow(at: indexPath) as! PickSymbolTVCell
        let symName = cell.label.text!
        guard let symbol = app.getSymbol(symName) else { return }
        tabBarVC.selectedIndex = 1
        parentVC.slideRightPanGR.isEnabled = false
        guard let navVC = tabBarVC.viewControllers?[1] as? UINavigationController else { print("no nav!");return }
        guard let vc = navVC.visibleViewController as? ChartVC else { print("NoChartVC"); return }
        app.chartSymbol = symbol.name
        if vc.chartView != nil {
            vc.reloadChart()
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    
    func refresh() {
        filterIndex = 0
        tableSymbols.removeAll()
        symbolsFound.removeAll()
        scannerResultTableView.reloadData()
        
        symbolsFound.append(contentsOf: app.scannerList.symbols)
        progress()
    }
    
    
    private func progress() {
        if filterIndex >= app.scannerFilters.count || symbolsFound.isEmpty {
            tableSymbols.append(contentsOf: symbolsFound)
            DispatchQueue.main.async {
                self.scannerResultTableView.reloadData()
                self.scannerResultTableView.refreshControl?.endRefreshing()
            }
            return
        }
        
        let filter = app.scannerFilters[filterIndex]
        var symbolsFoundS = [Symbol]()
        for sym in symbolsFound {
            symbolsFoundS.append(app.getSymbol(sym)!)
        }
        BinanaceApi.getCandlesForSymbols(symbolsFoundS, timeframe: filter.timeframe) { (downloadedCandles) in
            var candles = [String: [Candle]]()
            for item in downloadedCandles {
                var newArr = [Candle]()
                for i in 0 ..< item.value.count - 1 {
                    newArr.append(item.value[i])
                }
                candles[item.key] = newArr
            }
            DispatchQueue.global(qos: .background).async {
                self.checkFilter(filter: filter, allCandles: candles)
                self.filterIndex += 1
                self.progress()
            }
        }
    }
    
    private func checkFilter(filter: ScannerFilter, allCandles: [String: [Candle]]) {
        var removedSymbols = [String]()
        switch filter.type {
        case .volume24h:
            for symbolName in symbolsFound {
                let symbol = app.getSymbol(symbolName)!
                switch filter.relationship {
                case .greaterThan:
                    if symbol.btcVolume(app) <= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                case .lessThan:
                    if symbol.btcVolume(app) >= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                }
            }
        case .price:
            for symbolName in symbolsFound {
                let symbol = app.getSymbol(symbolName)!
                switch filter.relationship {
                case .greaterThan:
                    if symbol.btcPrice(app) <= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                case .lessThan:
                    if symbol.btcPrice(app) >= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                }
            }
        case .rsi:
            for i in 0 ..< symbolsFound.count {
                let symbolName = symbolsFound[i]
                var data = [Decimal]()
                for candle in allCandles[symbolName]! {
                    data.append(candle.close)
                }
                let length = filter.properties[Indicator.PropertyKey.length] as! Int
                if data.count <= length {
                    removedSymbols.append(symbolName)
                    continue
                }
                let rsiArray = Indicators.rsi(data: data, length: length)
                let rsi = rsiArray.last!
                switch filter.relationship {
                case .greaterThan:
                    if rsi <= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                case .lessThan:
                    if rsi >= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                }
            }
        case .rsi_divergence:
            for i in 0 ..< symbolsFound.count {
                let symbolName = symbolsFound[i]
                var data = [Decimal]()
                for candle in allCandles[symbolName]! {
                    data.append(candle.close)
                }
                let length = filter.properties[Indicator.PropertyKey.length] as! Int
                if data.count <= length {
                    removedSymbols.append(symbolName)
                    continue
                }
                let rsi = Indicators.rsi(data: data, length: length)
                let bullOrBear = filter.properties[Indicator.PropertyKey.bullishOrBearish] as! String
                
                var x = rsi.count - 2
                while x > rsi.count - 6 && x > 2 {
                    if bullOrBear == "Bullish" {
                        if rsi[x] > filter.rValue {
                            x -= 1
                            continue
                        }
                    } else {
                        if rsi[x] < filter.rValue {
                            x -= 1
                            continue
                        }
                    }
                    if rsi[x] < rsi[x - 1] && rsi[x] < rsi[x + 1] && data[x] < data[x + 1] && data[x] < data[x - 1] {
                        break
                    }
                    
                    x -= 1
                }
                
                var y = x - 2
                var divIndex = -1
                while y > 0 {
                    if rsi[y] < rsi[y - 1] && rsi[y] < rsi[y + 1] && data[y] < data[y + 1] && data[y] < data[y - 1] &&
                        rsi[y] < rsi[x] && data[y] > data[x] {
                        divIndex = y
                        break
                    }
                    y -= 1
                }
                
                if divIndex == -1 {
                    removedSymbols.append(symbolName)
                    continue
                }
                
                for t in (divIndex + 1) ..< x {
                    let lineRSI = rsi[divIndex] + (rsi[x] - rsi[divIndex]) * Decimal(t - divIndex) / Decimal(x - divIndex)
                    if rsi[t] < lineRSI {
                        removedSymbols.append(symbolName)
                        break
                    }
                }
                
            }
        case .macd_bar:
            for i in 0 ..< symbolsFound.count {
                let symbolName = symbolsFound[i]
                var data = [Decimal]()
                for candle in allCandles[symbolName]! {
                    data.append(candle.close)
                }
                let fastLength = filter.properties[Indicator.PropertyKey.fastLength] as! Int
                let slowLength = filter.properties[Indicator.PropertyKey.slowLength] as! Int
                let signalSmoothingLength = filter.properties[Indicator.PropertyKey.signalSmoothingLength] as! Int
                if data.count <= slowLength + signalSmoothingLength {
                    removedSymbols.append(symbolName)
                    continue
                }
                
                let macdArray = Indicators.macd(data: data, fastLength: fastLength, slowLength: slowLength, signalSmoothingLength: signalSmoothingLength)
                
                let macd = macdArray.last!
                
                
                switch filter.relationship {
                case .greaterThan:
                    if macd.0 - macd.1 <= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                case .lessThan:
                    if macd.0 - macd.1 >= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                }
            }
        case .macd_line:
            for i in 0 ..< symbolsFound.count {
                let symbolName = symbolsFound[i]
                var data = [Decimal]()
                for candle in allCandles[symbolName]! {
                    data.append(candle.close)
                }
                let fastLength = filter.properties[Indicator.PropertyKey.fastLength] as! Int
                let slowLength = filter.properties[Indicator.PropertyKey.slowLength] as! Int
                let signalSmoothingLength = filter.properties[Indicator.PropertyKey.signalSmoothingLength] as! Int
                if data.count <= slowLength + signalSmoothingLength {
                    removedSymbols.append(symbolName)
                    continue
                }
                let macdArray = Indicators.macd(data: data, fastLength: fastLength, slowLength: slowLength, signalSmoothingLength: signalSmoothingLength)
                let macd = macdArray.last!
                
                switch filter.relationship {
                case .greaterThan:
                    if macd.0 <= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                case .lessThan:
                    if macd.0 >= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                }
            }
        case .macd_signal:
            for i in 0 ..< symbolsFound.count {
                let symbolName = symbolsFound[i]
                var data = [Decimal]()
                for candle in allCandles[symbolName]! {
                    data.append(candle.close)
                }
                let fastLength = filter.properties[Indicator.PropertyKey.fastLength] as! Int
                let slowLength = filter.properties[Indicator.PropertyKey.slowLength] as! Int
                let signalSmoothingLength = filter.properties[Indicator.PropertyKey.signalSmoothingLength] as! Int
                if data.count <= slowLength + signalSmoothingLength {
                    removedSymbols.append(symbolName)
                    continue
                }
                
                let macdArray = Indicators.macd(data: data, fastLength: fastLength, slowLength: slowLength, signalSmoothingLength: signalSmoothingLength)
                let macd = macdArray.last!
                
                switch filter.relationship {
                case .greaterThan:
                    if macd.1 <= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                case .lessThan:
                    if macd.1 >= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                }
            }
            
        case .upper_boll_band_minus_candle_close:
            for i in 0 ..< symbolsFound.count {
                let symbolName = symbolsFound[i]
                var data = [Decimal]()
                for candle in allCandles[symbolName]! {
                    data.append(candle.close)
                }
                let fastLength = filter.properties[Indicator.PropertyKey.fastLength] as! Int
                let slowLength = filter.properties[Indicator.PropertyKey.slowLength] as! Int
                if data.count <= fastLength {
                    removedSymbols.append(symbolName)
                    continue
                }
                
                let bbArray = Indicators.bollinger_bands(data: data, length: fastLength, stdDev: slowLength)
                let bb = bbArray.last!

                switch filter.relationship {
                case .greaterThan:
                    if bb.0 - allCandles[symbolName]!.last!.close <= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                case .lessThan:
                    if bb.0 - allCandles[symbolName]!.last!.close >= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                }
            }
            
        case .lower_boll_band_minus_candle_close:
            for i in 0 ..< symbolsFound.count {
                let symbolName = symbolsFound[i]
                var data = [Decimal]()
                for candle in allCandles[symbolName]! {
                    data.append(candle.close)
                }
                let fastLength = filter.properties[Indicator.PropertyKey.fastLength] as! Int
                let slowLength = filter.properties[Indicator.PropertyKey.slowLength] as! Int
                if data.count <= fastLength {
                    removedSymbols.append(symbolName)
                    continue
                }
                let bbArray = Indicators.bollinger_bands(data: data, length: fastLength, stdDev: slowLength)
                let bb = bbArray.last!
                
                switch filter.relationship {
                case .greaterThan:
                    if bb.2 - allCandles[symbolName]!.last!.close <= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                case .lessThan:
                    if bb.2 - allCandles[symbolName]!.last!.close >= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                }
            }
            
        case .ema_difference:
            for i in 0 ..< symbolsFound.count {
                let symbolName = symbolsFound[i]
                var data = [Decimal]()
                for candle in allCandles[symbolName]! {
                    data.append(candle.close)
                }
                let fastLength = filter.properties[Indicator.PropertyKey.fastLength] as! Int
                let slowLength = filter.properties[Indicator.PropertyKey.slowLength] as! Int
                if data.count <= fastLength || data.count <= slowLength {
                    removedSymbols.append(symbolName)
                    continue
                }
                
                let ema1 = Indicators.ema(data: data, length: fastLength)
                let ema2 = Indicators.ema(data: data, length: slowLength)
                
                let emaDiff = ema1.last! - ema2.last!
                
                switch filter.relationship {
                case .greaterThan:
                    if emaDiff <= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                case .lessThan:
                    if emaDiff >= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                }
            }
            
        case .avg_volume:
            for i in 0 ..< symbolsFound.count {
                let symbolName = symbolsFound[i]
                let symbol = app.getSymbol(symbolName)!
                var data = [Decimal]()
                for candle in allCandles[symbolName]! {
                    data.append(app.getVolumeInBTC(symbol: symbol, baseVolume: candle.volume))
                }
                let length = filter.properties[Indicator.PropertyKey.length] as! Int
                if data.count <= length {
                    removedSymbols.append(symbolName)
                    continue
                }
                
                let sma = Indicators.sma(data: data, length: length)
                
                switch filter.relationship {
                case .greaterThan:
                    if sma.last! <= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                case .lessThan:
                    if sma.last! >= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                }
            }
            
        case .relative_volume:
            for i in 0 ..< symbolsFound.count {
                let symbolName = symbolsFound[i]
                let symbol = app.getSymbol(symbolName)!
                var data = [Decimal]()
                for candle in allCandles[symbolName]! {
                    data.append(app.getVolumeInBTC(symbol: symbol, baseVolume: candle.volume))
                }
                let length = filter.properties[Indicator.PropertyKey.length] as! Int
                if data.count <= length {
                    removedSymbols.append(symbolName)
                    continue
                }
                
                let sma = Indicators.sma(data: data, length: length)
                
                switch filter.relationship {
                case .greaterThan:
                    if data.last! / sma.last! <= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                case .lessThan:
                    if data.last! / sma.last! >= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                }
            }
        case .green_candle:
            for i in 0 ..< symbolsFound.count {
                let symbolName = symbolsFound[i]
                if allCandles[symbolName]!.isEmpty {
                    removedSymbols.append(symbolName)
                    continue
                }
                
                let latestCandle = allCandles[symbolName]!.last!
                
                switch filter.relationship {
                case .greaterThan:
                    if latestCandle.close - latestCandle.open <= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                case .lessThan:
                    if latestCandle.close - latestCandle.open >= filter.rValue {
                        removedSymbols.append(symbolName)
                    }
                }
            }
        }
        
        symbolsFound.removeAll { (s) -> Bool in
            return removedSymbols.contains(s)
        }
    }
    
    @IBAction func refreshButtonPressed(_ sender: Any) {
        refresh()
    }
    
    @IBAction func listBBITapped(_ sender: Any) {
        var lists = [String]()
        for l in app.lists {
            lists.append(l.name)
        }
        parentVC.slideUpOptionsChooser(options: lists, title: "Choose List") { (option) in
            if let l = self.app.getList(with: lists[option]) {
                self.app.scannerList = l
                self.listBBI.title = l.name
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let vc as ScannerSettingsVC:
            vc.parentVC = self.parentVC
        case self:
            scannerResultTableView.reloadData()
        default:
            break
        }
    }

}
