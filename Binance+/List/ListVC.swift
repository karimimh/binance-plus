//
//  ListVC.swift
//  Binance+
//
//  Created by Behnam Karimi on 5/1/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class ListVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UISearchBarDelegate, UISearchResultsUpdating {
    @IBOutlet weak var collectionView: UICollectionView!
    var app: App!
    
    //MARK: Properties
    var parentVC: ParentVC!
    var tabBarVC: TabBarVC!
    
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
    
    
    var miniTickerWebSocket: WebSocket?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            app = delegate.app
        }
        
        tabBarVC = (tabBarController as? TabBarVC)
        parentVC = (tabBarVC.parent as? ParentVC)
        
        chooseListVC = parentVC.leftContainerVC as? ChooseListVC
        chooseListVC.app = self.app
        chooseListVC.listVC = self
        chooseListVC.listsTableView.reloadData()
        
        
        parentVC.setupLeftContainerGestureRecognizers()
        chooseListVC.listChosenCompletion = {
            self.parentVC.slideLeft()
            self.collectionView.reloadData()
        }
        
        
        addSearchControllerToNavBar()
        
        if activeList == nil {
            activeList = getList("BTC")
        } else {
            setNavBarTitleView()
            setEditBarButtonItem()
        }
        
        
        
        listBBI = navigationItem.leftBarButtonItem
        sortBBI = navigationItem.rightBarButtonItem
        
        collectionView.allowsMultipleSelection = true
        self.startPriceStreaming()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        miniTickerWebSocket?.close()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        miniTickerWebSocket?.open()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        for symbol in app.allBinanceSymbols {
            symbol.iconImage = nil
            symbol.lastesThirtyDailyCandles = nil
        }
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if activeList == nil {
            return 0
        }
        if app == nil {
            return 0
        }
        if isFiltering() {
            return filteredSymbols.count
        }
        return activeList.symbols.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SymbolCVCell", for: indexPath) as! SymbolCVCell

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
        
        cell.previewChart.app = self.app
        cell.previewChart.symbol = symbol
        cell.previewChart.timeframe = .daily
        cell.previewChart.setNeedsDisplay()
        
        if symbol.lastesThirtyDailyCandles == nil {
            DispatchQueue.global(qos: .background).async {
                BinanaceAPI.getCandles(symbol: symbol, timeframe: .daily, limit: 30, completion: { (optionalCandles) in
                    if let candles = optionalCandles {
                        symbol.lastesThirtyDailyCandles = candles
                        DispatchQueue.main.async {
                            cell.previewChart.setNeedsDisplay()
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
        if cell.isSelected {
            cell.backgroundColor = UIColor.fromHex(hex: "#3392ff").withAlphaComponent(0.5)
        } else {
            cell.backgroundColor = .white
        }
        return cell
    }

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! SymbolCVCell
        guard let symbol = getSymbol(cell.nameLabel.text!) else { return }
        if !isEditing {
            parentVC.slideRightPanGR.isEnabled = false
            if app.chartSymbol != symbol.name {
                app.chartSymbol = symbol.name
            }
            tabBarVC.selectedIndex = 1
        } else {
            cell.backgroundColor = UIColor.fromHex(hex: "#3392ff").withAlphaComponent(0.5)
            cell.previewChart.setNeedsDisplay()
            if !selectedSymbols.contains(symbol.name) {
                selectedSymbols.append(symbol.name)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! SymbolCVCell
        guard let symbol = getSymbol(cell.nameLabel.text!) else { return }
        if selectedSymbols.contains(symbol.name) {
            selectedSymbols.remove(at: selectedSymbols.firstIndex(of: symbol.name)!)
        }
        cell.backgroundColor = .white
        cell.previewChart.setNeedsDisplay()
        
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        if activeList.isServerList {
            return false
        }
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let s = activeList.symbols.remove(at: sourceIndexPath.row)
        activeList.symbols.insert(s, at: destinationIndexPath.row)
        collectionView.moveItem(at: sourceIndexPath, to: destinationIndexPath)
//        needsSorting()
    }
    
    
    
    
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        if editing {
            if let ips = collectionView.indexPathsForSelectedItems {
                for ip in ips {
                    collectionView.deselectItem(at: ip, animated: true)
                }
            }
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertSymbols))
            navigationItem.rightBarButtonItems!.remove(at: 0)
            parentVC.slideRightPanGR.isEnabled = false
            if app.sortBy != .DEFAULT || app.sortDirection != .ASCENDING {
                app.sortBy = .DEFAULT
                app.sortDirection = .ASCENDING
                needsSorting()
                self.collectionView.reloadData()
            }
            
            navigationController?.setToolbarHidden(false, animated: true)
            
            deleteSymbolsBBI = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteSymbols(_:)))
            selectAllNoneBBI = UIBarButtonItem(title: "Select All", style: .plain, target: self, action: #selector(selectAllOrNone(_:)))
            
            let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            navigationController?.toolbar.items = [selectAllNoneBBI, space, deleteSymbolsBBI]
            
        } else {
            if let ips = collectionView.indexPathsForSelectedItems {
                for ip in ips {
                    collectionView.deselectItem(at: ip, animated: true)
                }
            }
            
            navigationItem.leftBarButtonItem = listBBI
            navigationItem.rightBarButtonItems?.insert(sortBBI, at: 0)
            parentVC.slideRightPanGR.isEnabled = true
            
            navigationController?.setToolbarHidden(true, animated: true)
        }
        super.setEditing(editing, animated: animated)
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
        
        parentVC.slideUpOptionsChooser(options: SortBy.all(), title: "Sort By", shouldDismissOnSelection: true) { (index) in
            let sortBy = SortBy(rawValue: index)!
            if self.app.sortBy == sortBy {
                self.app.sortDirection.negate()
            } else {
                self.app.sortBy = sortBy
                self.app.sortDirection = .ASCENDING
            }
            self.needsSorting()
            self.collectionView.reloadData()
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
        collectionView.reloadData()
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
//        collectionView.reloadData()
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
            let sym = activeList.symbols.first!
            let symbol = app.getSymbol(sym)!
            let s = symbol.quoteAsset.lowercased() + ".png"
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
//        if selectedSymbols.isEmpty { return }
//        for symbolName in selectedSymbols {
//            activeList.symbols.remove(at: activeList.symbols.firstIndex(of: symbolName)!)
//        }
        
        if let ips = collectionView.indexPathsForSelectedItems {
            for ip in ips {
                print(ip.row)
            }
//            collectionView.deleteItems(at: ips)
        }
//        collectionView.deleteItems(at: collectionView.indexPathsForSelectedItems!)
        
//        for i in 0 ..< collectionView.numberOfItems(inSection: 0) {
//            collectionView.deselectItem(at: IndexPath(row: i, section: 0), animated: true)
//        }
//        selectedSymbols.removeAll()
    }
    
    @IBAction func selectAllOrNone(_ sender: UIBarButtonItem) {
        if selectAllNoneBBI.title == "Select All" {
            for i in 0 ..< collectionView.numberOfItems(inSection: 0) {
                collectionView.selectItem(at: IndexPath(row: i, section: 0), animated: true, scrollPosition: .top)
            }
            selectAllNoneBBI.title = "Select None"
        } else if selectAllNoneBBI.title == "Select None" {
            for i in 0 ..< collectionView.numberOfItems(inSection: 0) {
                collectionView.deselectItem(at: IndexPath(row: i, section: 0), animated: true)
            }
            selectAllNoneBBI.title = "Select All"
        }
    }
    
    
    
    //MARK: Price Ticker Streaming
    
    private func startPriceStreaming() {
        BinanaceAPI.allMarketMiniTickersStream { (ws, jsonArray) in
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
            DispatchQueue.main.async {
                if self.isEditing || self.isFiltering() {
                    return
                }
                for c in self.collectionView.visibleCells {
                    let cell = c as! SymbolCVCell
                    guard let symbol = self.getSymbol(cell.nameLabel.text!) else { continue }
                    let volume = symbol.btcVolume(self.app)
                    cell.priceLabel.text = "\(symbol.price)"
                    cell.changeLabel.text = String(format: "%.2f%%", symbol.percentChange.doubleValue)
                    if symbol.volume > 10 {
                        cell.volumeLabel.text = "Volume: " + String(format: "%d", Int(volume.doubleValue)) + " ฿"
                    } else {
                        cell.volumeLabel.text = "Volume: " + String(format: "%.2f", volume.doubleValue) + " ฿"
                    }
                    
                    if symbol.percentChange < 0 {
                        cell.priceLabel.textColor = self.app.bearCandleColor
                        cell.changeLabel.backgroundColor = self.app.bearCandleColor
                    } else {
                        cell.priceLabel.textColor = self.app.bullCandleColor
                        cell.changeLabel.backgroundColor = self.app.bullCandleColor
                    }
                }
            }
        }
    }
    

}


// MARK: - Collection View Flow Layout Delegate
extension ListVC : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 80)
    }

}


