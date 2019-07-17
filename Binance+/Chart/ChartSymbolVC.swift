//
//  ChartSymbolVC.swift
//  Binance+
//
//  Created by Behnam Karimi on 4/10/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class ChartSymbolVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var symbolsTableView: UITableView!
    
    var chartVC: ChartVC?
    var app: App?
    
    var symbols = [String]()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        symbolsTableView.tableFooterView = UIView()
        symbolsTableView.delegate = self
        symbolsTableView.dataSource = self
        symbolsTableView.allowsSelection = true
        
        
        searchBar.delegate = self
        searchBar.becomeFirstResponder()
    }
    

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return symbols.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let app = self.app else { return UITableViewCell(style: .default, reuseIdentifier: nil) }
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChartSymbolTVCell", for: indexPath) as! ChartSymbolTVCell
        let symbol = symbols[indexPath.row]
        cell.symbolLabel.text = symbol
        if let image = app.getSymbol(symbol)?.iconImage {
            cell.iconIV.image = image
        }
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let app = self.app else { return }
        if symbols[indexPath.row] != app.chartSymbol {
            app.chartSymbol = symbols[indexPath.row]
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    
    
    
    // MARK: - SearchBar
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let app = self.app else { return }
        symbols.removeAll()
        
        if searchText.isEmpty {
            symbolsTableView.reloadData()
            return
        }
        for symbol in app.allBinanceSymbols {
            if symbol.name.uppercased().hasPrefix(searchText.uppercased()) {
                symbols.append(symbol.name)
            }
        }
        for symbol in app.allBinanceSymbols {
            if symbol.name.uppercased().contains(searchText.uppercased()) {
                symbols.append(symbol.name)
            }
        }
        symbolsTableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.dismiss(animated: true, completion: nil)
    }

}
