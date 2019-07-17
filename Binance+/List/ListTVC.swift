//
//  SymbolTableViewController.swift
//  Binance+
//
//  Created by Behnam Karimi on 12/21/1397 AP.
//  Copyright © 1397 AP Behnam Karimi. All rights reserved.
//

import UIKit
import SpriteKit
import os.log
import WebKit

class ListTVC: UITableViewController, UISearchBarDelegate, UISearchResultsUpdating {
    
    private var actionPool = [() -> Void]()
    //MARK: Properties
    var parentVC: ParentVC!
    var tabBarVC: TabBarVC!
    var app: App!
    
    var activeList: List! {
        get {
            return app.activeList
        }
        set {
            app.activeList = newValue
            setNavBarTitleView()
            setEditBarButtonItem()
        }
    }
    var isScrolling: Bool = false
    var filteredSymbols = [Symbol]()// for when user is searching
    var tableSymbols = [Symbol]()
    let searchController = UISearchController(searchResultsController: nil)
    
    
    var sortOptionsVC: SortOptionsVC!
    var chooseListVC: ChooseListVC!
    
    var listBBI: UIBarButtonItem!
    var sortBBI: UIBarButtonItem!
    
    var selectedSymbols = [String]()
    var deleteSymbolsBBI: UIBarButtonItem!
    var selectAllNoneBBI: UIBarButtonItem!
    
    var downloadingPreviewCandles = false
    
    var timer: Timer!
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        tabBarVC = (tabBarController as? TabBarVC)
        parentVC = (tabBarVC.parent as? ParentVC)
        self.app = parentVC.app
        
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        sortOptionsVC = storyboard.instantiateViewController(withIdentifier: "SortOptions") as? SortOptionsVC
        sortOptionsVC.app = app
        sortOptionsVC.listTVC = self
        
        
        chooseListVC = parentVC.leftContainerVC as? ChooseListVC
        chooseListVC.app = self.app
        chooseListVC.listTVC = self
        chooseListVC.listsTableView.reloadData()
        
        
        parentVC.setupLeftContainerGestureRecognizers()
        chooseListVC.listChosenCompletion = {
            self.parentVC.slideLeft()
        }
        
        
        tableView.tintColor = .yellow
        addSearchControllerToNavBar()

        if activeList == nil {
            activeList = getList("BTC")
        } else {
            setNavBarTitleView()
            setEditBarButtonItem()
        }
        
        
        
        listBBI = navigationItem.leftBarButtonItem
        sortBBI = navigationItem.rightBarButtonItem
        
        

