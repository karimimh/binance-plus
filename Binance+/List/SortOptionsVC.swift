//
//  SortOptionsVC.swift
//  Binance+
//
//  Created by Behnam Karimi on 1/29/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class SortOptionsVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var optionsTableView: UITableView!
    @IBOutlet weak var handleView: UIView!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    
    var app: App!
    var listVC: ListVC!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navBar.isTranslucent = false
        
        
        optionsTableView.tableFooterView = UIView()
        
        optionsTableView.delegate = self
        optionsTableView.dataSource = self
        
        optionsTableView.allowsSelection = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SortOption", for: indexPath) as! SortOptionTVCell
        cell.binance = app
        let options = ["Default", "Symbol", "Volume", "Price", "% Change"]
        let option = options[indexPath.row]
        cell.leftLabel.text = option
        cell.sortBy = SortBy(rawValue: indexPath.row)
        return cell
    }
    

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        listVC.needsSorting()
        app.save()
    }
    
    
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
