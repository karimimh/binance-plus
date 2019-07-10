//
//  ScannerSettingsVC.swift
//  Binance+
//
//  Created by Behnam Karimi on 2/16/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class ScannerSettingsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var editBBI: UIBarButtonItem!
    
    var list: List! {
        set {
            app.scannerList = newValue
        }
        get {
            return app.scannerList
        }
    }
    var filters: [ScannerFilter] {
        get {
            return app.scannerFilters
        }
        set {
            app.scannerFilters = newValue
        }
    }
    
    var parentVC: ParentVC!
    var app: App {
        get {
            return parentVC.app
        }
    }
    
    var currentEditingTextField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        tableView.delegate = self
        tableView.dataSource = self
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        tapGR.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGR)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    //MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if parentVC == nil {
            return 0
        }
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filters.isEmpty {
            tableView.setEmptyView(title: "No Filters Set ⚠︎", message: "Add Filters")
        }
        else {
            tableView.restore()
        }
        return filters.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "FilterTVCell", for: indexPath) as! FilterTVCell
        
        let filter = filters[row]

        cell.rowLabel.text = "\(row + 1)"
        cell.filterLabel.text = filter.toString()
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "FilterSettingsVC") as! FilterSettingsVC
        vc.parentVC = parentVC
        vc.filter = filters[indexPath.row]
        show(vc, sender: self)
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            filters.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            app.save()
        }
    }
    
    
    
    
    

    @IBAction func addFilter(_ sender: Any) {
        guard parentVC != nil else {
            return
        }
        
        
        
        
        parentVC.slideUpOptionsChooser(options: ScannerFilter.FilterType.allTypes(), title: "Choose Filter Type") { (index) in
            let filter = ScannerFilter(type: ScannerFilter.FilterType(rawValue: ScannerFilter.FilterType.allTypes()[index])!)
            self.filters.append(filter)
            self.tableView.reloadData()
        }
    }
    
    @IBAction func editBBITapped(_ sender: Any) {
        toggleEditing()
    }
    
    private func toggleEditing() {
        if(self.tableView.isEditing == true)
        {
            self.tableView.isEditing = false
            editBBI.title = "Edit"
            self.app.save()
        }
        else
        {
            self.tableView.isEditing = true
            editBBI.title = "Done"
        }
    }
    
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        if let tf = currentEditingTextField {
            tf.resignFirstResponder()
        }
    }
    
    
    
}