        if !app.appFirstTimeLaunch {
            updateExchageInfo {
                self.app.save()
                self.updateSymbolsAll24HPriceChangeStatistics {
                    self.updateLists {
                        self.app.save()
                        self.startPriceStreaming()
                    }
                }
            }
        }

        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(reloadTableView), userInfo: nil, repeats: true)
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if timer != nil {
            timer.invalidate()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if timer != nil {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(reloadTableView), userInfo: nil, repeats: true)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        for symbol in app.allBinanceSymbols {
            symbol.iconImage = nil
        }
    }
    
    @IBAction func reloadTableView() {
        if !isEditing && !isFiltering() && parentVC.mainContainerLeadingConstraint.constant == 0 && parentVC.bottomContainerTopConstraint.constant == 0 && !isScrolling {
            tableView.reloadData()
            
            guard !downloadingPreviewCandles else { return }
            guard let arr = tableView.indexPathsForVisibleRows else { return }
            var symbolsDownloadingPreviewCandles = [Symbol]()
            for ip in arr {
                let symbol: Symbol
                if isFiltering() {
                    symbol = filteredSymbols[ip.row]
                } else {
                    if tableSymbols.isEmpty {
                        self.needsSorting()
                    }
                    symbol = tableSymbols[ip.row]
                }
                if symbol.lastesThirtyDailyCandles == nil {
                    symbolsDownloadingPreviewCandles.append(symbol)
                }
                if symbol.iconImage == nil {
                    if let image = UIImage(named: symbol.baseAsset.lowercased() + ".png") {
                        symbol.iconImage = image
                    } else {
                        symbol.iconImage = UIImage()
                    }
                }
            }
            if symbolsDownloadingPreviewCandles.isEmpty { return }
            self.downloadingPreviewCandles = true
            BinanaceApi.getCandlesForSymbols(symbolsDownloadingPreviewCandles, timeframe: .daily, limit: 30) { (dictionary) in
                for item in dictionary {
                    let symbolName = item.key
                    if let symbol = self.app.getSymbol(symbolName) {
                        symbol.lastesThirtyDailyCandles = item.value
                    }
                }
                self.downloadingPreviewCandles = false
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if app == nil {
            return 0
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if app == nil {
            return 0
        }
        if isFiltering() {
            return filteredSymbols.count
        } else {
            if activeList != nil {
                return activeList.symbols.count
            }
        }
        return 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Symbol", for: indexPath) as! SymbolTableViewCell
        let symbol: Symbol
        if isFiltering() {
            symbol = filteredSymbols[indexPath.row]
        } else {
            if tableSymbols.isEmpty {
                self.needsSorting()
            }
            symbol = tableSymbols[indexPath.row]
        }
        let name = symbol.name
        let price = symbol.price
        let priceChange = symbol.percentChange
        let volume = symbol.btcVolume(app)
        
        
        
        cell.nameLabel.text = name
        cell.priceLabel.text = "\(price)"
        cell.changeLabel.text = String(format: "%.2f%%", priceChange.doubleValue)
        if volume > 10 {
            cell.volumeLabel.text = "Volume: " + String(format: "%d", Int(volume.doubleValue)) + " ฿"
        } else {
            cell.volumeLabel.text = "Volume: " + String(format: "%.2f", volume.doubleValue) + " ฿"
        }
        
        if priceChange < 0 {
            cell.priceLabel.textColor = app.bearCandleColor
            cell.changeLabel.backgroundColor = app.bearCandleColor
        } else {
            cell.priceLabel.textColor = app.bullCandleColor
            cell.changeLabel.backgroundColor = app.bullCandleColor
        }
        cell.changeLabel.layer.masksToBounds = true
        cell.changeLabel.layer.cornerRadius = 5

        cell.quickChart.app = self.app
        cell.quickChart.symbol = symbol
        cell.quickChart.timeframe = .daily
        cell.quickChart.setNeedsDisplay()
        
        cell.iconImageView.image = symbol.iconImage
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell  = tableView.cellForRow(at: indexPath) as! SymbolTableViewCell
        guard let symbol = getSymbol(cell.nameLabel.text!) else { return }
        if !isEditing {
            parentVC.slideRightPanGR.isEnabled = false
            if app.chartSymbol != symbol.name {
                app.chartSymbol = symbol.name
            }
            tabBarVC.selectedIndex = 1
        } else {
            if !selectedSymbols.contains(symbol.name) {
                selectedSymbols.append(symbol.name)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell  = tableView.cellForRow(at: indexPath) as! SymbolTableViewCell
        guard let symbol = getSymbol(cell.nameLabel.text!) else { return }
        if selectedSymbols.contains(symbol.name) {
            selectedSymbols.remove(at: selectedSymbols.firstIndex(of: symbol.name)!)
        }
    }
    
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if activeList.isServerList {
            return false
        }
        return true
    }
    

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            activeList.symbols.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            app.save()
        }
    }
    
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        if editing {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertSymbols))
            navigationItem.rightBarButtonItems!.remove(at: 0)
            parentVC.slideRightPanGR.isEnabled = false
            
            app.sortBy = .DEFAULT
            app.sortDirection = .ASCENDING
            needsSorting()
            
            navigationController?.setToolbarHidden(false, animated: true)
            
            deleteSymbolsBBI = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteSymbols(_:)))
            selectAllNoneBBI = UIBarButtonItem(title: "Select All", style: .plain, target: self, action: #selector(selectAllOrNone(_:)))
            
            let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            navigationController?.toolbar.items = [selectAllNoneBBI, space, deleteSymbolsBBI]
            
        } else {
            selectedSymbols.removeAll()
            navigationItem.leftBarButtonItem = listBBI
            navigationItem.rightBarButtonItems?.insert(sortBBI, at: 0)
            parentVC.slideRightPanGR.isEnabled = true
            
            navigationController?.setToolbarHidden(true, animated: true)
        }
        super.setEditing(editing, animated: animated)

        
    }

    
    // MARK: - Reaarange TableView
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let s = activeList.symbols.remove(at: fromIndexPath.row)
        activeList.symbols.insert(s, at: to.row)
        needsSorting()
        app.save()
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if activeList.isServerList {
            return false
        }
        return true
    }
 
    
    

    // MARK: - Scrolling
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScrolling = true
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        isScrolling = true
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isScrolling = false
    }
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            isScrolling = false
        }
    }
    override func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        isScrolling = false
    }
    
    
    
    
    // MARK: - Insert Rows
    @IBAction func insertSymbols() {
        let navCont = self.storyboard!.instantiateViewController(withIdentifier: "AddSymbolsNavController") as! UINavigationController
        guard let symbolChooserVC = navCont.viewControllers.first as? AddSymbolsTVC else { return }
        symbolChooserVC.listTVC = self
        symbolChooserVC.list = activeList
        
        self.present(navCont, animated:true, completion: nil)
    }
    
    
    
    
    //MARK: - Sort Options
    
    @IBAction func showSortOptionsVC() {
        parentVC.setAsBottomContainerVC(sortOptionsVC)
        var tableHeight = sortOptionsVC.optionsTableView.tableFooterView!.frame.minY
        if tableHeight > UIScreen.main.bounds.height * 0.65 {
            tableHeight = UIScreen.main.bounds.height * 0.65
        }
        let h = tableHeight + sortOptionsVC.optionsTableView.frame.minY
        sortOptionsVC.tableViewBottomConstraint.constant = parentVC.bottomContainer.bounds.height - h
        
        parentVC.slideUp(height: tableHeight + sortOptionsVC.optionsTableView.frame.minY) { (panGR2, panGR3) in
            self.app.sortDirection.negate()
            self.sortOptionsVC.optionsTableView.selectRow(at: IndexPath(row: self.app.sortBy.rawValue, section: 0), animated: false, scrollPosition: .none)
            self.sortOptionsVC.handleView.addGestureRecognizer(panGR2)
            self.sortOptionsVC.navBar.addGestureRecognizer(panGR3)
        }
        
        
    }
    
    
    

    // MARK: - Choose List
    
    @IBAction func chooseList(_ sender: UIBarButtonItem) {
        parentVC.slideRight()
        
    }
    
    
    
    //MARK: - SearchController
    func updateSearchResults(for searchController: UISearchController) {
        filteredSymbols = activeList.getSymbols(app).filter({ (symbol) -> Bool in
            if searchBarIsEmpty() {
                return true
            }
            return symbol.name.lowercased().contains(searchController.searchBar.text!.lowercased())
        })
        tableView.reloadData()
    }
    
    private func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    private func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    
    //MARK: - Sorting
    func needsSorting() {
        var arr = activeList.getSymbols(app)
        switch app.sortBy {
        case .DEFAULT:
            break
        case .SYMBOL:
            arr.sort { (lhs, rhs) -> Bool in
                return lhs.name < rhs.name
            }
        case .VOLUME:
            arr.sort { (lhs, rhs) -> Bool in
                return lhs.btcVolume(app) > rhs.btcVolume(app)
            }
        case .PRICE:
            arr.sort { (lhs, rhs) -> Bool in
                return lhs.price < rhs.price
            }
        case .PERCENT_CHANGE:
            arr.sort { (lhs, rhs) -> Bool in
                return lhs.percentChange > rhs.percentChange
            }
        }
        if app.sortDirection == .DESCENDING {
            arr.reverse()
        }
        tableSymbols = arr
        tableView.reloadData()
    }
    
    
    //MARK: - Private Methods
    
    //MARK: Navigation Bar

    private func addSearchControllerToNavBar() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Symbols"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        searchController.searchBar.delegate = self
