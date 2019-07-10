//
//  CreateListVC.swift
//  Binance+
//
//  Created by Behnam Karimi on 2/3/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class CreateListVC: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var textField: UITextField!
    
    var app: App!
    var chooseListVC: ChooseListVC!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textField.delegate = self
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func doneTapped(_ sender: Any) {
        if let t = textField.text, !t.isEmpty {
            guard app.getList(with: t) == nil else { return }
            let list = List(name: t, isServerList: false)
            app.lists.append(list)
            app.save()
        }
        textField.resignFirstResponder()
        chooseListVC.listsTableView.reloadData()
        self.dismiss(animated: true, completion: nil)
        
    }
    
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let t = textField.text, !t.isEmpty {
            if app.getList(with: t) == nil {
                let list = List(name: t, isServerList: false)
                app.lists.append(list)
                app.save()
            }
        }
        textField.resignFirstResponder()
        chooseListVC.listsTableView.reloadData()
        self.dismiss(animated: true, completion: nil)
        return true
    }

}

