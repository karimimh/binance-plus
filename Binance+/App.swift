//
//  BinancePlus.swift
//  Binance+
//
//  Created by Behnam Karimi on 12/28/1397 AP.
//  Copyright © 1397 AP Behnam Karimi. All rights reserved.
//

import UIKit
import os.log

class App: NSObject, NSCoding {
    
    var btcPrice: Decimal = 0
    
    //MARK: App Settings
    var appColor = UIColor.white // UIColor.fromHex(hex: "16BEFF")
    var appFirstTimeLaunch = false
    
    //List Settings
    var sortBy = SortBy.DEFAULT
    var sortDirection = SortDirection.ASCENDING 
    var activeList: List! {
        didSet {
            save()
        }
    }
    
    
    //Chart Settings
    var bullCandleColor = UIColor.fromHex(hex: "#1EA69A")
    var bearCandleColor = UIColor.fromHex(hex: "#F15350")
    var chartGridLinesColor = UIColor.fromHex(hex: "#f2ffff")
    var chartBGColor = UIColor.white
    var chartPriceViewBGColor = UIColor.white
    var chartTimeViewColor = UIColor.white
    var chartTopMargin: Double = 10
    var chartBottomMargin: Double = 10
    
    
    
    var chartAutoScale = true {
        didSet {
            save()
        }
    }
    var chartSymbol: String = "ETHBTC" {
        didSet {
            save()
        }
    }
    var chartTimeframe: Timeframe = .daily
    var chartLatestX: CGFloat = UIScreen.main.bounds.width * 0.75
    var chartCandles: [Candle]!
    var chartCandleWidth: CGFloat = 2.5
    var chartHighestPrice: Decimal!
    var chartLowestPrice: Decimal!
    var chartIndicators: [Indicator] = [Indicator(indicatorType: .ema, properties: [Indicator.PropertyKey.length: 20, Indicator.PropertyKey.color_1: UIColor.blue.withAlphaComponent(0.3), Indicator.PropertyKey.line_width_1: CGFloat(1)], frameRow: 0, frameHeightPercentage: 85), Indicator(indicatorType: .volume, properties: [:], frameRow: 1, frameHeightPercentage: 15)]
    
    
    
    //Scanner
    var scannerList: List!
    var scannerFilters = [ScannerFilter]()
    
    
    
    //MARK: Properties
    var lists = [List]()
    var allBinanceSymbols = [Symbol]()
    
    
    //MARK: Types
    struct Key {
        static let allBinanceSymbols = "allBinanceSymbols"
        static let lists = "lists"
        static let chartSymbol = "chartSymbol"
        static let bullCandleColor = "bullCandleColor"
        static let bearCandleColor = "bearCandleColor"
        static let sortBy = "sortBy"
        static let sortDirection = "sortDirection"
        static let chartAutoScale = "chartAutoScale"
        static let activeList = "activeList"
        static let chartTimeframe = "chartTimeframe"
        static let chartCandles = "chartCandles"
        static let chartCandleWidth = "chartCandleWidth"
        static let chartHighestPrice = "chartHighestPrice"
        static let chartLowestPrice = "chartLowestPrice"
        static let chartIndicators = "chartIndicators"
        static let appColor = "appColor"
        static let chartGridLinesColor = "chartGridLinesColor"
        static let chartBGColor = "chartBGColor"
        static let chartPriceViewBGColor = "chartPriceViewBGColor"
        static let chartTimeViewColor = "chartTimeViewColor"
        static let chartTopMargin = "chartTopMargin"
        static let chartBottomMargin = "chartBottomMargin"
        static let chartLatestX = "chartLatestX"
    }
    
    //MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("binanceScanner")
    