//        self.extendedLayoutIncludesOpaqueBars = true
        navigationItem.hidesSearchBarWhenScrolling = true
        searchController.searchBar.searchBarStyle = .minimal
    }
    
    private func setEditBarButtonItem() {
        if activeList.isServerList {
            if navigationItem.rightBarButtonItems!.count == 2 {
                navigationItem.rightBarButtonItems!.remove(at: 1)
            }
        } else if navigationItem.rightBarButtonItems!.count == 1 {
            navigationItem.rightBarButtonItems?.insert(editButtonItem, at: 1)
        }
        
        
        
    }
    
    private func setNavBarTitleView() {
        let v = ListTitleView.instantiateFromNib()
        v.label.text = activeList.name
        
        if activeList.isServerList && !activeList.symbols.isEmpty {
            let s = activeList.getSymbols(app).first!.quoteAsset.lowercased() + ".png"
            if let im = UIImage(named: s) {
                v.imageView.image = im
            }
        }
        navigationItem.titleView = v
    }
    
    
    
    //MARK: Helper Functions
    func getSymbol(_ name: String) -> Symbol? {
        for symbol in app.allBinanceSymbols {
            if symbol.name == name {
                return symbol
            }
        }
        return nil
    }
    
    
    
    
    private func filtered(symbols: [Symbol], with filter: String) -> [Symbol] {
        if filter.isEmpty {
            return activeList.getSymbols(app)
        }
        let f = filter.uppercased()
        var result = [Symbol]()
        for symbol in activeList.getSymbols(app) {
            if symbol.name.contains(f) {
                result.append(symbol)
            }
        }
        return result
    }
    
    func getList(_ name: String) -> List? {
        for list in app.lists {
            if list.name == name {
                return list
            }
        }
        return nil
    }
    
    func getListIndex(list: List) -> Int {
        for i in 0..<app.lists.count {
            if list.name == app.lists[i].name {
                return i
            }
        }
        return 0
    }
    
    @IBAction func deleteSymbols(_ sender: UIBarButtonItem) {
        if selectedSymbols.isEmpty { return }
        for symbolName in selectedSymbols {
            activeList.symbols.remove(at: activeList.symbols.firstIndex(of: symbolName)!)
        }
        tableView.deleteRows(at: tableView.indexPathsForSelectedRows!, with: .left)
        app.save()
    }
    
    @IBAction func selectAllOrNone(_ sender: UIBarButtonItem) {
        if selectAllNoneBBI.title == "Select All" {
            for i in 0 ..< tableView.numberOfRows(inSection: 0) {
                tableView.selectRow(at: IndexPath(row: i, section: 0), animated: true, scrollPosition: .none)
            }
            selectedSymbols.removeAll()
            for symbol in activeList.symbols {
                selectedSymbols.append(symbol)
            }
            selectAllNoneBBI.title = "Select None"
        } else if selectAllNoneBBI.title == "Select None" {
            for i in 0 ..< tableView.numberOfRows(inSection: 0) {
                tableView.deselectRow(at: IndexPath(row: i, section: 0), animated: true)
            }
            selectedSymbols.removeAll()
            selectAllNoneBBI.title = "Select All"
        }
    }
    
    
    
    // MARK: - Update from server
    
    private func updateExchageInfo(completion: @escaping () -> Void) {
        BinanaceApi.getExchangeInfo { (json) in
            guard let exchangeInfo = json else { return }
            
            let symbolsJsonArray = exchangeInfo["symbols"] as! [[String: Any]]
            for symbolInfo in symbolsJsonArray {
                let symbolName = symbolInfo["symbol"] as! String
                let symbolStatus = symbolInfo["status"] as! String
                let baseAsset = symbolInfo["baseAsset"] as! String
                let baseAssetPrecision = symbolInfo["baseAssetPrecision"] as! Int
                let quoteAsset = symbolInfo["quoteAsset"] as! String
                let quoteAssetPrecision = symbolInfo["quotePrecision"] as! Int
                /*let orderTypes = symbolInfo["orderTypes"]
                 let icebergAllowed = symbolInfo["icebergAllowed"]*/
                let filters = symbolInfo["filters"] as! [[String: Any]]
                
                
                
                if let symbol = self.app.getSymbol(symbolName) {
                    symbol.status = symbolStatus
                    symbol.baseAssetPrecision = baseAssetPrecision
                    symbol.quoteAssetPrecision = quoteAssetPrecision
                    
                    for filter in filters {
                        let filterType = filter["filterType"] as! String
                        if filterType == "PRICE_FILTER" {
                            let tickSize = Decimal(string: filter["tickSize"] as! String)!
                            symbol.tickSize = tickSize
                        } else if filterType == "LOT_SIZE" {
                            let stepSize = Decimal(string: filter["stepSize"] as! String)!
                            symbol.stepSize = stepSize
                        }
                    }
                } else {
                    let symbol = Symbol(name: symbolName, status: symbolStatus, baseAsset: baseAsset, baseAssetPrecision: baseAssetPrecision, quoteAsset: quoteAsset, quoteAssetPrecision: quoteAssetPrecision)
                    for filter in filters {
                        let filterType = filter["filterType"] as! String
                        if filterType == "PRICE_FILTER" {
                            let tickSize = Decimal(string: filter["tickSize"] as! String)!
                            symbol.tickSize = tickSize
                        } else if filterType == "LOT_SIZE" {
                            let stepSize = Decimal(string: filter["stepSize"] as! String)!
                            symbol.stepSize = stepSize
                        }
                    }
                    self.app.allBinanceSymbols.append(symbol)
                }
            }
            
            completion()
        }
    }
   
    
    private func updateSymbolsAll24HPriceChangeStatistics(completion: @escaping () -> Void) {
        BinanaceApi.all24HPriceChagneStatistics { (array) in
            guard let jsonArray = array else { return }
            for json in jsonArray {
                let symbolName = json["symbol"] as! String
                let closePrice = json["prevClosePrice"] as! String
                let baseAssetVolume = json["volume"] as! String
                let quoteAssetVolume = json["quoteVolume"] as! String
                let percentChange = json["priceChangePercent"] as! String
                
                guard let symbol = self.app.getSymbol(symbolName) else { return }
                
                symbol.price = Decimal(string: closePrice)!
                symbol.volume = Decimal(string: baseAssetVolume)!
                symbol.quoteAssetVolume = Decimal(string: quoteAssetVolume)!
                symbol.percentChange = Decimal(string: percentChange)!
                
            }
            completion()
        }
    }
    
    private func updateLists(completion: @escaping () -> Void = {}) {
        var index = 0
        for i in 0..<app.lists.count {
            let l = app.lists[i]
            if !l.isServerList {
                index = i
                break
            }
        }
        
        for symbol in app.allBinanceSymbols {
            let quoteAsset = symbol.quoteAsset
            if let list = self.app.getList(with: quoteAsset) {
                if !list.contains(symbolName: symbol.name) {
                    list.symbols.append(symbol.name)
                }
            } else {
                let newList = List(name: quoteAsset, isServerList: true)
                newList.isServerList = true
                newList.symbols.append(symbol.name)
                app.lists.insert(newList, at: index)
                index += 1
            }
        }

        var removedSymbols = [String]()
        for i in 0 ..< app.allBinanceSymbols.count {
            let symbol = app.allBinanceSymbols[i]
            if symbol.status.uppercased() != "TRADING" {
                removedSymbols.append(symbol.name)
            }
        }
        app.allBinanceSymbols.removeAll { (sym) -> Bool in
            return removedSymbols.contains(sym.name)
        }
        
        
        for list in app.lists {
            removedSymbols.removeAll()
            for sym in list.symbols {
                if let s = app.getSymbol(sym) {
                    if s.status.uppercased() != "TRADING" {
                        removedSymbols.append(sym)
                    }
                } else {
                    removedSymbols.append(sym)
                }
            }
            list.symbols.removeAll { (sym) -> Bool in
                return removedSymbols.contains(sym)
            }
        }
        
        
        
        completion()
    }
    
    //MARK: Price Ticker Streaming
    
    private func startPriceStreaming() {
        BinanaceApi.allMarketMiniTickersStream { (jsonArray) in
            guard let array = jsonArray else { return }
            for json in array {
                let symbolName = json["s"] as! String
                let closePrice = json["c"] as! String
                let openPrice = json["o"] as! String
                let baseAssetVolume = json["v"] as! String
                let quoteAssetVolume = json["q"] as! String
                
                guard let symbol = self.getSymbol(symbolName) else { continue }
                symbol.price = Decimal(string: closePrice)!
                symbol.volume = Decimal(string: baseAssetVolume)!
                symbol.quoteAssetVolume = Decimal(string: quoteAssetVolume)!
                
                let percentChange = 100.0 * (Decimal(string: closePrice)! - Decimal(string: openPrice)!) / Decimal(string: openPrice)!
                symbol.percentChange = percentChange
            }
            
        }
    }
    
    
}
