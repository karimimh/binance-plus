//
//  OptionsChooserVC.swift
//  Binance+
//
//  Created by Behnam Karimi on 2/16/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class OptionsChooserVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var handleView: UIView!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    var navItem: UINavigationItem!
    
    var options = [String]()
    
    var parentVC: ParentVC!
    
    var completion: ((Int) -> Void)?
    
    var shouldDismissOnSelect = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = true
        
        navBar.shadowImage = UIColor.fromHex(hex: "#D6D6D6").as1ptImage()
        navBar.setBackgroundImage(UIColor.white.as1ptImage(), for: .default)
        
        
        navItem = UINavigationItem(title: "")
        navItem.leftBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)
        navItem.leftBarButtonItem?.tintColor = UIColor.purple
        navItem.leftBarButtonItem?.isEnabled = false
        navItem.leftBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .bold), NSAttributedString.Key.foregroundColor: UIColor.purple], for: .disabled)
        navItem.leftBarButtonItem?.setTitlePositionAdjustment(UIOffset(horizontal: -7.5, vertical: -10), for: .default)
        navBar.items = [navItem]
        
        
        handleView.clipsToBounds = false
        handleView.layer.masksToBounds = false

    }

    
    
    //MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicOptionTVCell", for: indexPath)
        cell.textLabel?.text = options[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if shouldDismissOnSelect {
            self.dismiss(animated: true) {
                self.completion?(indexPath.row)
            }
        } else {
            completion?(indexPath.row)
        }
    }
    
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }
}
