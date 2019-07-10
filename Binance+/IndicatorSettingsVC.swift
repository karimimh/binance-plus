//
//  IndicatorSettingsVC.swift
//  Binance+
//
//  Created by Behnam Karimi on 3/27/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class IndicatorSettingsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var settingsTableView: UITableView!
    
    
    var chartVC: ChartVC!
    var parentVC: ParentVC! {
        get {
            return chartVC.parentVC
        }
    }
    var indicator: Indicator? {
        get {
            if chartVC == nil {
                return nil
            }
            return chartVC.activeIndicator
        }
    }
    
    
    var currentEditingTextField: UITextField?
    var leftBBI: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        settingsTableView.tableFooterView = UIView()
        
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        
        settingsTableView.allowsSelection = false
        
        
        
        
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        tapGR.cancelsTouchesInView = false
        self.chartVC.superV.addGestureRecognizer(tapGR)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let ind = self.indicator else {
            return 0
        }
        
        let n: Int
        switch ind.indicatorType {
        case .volume,.sma,.ema,.rsi:
            n = 4
        case .macd:
            n = 10
        case .bollinger_bands:
            n = 7
        }
        
        return n
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let indicator = self.indicator else {
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        switch indicator.indicatorType {
        case .volume:
            switch indexPath.row {
            case 0:
                //color
                let cell = tableView.dequeueReusableCell(withIdentifier: "ColorTVCell", for: indexPath) as! ColorTVCell
                cell.label.text = "Color"
                let color = indicator.properties[Indicator.PropertyKey.color_1] as! UIColor
                cell.button.setTitle(nil, for: .normal)
                cell.button.backgroundColor = color
                cell.buttonPressedAction = {
                    self.chartVC.colorPalletCVCCompletion = { (c) in
                        if let col = c {
                            cell.button.backgroundColor = col
                            indicator.properties[Indicator.PropertyKey.color_1] = c
                            self.apply()
                        }
                    }
                }
                
                return cell
            case 1:
                //sma length
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldTVCell", for: indexPath) as! TextFieldTVCell
                cell.label.text = "SMA Length"
                let smaLength = indicator.properties[Indicator.PropertyKey.length] as! Int
                cell.textField.text = String(smaLength)
                
                cell.newTextCompletion = {(text) in
                    guard let f = Double(text) else {
                        cell.textField.text = String(smaLength)
                        return
                    }
                    let l = Int(f)
                    cell.textField.text = String(l)
                    indicator.properties[Indicator.PropertyKey.length] = l
                    self.apply()
                }
                
                cell.textFieldStartedEditing = { () in
                    self.currentEditingTextField = cell.textField
                }
                
                cell.textFieldResignedCompletion = { () in
                    self.currentEditingTextField = nil
                }
                return cell
            case 2:
                //sma line width
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldTVCell", for: indexPath) as! TextFieldTVCell
                cell.label.text = "SMA LineWidth"
                let smaLineWidth = indicator.properties[Indicator.PropertyKey.line_width_1] as! CGFloat
                cell.textField.text = String(Double(smaLineWidth))
                cell.newTextCompletion = {(text) in
                    guard let f = Double(text) else {
                        cell.textField.text = String(Double(smaLineWidth))
                        return
                    }
                    let w = CGFloat(f)
                    cell.textField.text = String(f)
                    indicator.properties[Indicator.PropertyKey.line_width_1] = w
                    self.apply()
                }
                cell.textFieldStartedEditing = { () in
                    self.currentEditingTextField = cell.textField
                }
                cell.textFieldResignedCompletion = { () in
                    self.currentEditingTextField = nil
                }
                
                return cell
            case 3:
                //sma color
                let cell = tableView.dequeueReusableCell(withIdentifier: "ColorTVCell", for: indexPath) as! ColorTVCell
                cell.label.text = "SMA Color"
                let smaColor = indicator.properties[Indicator.PropertyKey.color_2] as! UIColor
                cell.button.setTitle(nil, for: .normal)
                cell.button.backgroundColor = smaColor
                cell.buttonPressedAction = {
                    self.chartVC.colorPalletCVCCompletion = { (c) in
                        if let col = c {
                            cell.button.backgroundColor = col
                            indicator.properties[Indicator.PropertyKey.color_2] = c
                            self.apply()
                        }
                    }
                }
                
                
                return cell
            default:
                return UITableViewCell(style: .default, reuseIdentifier: nil)
            }
        //SMA:
        case .sma, .ema, .rsi:
            
            switch indexPath.row {
            case 0:
                //source
                let cell = tableView.dequeueReusableCell(withIdentifier: "OptionalTVCell", for: indexPath) as! OptionalTVCell
                cell.label.text = "Source"
                let option = indicator.properties[Indicator.PropertyKey.source] as! String
                cell.options = ["Open", "High", "Low", "Close"]
                cell.parentVC = parentVC
                cell.completion = { (index) in
                    cell.button.setTitle(cell.options[index], for: .normal)
                    indicator.properties[Indicator.PropertyKey.source] = cell.options[index]
                    self.apply()
                }
                cell.button.setTitle(option, for: .normal)
                return cell
            case 1:
                //length
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldTVCell", for: indexPath) as! TextFieldTVCell
                cell.label.text = "Length"
                let smaLength = indicator.properties[Indicator.PropertyKey.length] as! Int
                cell.textField.text = String(smaLength)
                
                cell.newTextCompletion = {(text) in
                    guard let f = Double(text) else {
                        cell.textField.text = String(smaLength)
                        return
                    }
                    let l = Int(f)
                    cell.textField.text = String(l)
                    indicator.properties[Indicator.PropertyKey.length] = l
                    self.apply()
                }
                cell.textFieldStartedEditing = { () in
                    self.currentEditingTextField = cell.textField
                }
                cell.textFieldResignedCompletion = { () in
                    self.currentEditingTextField = nil
                }
                
                return cell
            case 2:
                //color
                let cell = tableView.dequeueReusableCell(withIdentifier: "ColorTVCell", for: indexPath) as! ColorTVCell
                cell.label.text = "Color"
                let color = indicator.properties[Indicator.PropertyKey.color_1] as! UIColor
                cell.button.setTitle(nil, for: .normal)
                cell.button.backgroundColor = color
                cell.buttonPressedAction = {
                    self.chartVC.colorPalletCVCCompletion = { (c) in
                        if let col = c {
                            cell.button.backgroundColor = col
                            indicator.properties[Indicator.PropertyKey.color_1] = c
                            self.apply()
                        }
                    }
                }
                
                
                return cell
            case 3:
                //lineWidth
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldTVCell", for: indexPath) as! TextFieldTVCell
                cell.label.text = "Line Width"
                let smaLineWidth = indicator.properties[Indicator.PropertyKey.line_width_1] as! CGFloat
                cell.textField.text = String(Double(smaLineWidth))
                
                cell.newTextCompletion = {(text) in
                    guard let f = Double(text) else {
                        cell.textField.text = String(Double(smaLineWidth))
                        return
                    }
                    let w = CGFloat(f)
                    cell.textField.text = String(f)
                    indicator.properties[Indicator.PropertyKey.line_width_1] = w
                    self.apply()
                }
                cell.textFieldStartedEditing = { () in
                    self.currentEditingTextField = cell.textField
                }
                cell.textFieldResignedCompletion = { () in
                    self.currentEditingTextField = nil
                }
                
                return cell
            default:
                return UITableViewCell(style: .default, reuseIdentifier: nil)
            }
        case .macd:
            
            switch indexPath.row {
            case 0:
                //source
                let cell = tableView.dequeueReusableCell(withIdentifier: "OptionalTVCell", for: indexPath) as! OptionalTVCell
                cell.label.text = "Source"
                let option = indicator.properties[Indicator.PropertyKey.source] as! String
                
                cell.options = ["Open", "High", "Low", "Close"]
                cell.parentVC = parentVC
                cell.completion = { (index) in
                    cell.button.setTitle(cell.options[index], for: .normal)
                    indicator.properties[Indicator.PropertyKey.source] = cell.options[index]
                    self.apply()
                }
                cell.button.setTitle(option, for: .normal)
                
                return cell
            case 1:
                //fast length
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldTVCell", for: indexPath) as! TextFieldTVCell
                cell.label.text = "Fast Length"
                let fastLength = indicator.properties[Indicator.PropertyKey.fastLength] as! Int
                cell.textField.text = String(fastLength)
                
                cell.newTextCompletion = {(text) in
                    guard let f = Double(text) else {
                        cell.textField.text = String(fastLength)
                        return
                    }
                    let l = Int(f)
                    cell.textField.text = String(l)
                    indicator.properties[Indicator.PropertyKey.fastLength] = l
                    self.apply()
                }
                cell.textFieldStartedEditing = { () in
                    self.currentEditingTextField = cell.textField
                }
                cell.textFieldResignedCompletion = { () in
                    self.currentEditingTextField = nil
                }
                
                return cell
            case 2:
                //slow length
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldTVCell", for: indexPath) as! TextFieldTVCell
                cell.label.text = "Slow Length"
                let slowLength = indicator.properties[Indicator.PropertyKey.slowLength] as! Int
                cell.textField.text = String(slowLength)
                
                cell.newTextCompletion = {(text) in
                    guard let f = Double(text) else {
                        cell.textField.text = String(slowLength)
                        return
                    }
                    let l = Int(f)
                    cell.textField.text = String(l)
                    indicator.properties[Indicator.PropertyKey.slowLength] = l
                    self.apply()
                }
                cell.textFieldStartedEditing = { () in
                    self.currentEditingTextField = cell.textField
                }
                cell.textFieldResignedCompletion = { () in
                    self.currentEditingTextField = nil
                }
                
                return cell
            case 3:
                //signal smoothing length
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldTVCell", for: indexPath) as! TextFieldTVCell
                cell.label.text = "Signal Smoothing Length"
                let signalSmoothingLength = indicator.properties[Indicator.PropertyKey.signalSmoothingLength] as! Int
                cell.textField.text = String(signalSmoothingLength)
                
                cell.newTextCompletion = {(text) in
                    guard let f = Double(text) else {
                        cell.textField.text = String(signalSmoothingLength)
                        return
                    }
                    let l = Int(f)
                    cell.textField.text = String(l)
                    indicator.properties[Indicator.PropertyKey.signalSmoothingLength] = l
                    self.apply()
                }
                cell.textFieldStartedEditing = { () in
                    self.currentEditingTextField = cell.textField
                }
                cell.textFieldResignedCompletion = { () in
                    self.currentEditingTextField = nil
                }
                
                return cell
            case 4:
                //macd color
                let cell = tableView.dequeueReusableCell(withIdentifier: "ColorTVCell", for: indexPath) as! ColorTVCell
                cell.label.text = "MACD Color"
                let macdColor = indicator.properties[Indicator.PropertyKey.color_1] as! UIColor
                cell.button.setTitle(nil, for: .normal)
                cell.button.backgroundColor = macdColor
                cell.buttonPressedAction = {
                    self.chartVC.colorPalletCVCCompletion = { (c) in
                        if let col = c {
                            cell.button.backgroundColor = col
                            indicator.properties[Indicator.PropertyKey.color_1] = c
                            self.apply()
                        }
                    }
                    
                }
                
                return cell
            case 5:
                //macd color
                let cell = tableView.dequeueReusableCell(withIdentifier: "ColorTVCell", for: indexPath) as! ColorTVCell
                cell.label.text = "Signal Color"
                let signalColor = indicator.properties[Indicator.PropertyKey.color_2] as! UIColor
                cell.button.setTitle(nil, for: .normal)
                cell.button.backgroundColor = signalColor
                cell.buttonPressedAction = {
                    self.chartVC.colorPalletCVCCompletion = { (c) in
                        if let col = c {
                            cell.button.backgroundColor = col
                            indicator.properties[Indicator.PropertyKey.color_2] = c
                            self.apply()
                        }
                    }
                }
                
                
                return cell
            case 6:
                //macd lineWidth
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldTVCell", for: indexPath) as! TextFieldTVCell
                cell.label.text = "MACD Line Width"
                let macdLineWidth = indicator.properties[Indicator.PropertyKey.line_width_1] as! CGFloat
                cell.textField.text = String(Double(macdLineWidth))
                
                cell.newTextCompletion = {(text) in
                    guard let f = Double(text) else {
                        cell.textField.text = String(Double(macdLineWidth))
                        return
                    }
                    let w = CGFloat(f)
                    cell.textField.text = String(f)
                    indicator.properties[Indicator.PropertyKey.line_width_1] = w
                    self.apply()
                }
                cell.textFieldStartedEditing = { () in
                    self.currentEditingTextField = cell.textField
                }
                cell.textFieldResignedCompletion = { () in
                    self.currentEditingTextField = nil
                }
                
                return cell
            case 7:
                //signal lineWidth
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldTVCell", for: indexPath) as! TextFieldTVCell
                cell.label.text = "Signal Line Width"
                let signalLineWidth = indicator.properties[Indicator.PropertyKey.line_width_2] as! CGFloat
                cell.textField.text = String(Double(signalLineWidth))
                
                cell.newTextCompletion = {(text) in
                    guard let f = Double(text) else {
                        cell.textField.text = String(Double(signalLineWidth))
                        return
                    }
                    let w = CGFloat(f)
                    cell.textField.text = String(f)
                    indicator.properties[Indicator.PropertyKey.line_width_2] = w
                    self.apply()
                }
                cell.textFieldStartedEditing = { () in
                    self.currentEditingTextField = cell.textField
                }
                cell.textFieldResignedCompletion = { () in
                    self.currentEditingTextField = nil
                }
                
                
                return cell
            case 8:
                //positive bar color
                let cell = tableView.dequeueReusableCell(withIdentifier: "ColorTVCell", for: indexPath) as! ColorTVCell
                cell.label.text = "Positive Bar Color"
                let positiveBarColor = indicator.properties[Indicator.PropertyKey.color_3] as! UIColor
                cell.button.setTitle(nil, for: .normal)
                cell.button.backgroundColor = positiveBarColor
                cell.buttonPressedAction = {
                    self.chartVC.colorPalletCVCCompletion = { (c) in
                        if let col = c {
                            cell.button.backgroundColor = col
                            indicator.properties[Indicator.PropertyKey.color_3] = c
                            self.apply()
                        }
                    }
                }
                
                
                return cell
            case 9:
                //negative bar color
                let cell = tableView.dequeueReusableCell(withIdentifier: "ColorTVCell", for: indexPath) as! ColorTVCell
                cell.label.text = "Negative Bar Color"
                let negativeBarColor = indicator.properties[Indicator.PropertyKey.color_4] as! UIColor
                cell.button.setTitle(nil, for: .normal)
                cell.button.backgroundColor = negativeBarColor
                cell.buttonPressedAction = {
                    self.chartVC.colorPalletCVCCompletion = { (c) in
                        if let col = c {
                            cell.button.backgroundColor = col
                            indicator.properties[Indicator.PropertyKey.color_4] = c
                            self.apply()
                        }
                    }
                }
                
                
                return cell
            default:
                return UITableViewCell(style: .default, reuseIdentifier: nil)
            }
        case .bollinger_bands:
            
            switch indexPath.row {
            case 0:
                //source
                let cell = tableView.dequeueReusableCell(withIdentifier: "OptionalTVCell", for: indexPath) as! OptionalTVCell
                cell.label.text = "Source"
                
                let option = indicator.properties[Indicator.PropertyKey.source] as! String
                cell.options = ["Open", "High", "Low", "Close"]
                cell.parentVC = parentVC
                cell.completion = { (index) in
                    cell.button.setTitle(cell.options[index], for: .normal)
                    indicator.properties[Indicator.PropertyKey.source] = cell.options[index]
                    self.apply()
                }
                cell.button.setTitle(option, for: .normal)
                return cell
            case 1:
                //length
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldTVCell", for: indexPath) as! TextFieldTVCell
                cell.label.text = "Length"
                let length = indicator.properties[Indicator.PropertyKey.fastLength] as! Int
                cell.textField.text = String(length)
                
                cell.newTextCompletion = {(text) in
                    guard let f = Double(text) else {
                        cell.textField.text = String(length)
                        return
                    }
                    let l = Int(f)
                    cell.textField.text = String(l)
                    indicator.properties[Indicator.PropertyKey.fastLength] = l
                    self.apply()
                }
                cell.textFieldStartedEditing = { () in
                    self.currentEditingTextField = cell.textField
                }
                cell.textFieldResignedCompletion = { () in
                    self.currentEditingTextField = nil
                }
                
                
                return cell
            case 2:
                //stdDev
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldTVCell", for: indexPath) as! TextFieldTVCell
                cell.label.text = "stdDev"
                let stdDev = indicator.properties[Indicator.PropertyKey.slowLength] as! Int
                cell.textField.text = String(stdDev)
                
                cell.newTextCompletion = {(text) in
                    guard let f = Double(text) else {
                        cell.textField.text = String(stdDev)
                        return
                    }
                    let l = Int(f)
                    cell.textField.text = String(l)
                    indicator.properties[Indicator.PropertyKey.slowLength] = l
                    self.apply()
                }
                cell.textFieldStartedEditing = { () in
                    self.currentEditingTextField = cell.textField
                }
                cell.textFieldResignedCompletion = { () in
                    self.currentEditingTextField = nil
                }
                
                
                return cell
            case 3:
                //show middle band
                let cell = tableView.dequeueReusableCell(withIdentifier: "OptionalTVCell", for: indexPath) as! OptionalTVCell
                cell.label.text = "Show Middle Band"
                let showMiddleBand = indicator.properties[Indicator.PropertyKey.showMiddleBand] as! Bool
                cell.options = ["Yes", "No"]
                cell.parentVC = parentVC
                cell.completion = { (index) in
                    cell.button.setTitle((index == 0) ? "Yes" : "No", for: .normal)
                    indicator.properties[Indicator.PropertyKey.source] = Bool(index == 0)
                }
                cell.button.setTitle(showMiddleBand ? "Yes" : "No", for: .normal)
                return cell
            case 4:
                //color
                let cell = tableView.dequeueReusableCell(withIdentifier: "ColorTVCell", for: indexPath) as! ColorTVCell
                cell.label.text = "Color"
                let color = indicator.properties[Indicator.PropertyKey.color_1] as! UIColor
                cell.button.setTitle(nil, for: .normal)
                cell.button.backgroundColor = color
                cell.buttonPressedAction = {
                    self.chartVC.colorPalletCVCCompletion = { (c) in
                        if let col = c {
                            cell.button.backgroundColor = col
                            indicator.properties[Indicator.PropertyKey.color_1] = c
                            self.apply()
                        }
                    }
                    
                }
                
                return cell
            case 5:
                //lineWidth
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldTVCell", for: indexPath) as! TextFieldTVCell
                cell.label.text = "Line Width"
                let lineWidth = indicator.properties[Indicator.PropertyKey.line_width_1] as! CGFloat
                cell.textField.text = String(Double(lineWidth))
                
                cell.newTextCompletion = {(text) in
                    guard let f = Double(text) else {
                        cell.textField.text = String(Double(lineWidth))
                        return
                    }
                    let w = CGFloat(f)
                    cell.textField.text = String(f)
                    indicator.properties[Indicator.PropertyKey.line_width_1] = w
                    self.apply()
                }
                cell.textFieldStartedEditing = { () in
                    self.currentEditingTextField = cell.textField
                }
                cell.textFieldResignedCompletion = { () in
                    self.currentEditingTextField = nil
                }
                
                
                return cell
            default:
                return UITableViewCell(style: .default, reuseIdentifier: nil)
            }
        }
        
    }
    
    
    
     func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
     }
     
     func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
     }
    
    func apply() {
        self.chartVC.app.save()
        chartVC.chart.update()
    }
    
    
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        if let tf = currentEditingTextField {
            tf.resignFirstResponder()
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let colorPalletVC as ColorPalletCVC:
            colorPalletVC.chartVC = self.chartVC
        default:
            break
        }
    }
}
