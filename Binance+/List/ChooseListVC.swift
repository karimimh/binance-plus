//
//  ChooseListVC.swift
//  Binance+
//
//  Created by Behnam Karimi on 2/1/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class ChooseListVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var listsTableView: UITableView!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var editBBI: UIBarButtonItem!
    @IBOutlet weak var settingsBBI: UIBarButtonItem!
    
    var app: App?
    var listVC: ListVC?
    var selectedCell: ChooseListTVCell!
    var listChosenCompletion: (() -> Void)?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let item = UINavigationItem(title: "")
        let lbbi = UIBarButtonItem(title: "Lists", style: .plain, target: nil, action: nil)
        lbbi.tintColor = .black
        item.leftBarButtonItem = lbbi
        
        
        let rbbi = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newList(_:)))
        item.rightBarButtonItem = rbbi
        
        navBar.items = [item]
        
        
        
        
        listsTableView.tableFooterView = UIView()
        listsTableView.delegate = self
        listsTableView.dataSource = self
        listsTableView.allowsSelection = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let app = self.app else { return 0 }
        return app.lists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let app = self.app else { return UITableViewCell(style: .default, reuseIdentifier: nil) }
        guard let listTVC = self.listVC else { return UITableViewCell(style: .default, reuseIdentifier: nil) }
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChooseListTVCell", for: indexPath) as! ChooseListTVCell
        let list = app.lists[indexPath.row]
        cell.label.text = list.name
        if list.isServerList && !list.symbols.isEmpty {
            if list.name == "BTC" || list.name == "ETH" || list.name == "BNB" {
                DispatchQueue.global(qos: .background).async {
                    let im = UIImage(named: list.name.lowercased() + ".png")
                    DispatchQueue.main.async {
                        cell.iconImageView.image = im
                    }
                }
            } else if list.name == "USD" {
                DispatchQueue.global(qos: .background).async {
                    let im = UIImage(named: "usdt" + ".png")
                    DispatchQueue.main.async {
                        cell.iconImageView.image = im
                    }
                }
            } else if list.name == "ALTS" {
                DispatchQueue.global(qos: .background).async {
                    let im = UIImage(named: "xrp" + ".png")
                    DispatchQueue.main.async {
                        cell.iconImageView.image = im
                    }
                }
            }
        } else {
            if let im = UIImage(named: "star") {
                cell.iconImageView.image = im
            }
        }
        if list.name == listTVC.activeList.name {
            selectedCell = cell
            selectedCell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(self.listsTableView.isEditing == true) { return }
        guard let listTVC = self.listVC else { return }
        selectedCell.accessoryType = .none
        guard let cell = tableView.cellForRow(at: indexPath) as? ChooseListTVCell else { return }
        selectedCell = cell
        cell.accessoryType = .checkmark
        listTVC.activeList = listTVC.getList(cell.label.text!)
        listTVC.needsSorting()
        listChosenCompletion?()
    }
    
    
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let app = self.app else { return false }
        guard let cell = tableView.cellForRow(at: indexPath) as? ChooseListTVCell else { return false }
        let listName = cell.label.text!
        if app.getList(with: listName)!.isServerList {
            return false
        }
        return true
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let app = self.app else { return }
        guard let cell = tableView.cellForRow(at: indexPath) as? ChooseListTVCell else { return }
        let listName = cell.label.text!
        let listIndex = app.getListIndex(with: listName)
        guard listIndex >= 0 else { return }
        
        if editingStyle == .delete {
            app.lists.remove(at: listIndex)
            tableView.deleteRows(at: [indexPath], with: .fade)
            app.save()
        }
    }
    
    
    
    // MARK: - Reaaringing Tableview
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        guard let app = self.app else { return false }
        guard let cell = tableView.cellForRow(at: indexPath) as? ChooseListTVCell else { return false }
        let listName = cell.label.text!
        guard let list = app.getList(with: listName) else {
            return false
        }
        if list.isServerList {
            return false
        }
        return true
    }
    
    
    
    func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        guard let app = self.app else { return }
        let toList = app.lists[to.row]
        if toList.isServerList { return }
        let list = app.lists.remove(at: fromIndexPath.row)
        app.lists.insert(list, at: to.row)
        app.save()
    }
    
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        guard let app = self.app else { return sourceIndexPath }
        guard let cell = tableView.cellForRow(at: proposedDestinationIndexPath) as? ChooseListTVCell else { return sourceIndexPath }
        let listName = cell.label.text!
        guard let list = app.getList(with: listName) else {
            return sourceIndexPath
        }
        if list.isServerList {
            return sourceIndexPath
        }
        return proposedDestinationIndexPath
    }
    
    
    // MARK: - Actions
    
    @IBAction func newList(_ sender: UIBarButtonItem) {
        if(self.listsTableView.isEditing == true) { toggleEditing() }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CreateListVC") as! CreateListVC
        vc.app = app
        vc.chooseListVC = self
        
        self.parent!.present(vc, animated: true)
    }

    @IBAction func editList(_ sender: Any) {
        toggleEditing()
    }
    
    private func toggleEditing() {
        if(self.listsTableView.isEditing == true)
        {
            self.listsTableView.isEditing = false
            editBBI.title = "Edit"
            listVC?.parentVC.enableSliding()
        }
        else
        {
            self.listsTableView.isEditing = true
            editBBI.title = "Done"
            listVC?.parentVC.disableSliding()
        }
    }
    
}