    var busyShowingSTH = false
    
    
    //MARK: - Initialization
    override init() {
        super.init()
        
        BinanaceApi.currentAvgPrice(for: "BTCUSDT", completion: { (p) in
            if let price = p {
                self.btcPrice = price
            }
        })
    }
    
    
    init(bullCandleColor: UIColor, bearCandleColor: UIColor, sortBy: SortBy, sortDirection: SortDirection, chartAutoScale: Bool, allBinanceSymbols: [Symbol], lists: [List], chartSymbol: String?, activeList: List?, chartTimeframe: Timeframe?, chartCandles: [Candle]?, chartCandleWidth: CGFloat?, chartLatestX: CGFloat?, chartHighestPrice: Decimal?, chartLowestPrice: Decimal?, chartIndicators: [Indicator]?, appColor: UIColor?, chartGridLinesColor: UIColor?, chartBGColor: UIColor?, chartPriceViewBGColor: UIColor?, chartTimeViewColor: UIColor?, chartTopMargin: Double, chartBottomMargin: Double) {
        self.bullCandleColor = bullCandleColor
        self.bearCandleColor = bearCandleColor
        self.sortBy = sortBy
        self.sortDirection = sortDirection
        self.chartAutoScale = chartAutoScale
        self.allBinanceSymbols = allBinanceSymbols
        self.lists = lists
        if let s = chartSymbol { self.chartSymbol = s }
        self.activeList = activeList
        if let t = chartTimeframe { self.chartTimeframe = t }
        self.chartCandles = chartCandles
        if let ww = chartCandleWidth { self.chartCandleWidth = ww }
        self.chartHighestPrice = chartHighestPrice
        self.chartLowestPrice = chartLowestPrice
        if let inds = chartIndicators { self.chartIndicators = inds }
        if let c = appColor { self.appColor = c }
        if let c = chartGridLinesColor { self.chartGridLinesColor = c }
        if let c = chartBGColor { self.chartBGColor = c }
        if let c = chartPriceViewBGColor { self.chartPriceViewBGColor = c }
        if let c = chartTimeViewColor { self.chartTimeViewColor = c }
        self.chartTopMargin = chartTopMargin
        self.chartBottomMargin = chartBottomMargin
        if let x = chartLatestX { self.chartLatestX = x }
        
        super.init()
        
    }
    
    
    //MARK: - Methods
    func getSymbol(_ name: String) -> Symbol? {
        for symbol in allBinanceSymbols {
            if symbol.name == name {
                return symbol
            }
        }
        return nil
    }
    func getSymbolIndex(_ name: String) -> Int {
        for i in 0..<allBinanceSymbols.count {
            let symbol = allBinanceSymbols[i]
            if symbol.name == name {
                return i
            }
        }
        return -1
    }
    
    
    func getList(with name: String) -> List? {
        for list in lists {
            if list.name == name {
                return list
            }
        }
        return nil
    }
    
    func getListIndex(with name: String) -> Int {
        for i in 0..<lists.count {
            if lists[i].name == name {
                return i
            }
        }
        return -1
    }
    
    
    
