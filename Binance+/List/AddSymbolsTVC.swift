//
//  SymbolChooserTableViewController.swift
//  Binance+
//
//  Created by Behnam Karimi on 12/26/1397 AP.
//  Copyright © 1397 AP Behnam Karimi. All rights reserved.
//

import UIKit

class AddSymbolsTVC: UITableViewController, UISearchBarDelegate, UISearchResultsUpdating {
    
    var listVC: ListVC? {
        didSet {
            if let vc = listVC {
                allSymbols = vc.app.allBinanceSymbols.sorted(by: { (lhs, rhs) -> Bool in
                    lhs.name < rhs.name
                })
            }
        }
    }
    var list: List?
    
    var filteredSymbols = [Symbol]()// for when user is searching
    let searchController = UISearchController(searchResultsController: nil)
    var allSymbols = [Symbol]()
    
    
    var selectedSymbols = [String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addSearchControllerToNavBar()
    }
    
    
    
    
    
    
    @IBAction func onSelectionFinished() {
        guard let vc = listVC else { return }
        guard let l = list else { return }
        
        
        for sym in selectedSymbols {
            if !l.contains(symbolName: sym) {
                l.symbols.append(sym)
            }
        }
        
//        if let selected = tableView.indexPathsForSelectedRows {
//            for indexPath in selected {
//                let s = allSymbols[indexPath.row].name
//                if !l.contains(symbolName: s) {
//                    l.symbols.append(s)
//                }
//            }
//        }
        vc.needsSorting()
        vc.tableView.reloadData()
        vc.app.save()
        self.navigationController?.popViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
        vc.setEditing(false, animated: true)
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let vc = listVC else { return 0 }
        if isFiltering() {
            return filteredSymbols.count
        }
        return vc.app.allBinanceSymbols.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PickSymbolTVCell", for: indexPath) as! PickSymbolTVCell
        guard let vc = listVC else { return cell }
        
        let symbols: [Symbol]
        if isFiltering() {
            symbols = filteredSymbols
        } else {
            symbols = vc.app.allBinanceSymbols
        }
        
        let symbol = symbols.sorted(by: { (lhs, rhs) -> Bool in
            lhs.name < rhs.name
        })[indexPath.row]
        
        
        cell.label.text = symbol.name
        
        cell.iconIV.image = UIImage(named: symbol.baseAsset.lowercased() + ".png")
        
        
        let cellSelected = selectedSymbols.contains(symbol.name) || cell.isSelected
        
        cell.accessoryType = cellSelected ? .checkmark : .none

        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? PickSymbolTVCell else { return }
        cell.accessoryType = .checkmark
        let sym = cell.label.text!
        if !selectedSymbols.contains(sym) {
            selectedSymbols.append(sym)
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? PickSymbolTVCell else { return }
        cell.accessoryType = .none
        let sym = cell.label.text!
        if selectedSymbols.contains(sym) {
            selectedSymbols.remove(at: selectedSymbols.firstIndex(of: sym)!)
        }
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 28
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 28
    }

    
    // - MARK: Search Controller
    private func addSearchControllerToNavBar() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Symbols"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        searchController.searchBar.delegate = self
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredSymbols = listVC!.app.allBinanceSymbols.filter({ (symbol) -> Bool in
            if searchBarIsEmpty() {
                return true
            }
            return symbol.name.lowercased().contains(searchController.searchBar.text!.lowercased())
        })
        tableView.reloadData()
    }
    
    
    
    private func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    private func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
}
