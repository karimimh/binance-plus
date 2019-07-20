//
//  ListVC.swift
//  Binance+
//
//  Created by Behnam Karimi on 4/28/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class ListVC: UIViewController, UISearchBarDelegate, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
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
    var filteredSymbols = [Symbol]() // for when user is searching
    var tableSymbols = [Symbol]()
    let searchController = UISearchController(searchResultsController: nil)
    
    
    var chooseListVC: ChooseListVC!
    
    var listBBI: UIBarButtonItem!
    var sortBBI: UIBarButtonItem!
    
    var selectedSymbols = [String]()
    var deleteSymbolsBBI: UIBarButtonItem!
    var selectAllNoneBBI: UIBarButtonItem!
    
    var downloadingPreviewCandles = false
    
    var timer: Timer!
    
    var miniTickerWebSocket: WebSocket?
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        tabBarVC = (tabBarController as? TabBarVC)
        parentVC = (tabBarVC.parent as? ParentVC)
        self.app = parentVC.app
        
        
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = true
        
        
        chooseListVC = parentVC.leftContainerVC as? ChooseListVC
        chooseListVC.app = self.app
        chooseListVC.listVC = self
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
        
        
        self.startPriceStreaming()
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(reloadTableView), userInfo: nil, repeats: true)
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if timer != nil {
            timer.invalidate()
        }
        miniTickerWebSocket?.close()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if timer != nil {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(reloadTableView), userInfo: nil, repeats: true)
        }
        miniTickerWebSocket?.open()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        for symbol in app.allBinanceSymbols {
            symbol.iconImage = nil
            symbol.lastesThirtyDailyCandles = nil
        }
    }
    
    @IBAction func reloadTableView() {
        if !isEditing && !isFiltering() && !isScrolling {
            tableView.reloadData()
        }
    }
    
    // MARK: - Table view data source
    
     func numberOfSections(in tableView: UITableView) -> Int {
        if app == nil {
            return 0
        }
        return 1
    }
    
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        
        if symbol.lastesThirtyDailyCandles == nil {
            DispatchQueue.global(qos: .background).async {
                BinanaceApi.getCandles(symbol: symbol, timeframe: .daily, limit: 30, completion: { (optionalCandles) in
                    if let candles = optionalCandles {
                        symbol.lastesThirtyDailyCandles = candles
                        DispatchQueue.main.async {
                            cell.quickChart.setNeedsDisplay()
                        }
                    }
                })
            }
        }
        
        if symbol.iconImage != nil {
            cell.iconImageView.image = symbol.iconImage
        } else {
            DispatchQueue.global(qos: .background).async {
                symbol.iconImage = UIImage(named: symbol.baseAsset.lowercased())
                DispatchQueue.main.async {
                    cell.iconImageView.image = symbol.iconImage
                }
            }
        }
        return cell
    }
    
     func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
     func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    
    
     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
    
     func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell  = tableView.cellForRow(at: indexPath) as! SymbolTableViewCell
        guard let symbol = getSymbol(cell.nameLabel.text!) else { return }
        if selectedSymbols.contains(symbol.name) {
            selectedSymbols.remove(at: selectedSymbols.firstIndex(of: symbol.name)!)
        }
    }
    
    
     func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if activeList.isServerList {
            return false
        }
        return true
    }
    
    
     func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            activeList.symbols.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            app.save()
        }
    }
    
    
     func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
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
     func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let s = activeList.symbols.remove(at: fromIndexPath.row)
        activeList.symbols.insert(s, at: to.row)
        needsSorting()
        app.save()
    }
    
     func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if activeList.isServerList {
            return false
        }
        return true
    }
    
    
    
    
    // MARK: - Scrolling
     func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScrolling = true
    }
    
     func scrollViewDidScroll(_ scrollView: UIScrollView) {
        isScrolling = true
    }
    
     func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isScrolling = false
    }
     func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            isScrolling = false
        }
    }
     func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        isScrolling = false
    }
    
    
    
    
    // MARK: - Insert Rows
    @IBAction func insertSymbols() {
        let navCont = self.storyboard!.instantiateViewController(withIdentifier: "AddSymbolsNavController") as! UINavigationController
        guard let symbolChooserVC = navCont.viewControllers.first as? AddSymbolsTVC else { return }
        symbolChooserVC.listVC = self
        symbolChooserVC.list = activeList
        
        self.present(navCont, animated:true, completion: nil)
    }
    
    
    
    
    //MARK: - Sort Options
    
    @IBAction func showSortOptionsVC() {
        
        parentVC.slideUpOptionsChooser(options: SortBy.all(), title: "Sort By", shouldDismissOnSelection: false) { (index) in
            let sortBy = SortBy(rawValue: index)!
            if self.app.sortBy == sortBy {
                self.app.sortDirection.negate()
            } else {
                self.app.sortBy = sortBy
                self.app.sortDirection = .ASCENDING
            }
            self.needsSorting()
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
    
    
    
    //MARK: Price Ticker Streaming
    
    private func startPriceStreaming() {
        BinanaceApi.allMarketMiniTickersStream { (ws, jsonArray) in
            self.miniTickerWebSocket = ws
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