    //MARK: - NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(bullCandleColor, forKey: Key.bullCandleColor)
        aCoder.encode(bearCandleColor, forKey: Key.bearCandleColor)
        aCoder.encode(sortBy.rawValue, forKey: Key.sortBy)
        aCoder.encode(sortDirection.rawValue, forKey: Key.sortDirection)
        aCoder.encode(chartAutoScale, forKey: Key.chartAutoScale)
        aCoder.encode(allBinanceSymbols, forKey: Key.allBinanceSymbols)
        aCoder.encode(lists, forKey: Key.lists)
        aCoder.encode(chartSymbol, forKey: Key.chartSymbol)
        aCoder.encode(activeList, forKey: Key.activeList)
        aCoder.encode(appColor, forKey: Key.appColor)
        aCoder.encode(chartGridLinesColor, forKey: Key.chartGridLinesColor)
        aCoder.encode(chartBGColor, forKey: Key.chartBGColor)
        aCoder.encode(chartPriceViewBGColor, forKey: Key.chartPriceViewBGColor)
        aCoder.encode(chartTimeViewColor, forKey: Key.chartTimeViewColor)
        aCoder.encode(chartTopMargin, forKey: Key.chartTopMargin)
        aCoder.encode(chartBottomMargin, forKey: Key.chartBottomMargin)
        aCoder.encode(chartTimeframe.rawValue, forKey: Key.chartTimeframe)
        aCoder.encode(chartIndicators, forKey: Key.chartIndicators)
        aCoder.encode(chartCandleWidth, forKey: Key.chartCandleWidth)
        aCoder.encode(chartLatestX, forKey: Key.chartLatestX)
        
    }

    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let bullCandleColor = aDecoder.decodeObject(forKey: Key.bullCandleColor) as? UIColor else {
            os_log("Unable to decode the bullCandleColor for a App object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let bearCandleColor = aDecoder.decodeObject(forKey: Key.bearCandleColor) as? UIColor else {
            os_log("Unable to decode the bearCandleColor for a App object.", log: OSLog.default, type: .debug)
            return nil
        }
        let sortBy = aDecoder.decodeInteger(forKey: Key.sortBy)
        let sortDirection = aDecoder.decodeInteger(forKey: Key.sortDirection)
        let chartAutoScale = aDecoder.decodeBool(forKey: Key.chartAutoScale)

        guard let lists = aDecoder.decodeObject(forKey: Key.lists) as? [List] else {
            os_log("Unable to decode the lists for a App object.", log: OSLog.default, type: .debug)
            return nil
        }

        guard let allBinanceSymbols = aDecoder.decodeObject(forKey: Key.allBinanceSymbols) as? [Symbol] else {
            os_log("Unable to decode the allBinanceSymbols for a App object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        let chartSymbol = aDecoder.decodeObject(forKey: Key.chartSymbol) as? String
        
        let activeList = aDecoder.decodeObject(forKey: Key.activeList) as? List
        
        var chartTimeframe: Timeframe? = nil
        if let chartTimeframeString = aDecoder.decodeObject(forKey: Key.chartTimeframe) as? String {
            if let t = Timeframe(rawValue: chartTimeframeString) {
                chartTimeframe = t
            }
        }
        
        
        
        let candles = aDecoder.decodeObject(forKey: Key.chartCandles) as? [Candle]
        
        let chartCandleWidth = aDecoder.decodeObject(forKey: Key.chartCandleWidth) as? CGFloat
        
        let chartLatestX = aDecoder.decodeObject(forKey: Key.chartLatestX) as? CGFloat
        
        let chartHighestPrice = aDecoder.decodeObject(forKey: Key.chartHighestPrice) as? Decimal
        
        let chartLowestPrice = aDecoder.decodeObject(forKey: Key.chartLowestPrice) as? Decimal
        
        let chartIndicators = aDecoder.decodeObject(forKey: Key.chartIndicators) as? [Indicator]
        
        let appColor = aDecoder.decodeObject(forKey: Key.appColor) as? UIColor
        
        let chartGridLinesColor = aDecoder.decodeObject(forKey: Key.chartGridLinesColor) as? UIColor
        
        let chartBGColor = aDecoder.decodeObject(forKey: Key.chartBGColor) as? UIColor
        
        let chartPriceViewBGColor = aDecoder.decodeObject(forKey: Key.chartPriceViewBGColor) as? UIColor
        
        let chartTimeViewColor = aDecoder.decodeObject(forKey: Key.chartTimeViewColor) as? UIColor
        
        let chartTopMargin = aDecoder.decodeDouble(forKey: Key.chartTopMargin)
        
        let chartBottomMargin = aDecoder.decodeDouble(forKey: Key.chartBottomMargin)
        
        self.init(bullCandleColor: bullCandleColor, bearCandleColor: bearCandleColor, sortBy: SortBy(rawValue: sortBy) ?? SortBy.DEFAULT, sortDirection: SortDirection(rawValue: sortDirection) ?? SortDirection.ASCENDING, chartAutoScale: chartAutoScale, allBinanceSymbols: allBinanceSymbols, lists: lists, chartSymbol: chartSymbol, activeList: activeList, chartTimeframe: chartTimeframe, chartCandles: candles, chartCandleWidth: chartCandleWidth, chartLatestX: chartLatestX, chartHighestPrice: chartHighestPrice, chartLowestPrice: chartLowestPrice, chartIndicators: chartIndicators, appColor: appColor, chartGridLinesColor: chartGridLinesColor, chartBGColor: chartBGColor, chartPriceViewBGColor: chartPriceViewBGColor, chartTimeViewColor: chartTimeViewColor, chartTopMargin: chartTopMargin, chartBottomMargin: chartBottomMargin)
        
    }
    
    func save() {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
            try data.write(to: App.ArchiveURL)
        } catch {
            os_log("Failed to save App...", log: OSLog.default, type: .error)
        }
    }
    
    
    func getVolumeInBTC(symbol: Symbol, baseVolume volume: Decimal) -> Decimal {
        if symbol.baseAsset == "BTC" {
            return volume
        } else if symbol.quoteAsset == "BTC" {
            // p = eth / btc,       volume * eth = volume * p * btc
            let p = symbol.price
            return volume * p
        } else {
            // p = eth / quote,     volume * eth = volume * p * quote
            // q = quote / btc,     volume * eth = volume * p * q * btc
            let p = symbol.price
            if let quote = getSymbol(symbol.quoteAsset + "BTC") {
                let q = quote.price
                return volume * p * q
            } else {
                return 0
            }
        }
    }
    
    
    func getPriceInBTC(symbol: Symbol) -> Decimal {
        if symbol.baseAsset == "BTC" {
            return 1.0
        } else if symbol.quoteAsset == "BTC" {
            // p = eth / btc
            return symbol.price
        } else {
            // p = eth / quote
            // q = quote / btc
            let p = symbol.price
            if let quote = getSymbol(symbol.quoteAsset + "BTC") {
                let q = quote.price
                return p * q
            } else {
                return 0
            }
        }
    }
    
    
}

//MARK: ENUMERATIONS
enum SortBy: Int {
    case DEFAULT
    case SYMBOL
    case VOLUME
    case PRICE
    case PERCENT_CHANGE
}

enum SortDirection: Int {
    case ASCENDING
    case DESCENDING
    
    mutating func negate() {
        if self == .ASCENDING {
            self = .DESCENDING
        } else {
            self = .ASCENDING
        }
    }
}
