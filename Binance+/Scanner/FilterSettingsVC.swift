//
//  FilterSettingsVC.swift
//  Binance+
//
//  Created by Behnam Karimi on 4/13/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class FilterSettingsVC: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    @IBOutlet weak var tv: UITableView!
    
    
    var filter: ScannerFilter?
    var parentVC: ParentVC!
    
    var currentTextField: UITextField?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tv.tableFooterView = UIView()
        tv.delegate = self
        tv.dataSource = self
        tv.allowsSelection = false
    }

    override func viewDidAppear(_ animated: Bool) {
        tv.reloadData()
    }
    
    
    
    //MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.parentVC == nil { return 0 }
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let filter = self.filter else { return 0 }
        switch filter.type {
        case .volume24h, .price, .rsi_divergence:
            return 2
        case .green_candle:
            return 3
        case .avg_volume, .relative_volume, .rsi:
            return 4
        case .ema_difference, .upper_boll_band_minus_candle_close, .lower_boll_band_minus_candle_close:
            return 5
        case .macd_signal, .macd_line, .macd_bar:
            return 6
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let filter = self.filter else { return UITableViewCell(style: .default, reuseIdentifier: nil) }
        let row = indexPath.row
        switch filter.type {
        case .volume24h, .price:
            if row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterButtonTVCell") as! FilterButtonTVCell
                cell.leftLabel.text = "greater than / less than"
                cell.rightButton.setTitle(filter.relationship.toString(), for: .normal)
                cell.buttonPressedAction = {
                    self.parentVC.slideUpOptionsChooser(options: ["Greater Than ( > )", "Less Than ( < )"], title: "Select option", completion: { (index) in
                        filter.relationship = ScannerFilter.FilterRelationship(rawValue: index)!
                        cell.rightButton.setTitle(filter.relationship.toString(), for: .normal)
                    })
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterTFTVCell") as! FilterTFTVCell
                cell.leftLabel.text = "rValue"
                cell.rightTextField.text = filter.rValue.stringValue
                cell.newTextCompletion = { (text) in
                    if let v = Decimal(string: text) {
                        filter.rValue = v
                    }
                    cell.rightTextField.text = filter.rValue.stringValue
                }
                cell.textFieldStartedEditing = {
                    self.currentTextField = cell.rightTextField
                }
                cell.textFieldResignedCompletion = {
                    self.currentTextField = nil
                }
                return cell
            }
            
        case .avg_volume, .relative_volume:
            if row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterTFTVCell") as! FilterTFTVCell
                cell.leftLabel.text = "Average Length"
                cell.rightTextField.text = String(filter.properties[Indicator.PropertyKey.length] as! Int)
                cell.newTextCompletion = { (text) in
                    if let v = Int(text) {
                        filter.properties[Indicator.PropertyKey.length] = v
                    }
                    cell.rightTextField.text = String(filter.properties[Indicator.PropertyKey.length] as! Int)
                }
                cell.textFieldStartedEditing = {
                    self.currentTextField = cell.rightTextField
                }
                cell.textFieldResignedCompletion = {
                    self.currentTextField = nil
                }
                return cell
            } else if row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterButtonTVCell") as! FilterButtonTVCell
                cell.leftLabel.text = "greater than / less than"
                cell.rightButton.setTitle(filter.relationship.toString(), for: .normal)
                cell.buttonPressedAction = {
                    self.parentVC.slideUpOptionsChooser(options: ["Greater Than ( > )", "Less Than ( < )"], title: "Select option", completion: { (index) in
                        filter.relationship = ScannerFilter.FilterRelationship(rawValue: index)!
                        cell.rightButton.setTitle(filter.relationship.toString(), for: .normal)
                    })
                }
                return cell
            } else if row == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterTFTVCell") as! FilterTFTVCell
                cell.leftLabel.text = "rValue"
                cell.rightTextField.text = filter.rValue.stringValue
                cell.newTextCompletion = { (text) in
                    if let v = Decimal(string: text) {
                        filter.rValue = v
                    }
                    cell.rightTextField.text = filter.rValue.stringValue
                }
                cell.textFieldStartedEditing = {
                    self.currentTextField = cell.rightTextField
                }
                cell.textFieldResignedCompletion = {
                    self.currentTextField = nil
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterButtonTVCell") as! FilterButtonTVCell
                cell.leftLabel.text = "Timeframe"
                cell.rightButton.setTitle(filter.timeframe.rawValue, for: .normal)
                cell.buttonPressedAction = {
                    self.parentVC.slideUpOptionsChooser(options: Timeframe.allValues(), title: "Select option", completion: { (index) in
                        filter.timeframe = Timeframe(rawValue: Timeframe.allValues()[index])!
                        cell.rightButton.setTitle(filter.timeframe.rawValue, for: .normal)
                    })
                }
                return cell
            }
            
        case .ema_difference:
            if row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterTFTVCell") as! FilterTFTVCell
                cell.leftLabel.text = "EMA Length 1"
                cell.rightTextField.text = String(filter.properties[Indicator.PropertyKey.fastLength] as! Int)
                cell.newTextCompletion = { (text) in
                    if let v = Int(text) {
                        filter.properties[Indicator.PropertyKey.fastLength] = v
                    }
                    cell.rightTextField.text = String(filter.properties[Indicator.PropertyKey.fastLength] as! Int)
                }
                cell.textFieldStartedEditing = {
                    self.currentTextField = cell.rightTextField
                }
                cell.textFieldResignedCompletion = {
                    self.currentTextField = nil
                }
                return cell
            } else if row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterTFTVCell") as! FilterTFTVCell
                cell.leftLabel.text = "EMA Length 2"
                cell.rightTextField.text = String(filter.properties[Indicator.PropertyKey.slowLength] as! Int)
                cell.newTextCompletion = { (text) in
                    if let v = Int(text) {
                        filter.properties[Indicator.PropertyKey.slowLength] = v
                    }
                    cell.rightTextField.text = String(filter.properties[Indicator.PropertyKey.slowLength] as! Int)
                }
                cell.textFieldStartedEditing = {
                    self.currentTextField = cell.rightTextField
                }
                cell.textFieldResignedCompletion = {
                    self.currentTextField = nil
                }
                return cell
            } else if row == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterButtonTVCell") as! FilterButtonTVCell
                cell.leftLabel.text = "greater than / less than"
                cell.rightButton.setTitle(filter.relationship.toString(), for: .normal)
                cell.buttonPressedAction = {
                    self.parentVC.slideUpOptionsChooser(options: ["Greater Than ( > )", "Less Than ( < )"], title: "Select option", completion: { (index) in
                        filter.relationship = ScannerFilter.FilterRelationship(rawValue: index)!
                        cell.rightButton.setTitle(filter.relationship.toString(), for: .normal)
                    })
                }
                return cell
            } else if row == 3 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterTFTVCell") as! FilterTFTVCell
                cell.leftLabel.text = "rValue"
                cell.rightTextField.text = filter.rValue.stringValue
                cell.newTextCompletion = { (text) in
                    if let v = Decimal(string: text) {
                        filter.rValue = v
                    }
                    cell.rightTextField.text = filter.rValue.stringValue
                }
                cell.textFieldStartedEditing = {
                    self.currentTextField = cell.rightTextField
                }
                cell.textFieldResignedCompletion = {
                    self.currentTextField = nil
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterButtonTVCell") as! FilterButtonTVCell
                cell.leftLabel.text = "Timeframe"
                cell.rightButton.setTitle(filter.timeframe.rawValue, for: .normal)
                cell.buttonPressedAction = {
                    self.parentVC.slideUpOptionsChooser(options: Timeframe.allValues(), title: "Select option", completion: { (index) in
                        filter.timeframe = Timeframe(rawValue: Timeframe.allValues()[index])!
                        cell.rightButton.setTitle(filter.timeframe.rawValue, for: .normal)
                    })
                }
                return cell
            }
            
        case .lower_boll_band_minus_candle_close, .upper_boll_band_minus_candle_close:
            if row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterTFTVCell") as! FilterTFTVCell
                cell.leftLabel.text = "BollingerBand Length"
                cell.rightTextField.text = String(filter.properties[Indicator.PropertyKey.fastLength] as! Int)
                cell.newTextCompletion = { (text) in
                    if let v = Int(text) {
                        filter.properties[Indicator.PropertyKey.fastLength] = v
                    }
                    cell.rightTextField.text = String(filter.properties[Indicator.PropertyKey.fastLength] as! Int)
                }
                cell.textFieldStartedEditing = {
                    self.currentTextField = cell.rightTextField
                }
                cell.textFieldResignedCompletion = {
                    self.currentTextField = nil
                }
                return cell
            } else if row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterTFTVCell") as! FilterTFTVCell
                cell.leftLabel.text = "BollingerBand stddev"
                cell.rightTextField.text = String(filter.properties[Indicator.PropertyKey.slowLength] as! Int)
                cell.newTextCompletion = { (text) in
                    if let v = Int(text) {
                        filter.properties[Indicator.PropertyKey.slowLength] = v
                    }
                    cell.rightTextField.text = String(filter.properties[Indicator.PropertyKey.slowLength] as! Int)
                }
                cell.textFieldStartedEditing = {
                    self.currentTextField = cell.rightTextField
                }
                cell.textFieldResignedCompletion = {
                    self.currentTextField = nil
                }
                return cell
            } else if row == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterButtonTVCell") as! FilterButtonTVCell
                cell.leftLabel.text = "greater than / less than"
                cell.rightButton.setTitle(filter.relationship.toString(), for: .normal)
                cell.buttonPressedAction = {
                    self.parentVC.slideUpOptionsChooser(options: ["Greater Than ( > )", "Less Than ( < )"], title: "Select option", completion: { (index) in
                        filter.relationship = ScannerFilter.FilterRelationship(rawValue: index)!
                        cell.rightButton.setTitle(filter.relationship.toString(), for: .normal)
                    })
                }
                return cell
            } else if row == 3 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterTFTVCell") as! FilterTFTVCell
                cell.leftLabel.text = "rValue"
                cell.rightTextField.text = filter.rValue.stringValue
                cell.newTextCompletion = { (text) in
                    if let v = Decimal(string: text) {
                        filter.rValue = v
                    }
                    cell.rightTextField.text = filter.rValue.stringValue
                }
                cell.textFieldStartedEditing = {
                    self.currentTextField = cell.rightTextField
                }
                cell.textFieldResignedCompletion = {
                    self.currentTextField = nil
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterButtonTVCell") as! FilterButtonTVCell
                cell.leftLabel.text = "Timeframe"
                cell.rightButton.setTitle(filter.timeframe.rawValue, for: .normal)
                cell.buttonPressedAction = {
                    self.parentVC.slideUpOptionsChooser(options: Timeframe.allValues(), title: "Select option", completion: { (index) in
                        filter.timeframe = Timeframe(rawValue: Timeframe.allValues()[index])!
                        cell.rightButton.setTitle(filter.timeframe.rawValue, for: .normal)
                    })
                }
                return cell
            }
            
        case .macd_bar, .macd_line, .macd_signal:
            if row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterTFTVCell") as! FilterTFTVCell
                cell.leftLabel.text = "Fast Length"
                cell.rightTextField.text = String(filter.properties[Indicator.PropertyKey.fastLength] as! Int)
                cell.newTextCompletion = { (text) in
                    if let v = Int(text) {
                        filter.properties[Indicator.PropertyKey.fastLength] = v
                    }
                    cell.rightTextField.text = String(filter.properties[Indicator.PropertyKey.fastLength] as! Int)
                }
                cell.textFieldStartedEditing = {
                    self.currentTextField = cell.rightTextField
                }
                cell.textFieldResignedCompletion = {
                    self.currentTextField = nil
                }
                return cell
            } else if row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterTFTVCell") as! FilterTFTVCell
                cell.leftLabel.text = "Slow Length"
                cell.rightTextField.text = String(filter.properties[Indicator.PropertyKey.slowLength] as! Int)
                cell.newTextCompletion = { (text) in
                    if let v = Int(text) {
                        filter.properties[Indicator.PropertyKey.slowLength] = v
                    }
                    cell.rightTextField.text = String(filter.properties[Indicator.PropertyKey.slowLength] as! Int)
                }
                cell.textFieldStartedEditing = {
                    self.currentTextField = cell.rightTextField
                }
                cell.textFieldResignedCompletion = {
                    self.currentTextField = nil
                }
                return cell
            } else if row == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterTFTVCell") as! FilterTFTVCell
                cell.leftLabel.text = "Signal Smoothing Length"
                cell.rightTextField.text = String(filter.properties[Indicator.PropertyKey.signalSmoothingLength] as! Int)
                cell.newTextCompletion = { (text) in
                    if let v = Int(text) {
                        filter.properties[Indicator.PropertyKey.signalSmoothingLength] = v
                    }
                    cell.rightTextField.text = String(filter.properties[Indicator.PropertyKey.signalSmoothingLength] as! Int)
                }
                cell.textFieldStartedEditing = {
                    self.currentTextField = cell.rightTextField
                }
                cell.textFieldResignedCompletion = {
                    self.currentTextField = nil
                }
                return cell
            } else if row == 3 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterButtonTVCell") as! FilterButtonTVCell
                cell.leftLabel.text = "greater than / less than"
                cell.rightButton.setTitle(filter.relationship.toString(), for: .normal)
                cell.buttonPressedAction = {
                    self.parentVC.slideUpOptionsChooser(options: ["Greater Than ( > )", "Less Than ( < )"], title: "Select option", completion: { (index) in
                        filter.relationship = ScannerFilter.FilterRelationship(rawValue: index)!
                        cell.rightButton.setTitle(filter.relationship.toString(), for: .normal)
                    })
                }
                return cell
            } else if row == 4 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterTFTVCell") as! FilterTFTVCell
                cell.leftLabel.text = "rValue"
                cell.rightTextField.text = filter.rValue.stringValue
                cell.newTextCompletion = { (text) in
                    if let v = Decimal(string: text) {
                        filter.rValue = v
                    }
                    cell.rightTextField.text = filter.rValue.stringValue
                }
                cell.textFieldStartedEditing = {
                    self.currentTextField = cell.rightTextField
                }
                cell.textFieldResignedCompletion = {
                    self.currentTextField = nil
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterButtonTVCell") as! FilterButtonTVCell
                cell.leftLabel.text = "Timeframe"
                cell.rightButton.setTitle(filter.timeframe.rawValue, for: .normal)
                cell.buttonPressedAction = {
                    self.parentVC.slideUpOptionsChooser(options: Timeframe.allValues(), title: "Select option", completion: { (index) in
                        filter.timeframe = Timeframe(rawValue: Timeframe.allValues()[index])!
                        cell.rightButton.setTitle(filter.timeframe.rawValue, for: .normal)
                    })
                }
                return cell
            }
            
        case .rsi:
            if row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterTFTVCell") as! FilterTFTVCell
                cell.leftLabel.text = "RSI Length"
                cell.rightTextField.text = String(filter.properties[Indicator.PropertyKey.length] as! Int)
                cell.newTextCompletion = { (text) in
                    if let v = Int(text) {
                        filter.properties[Indicator.PropertyKey.length] = v
                    }
                    cell.rightTextField.text = String(filter.properties[Indicator.PropertyKey.length] as! Int)
                }
                cell.textFieldStartedEditing = {
                    self.currentTextField = cell.rightTextField
                }
                cell.textFieldResignedCompletion = {
                    self.currentTextField = nil
                }
                return cell
            } else if row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterButtonTVCell") as! FilterButtonTVCell
                cell.leftLabel.text = "greater than / less than"
                cell.rightButton.setTitle(filter.relationship.toString(), for: .normal)
                cell.buttonPressedAction = {
                    self.parentVC.slideUpOptionsChooser(options: ["Greater Than ( > )", "Less Than ( < )"], title: "Select option", completion: { (index) in
                        filter.relationship = ScannerFilter.FilterRelationship(rawValue: index)!
                        cell.rightButton.setTitle(filter.relationship.toString(), for: .normal)
                    })
                }
                return cell
            } else if row == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterTFTVCell") as! FilterTFTVCell
                cell.leftLabel.text = "rValue"
                cell.rightTextField.text = filter.rValue.stringValue
                cell.newTextCompletion = { (text) in
                    if let v = Decimal(string: text) {
                        filter.rValue = v
                    }
                    cell.rightTextField.text = filter.rValue.stringValue
                }
                cell.textFieldStartedEditing = {
                    self.currentTextField = cell.rightTextField
                }
                cell.textFieldResignedCompletion = {
                    self.currentTextField = nil
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterButtonTVCell") as! FilterButtonTVCell
                cell.leftLabel.text = "Timeframe"
                cell.rightButton.setTitle(filter.timeframe.rawValue, for: .normal)
                cell.buttonPressedAction = {
                    self.parentVC.slideUpOptionsChooser(options: Timeframe.allValues(), title: "Select option", completion: { (index) in
                        filter.timeframe = Timeframe(rawValue: Timeframe.allValues()[index])!
                        cell.rightButton.setTitle(filter.timeframe.rawValue, for: .normal)
                    })
                }
                return cell
            }
        case .rsi_divergence:
            if row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterTFTVCell") as! FilterTFTVCell
                cell.leftLabel.text = "RSI Length"
                cell.rightTextField.text = String(filter.properties[Indicator.PropertyKey.length] as! Int)
                cell.newTextCompletion = { (text) in
                    if let v = Int(text) {
                        filter.properties[Indicator.PropertyKey.length] = v
                    }
                    cell.rightTextField.text = String(filter.properties[Indicator.PropertyKey.length] as! Int)
                }
                cell.textFieldStartedEditing = {
                    self.currentTextField = cell.rightTextField
                }
                cell.textFieldResignedCompletion = {
                    self.currentTextField = nil
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterButtonTVCell") as! FilterButtonTVCell
                cell.leftLabel.text = "Timeframe"
                cell.rightButton.setTitle(filter.timeframe.rawValue, for: .normal)
                cell.buttonPressedAction = {
                    self.parentVC.slideUpOptionsChooser(options: Timeframe.allValues(), title: "Select option", completion: { (index) in
                        filter.timeframe = Timeframe(rawValue: Timeframe.allValues()[index])!
                        cell.rightButton.setTitle(filter.timeframe.rawValue, for: .normal)
                    })
                }
                return cell
            }
        case .green_candle:
            if row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterButtonTVCell") as! FilterButtonTVCell
                cell.leftLabel.text = "greater than / less than"
                cell.rightButton.setTitle(filter.relationship.toString(), for: .normal)
                cell.buttonPressedAction = {
                    self.parentVC.slideUpOptionsChooser(options: ["Greater Than ( > )", "Less Than ( < )"], title: "Select option", completion: { (index) in
                        filter.relationship = ScannerFilter.FilterRelationship(rawValue: index)!
                        cell.rightButton.setTitle(filter.relationship.toString(), for: .normal)
                    })
                }
                return cell
            } else if row == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterTFTVCell") as! FilterTFTVCell
                cell.leftLabel.text = "rValue"
                cell.rightTextField.text = filter.rValue.stringValue
                cell.newTextCompletion = { (text) in
                    if let v = Decimal(string: text) {
                        filter.rValue = v
                    }
                    cell.rightTextField.text = filter.rValue.stringValue
                }
                cell.textFieldStartedEditing = {
                    self.currentTextField = cell.rightTextField
                }
                cell.textFieldResignedCompletion = {
                    self.currentTextField = nil
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FilterButtonTVCell") as! FilterButtonTVCell
                cell.leftLabel.text = "Timeframe"
                cell.rightButton.setTitle(filter.timeframe.rawValue, for: .normal)
                cell.buttonPressedAction = {
                    self.parentVC.slideUpOptionsChooser(options: Timeframe.allValues(), title: "Select option", completion: { (index) in
                        filter.timeframe = Timeframe(rawValue: Timeframe.allValues()[index])!
                        cell.rightButton.setTitle(filter.timeframe.rawValue, for: .normal)
                    })
                }
                return cell
            }
        }
    }
    


    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    
    
    
}
