//
//  IndicatorsVC.swift
//  Binance+
//
//  Created by Behnam Karimi on 3/26/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class IndicatorsVC: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    @IBOutlet weak var indicatorsTableView: UITableView!
    
    
    var chartVC: ChartVC!
    var editBBI: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        indicatorsTableView.tableFooterView = UIView()
        
        indicatorsTableView.delegate = self
        indicatorsTableView.dataSource = self
        
        indicatorsTableView.allowsSelection = true

        let navItem = navigationItem
        
        editBBI = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editTapped(_:)))
        navItem.leftBarButtonItem = editBBI
        
        let addBBI = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addIndicator(_:)))
        navItem.rightBarButtonItem = addBBI
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Indicators"
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let chartVC = self.chartVC else {
            return 0
        }
        if chartVC.chart == nil {
            return 0
        }
        
        return chartVC.chart.indicators.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IndicatorListTVCell") as! ColorTVCell
        guard let chart = chartVC?.chart else {
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        
        let ind = chart.indicators[indexPath.row]
        cell.label.text = ind.getNameInFunctionForm()
        cell.button.backgroundColor = ind.getColor()
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indicatorsTableView.isEditing {
            return
        }
        let indicator = chartVC.chart.indicators[indexPath.row]
        chartVC.activeIndicator = indicator
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            chartVC.chart.indicators.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            chartVC.chart.layoutChart()
        }
    }
    
    

    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    
    
    
    @IBAction func addIndicator(_ sender: UIBarButtonItem) {
        guard let chartVC = self.chartVC else {
            return
        }
        var options: [String] = ["SMA", "EMA"]
        var hasVolume = false
        var hasRSI = false
        var hasMACD = false
        var hasBOLL = false
        for ind in chartVC.chart.indicators {
            if ind.indicatorType == .volume {
                hasVolume = true
            } else if ind.indicatorType == .rsi {
                hasRSI = true
            } else if ind.indicatorType == .macd {
                hasMACD = true
            } else if ind.indicatorType == .bollinger_bands {
                hasBOLL = true
            }
        }
        if !hasVolume {
            options.append("Volume")
        }
        if !hasRSI {
            options.append("RSI")
        }
        if !hasMACD {
            options.append("MACD")
        }
        if !hasBOLL {
            options.append("Bollinger Bands")
        }
        chartVC.parentVC.slideUpOptionsChooser(options: options) { (index) in
            var p: Double = 10
            let per = chartVC.chart.mainFramePercentage
            if per - p < 20 {
                var found = false
                for iv in chartVC.chart.getNonZeroRowIndicatorViews() {
                    if iv.indicator.frameHeightPercentage >= 20 {
                        iv.indicator.frameHeightPercentage -= 10
                        found = true
                        break
                    }
                }
                if !found {
                    p = 0
                    for iv in chartVC.chart.getNonZeroRowIndicatorViews() {
                        if iv.indicator.frameHeightPercentage >= 5 {
                            iv.indicator.frameHeightPercentage -= 1
                            p += 1
                            if p >= 8 {
                                break
                            }
                        }
                        if p < 5 {
                            return
                        }
                    }
                }
            }
            
            var indicator: Indicator?
            switch options[index] {
            case "SMA":
                indicator = Indicator(indicatorType: .sma, properties: [:], frameRow: 0, frameHeightPercentage: 100)
                
            case "EMA":
                indicator = Indicator(indicatorType: .ema, properties: [:], frameRow: 0, frameHeightPercentage: 100)
                
            case "Volume":
                indicator = Indicator(indicatorType: .volume, properties: [:], frameRow: chartVC.chart.getNextRow(), frameHeightPercentage: p)
                
            case "RSI":
                indicator = Indicator(indicatorType: .rsi, properties: [:], frameRow: chartVC.chart.getNextRow(), frameHeightPercentage: p)
                
            case "MACD":
                indicator = Indicator(indicatorType: .macd, properties: [:], frameRow: chartVC.chart.getNextRow(), frameHeightPercentage: p)
                
            case "Bollinger Bands":
                indicator = Indicator(indicatorType: .bollinger_bands, properties: [:], frameRow: 0, frameHeightPercentage: 100)
                
            default:
                break
            }
            guard let ind = indicator  else { return }
            chartVC.chart.indicators.append(ind)
            self.chartVC.chart.layoutChart()
            chartVC.activeIndicator = ind
            self.indicatorsTableView.reloadData()
        }
    }
    
    
    @IBAction func editTapped(_ sender: UIBarButtonItem) {
        toggleEditing()
    }
    
    private func toggleEditing() {
        if(self.indicatorsTableView.isEditing == true)
        {
            self.indicatorsTableView.isEditing = false
            editBBI.title = "Edit"
            self.chartVC.app.save()
        }
        else
        {
            self.indicatorsTableView.isEditing = true
            editBBI.title = "Done"
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let indSettingsVC as IndicatorSettingsVC:
            indSettingsVC.chartVC = self.chartVC
        default:
            break
        }
    }
}
