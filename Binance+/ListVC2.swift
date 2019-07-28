//
//  ListVC2.swift
//  Binance+
//
//  Created by Behnam Karimi on 5/1/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class ListVC2: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet weak var collectionView: UICollectionView!
    var app: App?
    

    override func viewDidLoad() {
        super.viewDidLoad()

        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            app = delegate.app
        }
        
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return app?.allBinanceSymbols.count ?? 0
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SymbolCVCell", for: indexPath) as! SymbolCVCell
        
        guard let app = self.app else {
            return cell
        }
        let symbol = app.allBinanceSymbols[indexPath.row]
        let name = symbol.name
        let price = symbol.price
        let priceChange = symbol.percentChange
        let volume = symbol.btcVolume(app)
        
        
        cell.nameLabel.text = name
        cell.priceLabel.text = "\(price)"
        cell.changeLabel.text = String(format: "%.2f%%", priceChange.doubleValue)
        if volume > 10 {
            cell.volumeLabel.text = "Volume: " + String(format: "%d", Int(volume.doubleValue)) + " ฿"
        } else {
            cell.volumeLabel.text = "Volume: " + String(format: "%.2f", volume.doubleValue) + " ฿"
        }
        
        if priceChange < 0 {
            cell.priceLabel.textColor = app.bearCandleColor
            cell.changeLabel.backgroundColor = app.bearCandleColor
        } else {
            cell.priceLabel.textColor = app.bullCandleColor
            cell.changeLabel.backgroundColor = app.bullCandleColor
        }
        cell.changeLabel.layer.masksToBounds = true
        cell.changeLabel.layer.cornerRadius = 5
        
        cell.previewChart.app = self.app
        cell.previewChart.symbol = symbol
        cell.previewChart.timeframe = .daily
        cell.previewChart.setNeedsDisplay()
        
        if symbol.lastesThirtyDailyCandles == nil {
            DispatchQueue.global(qos: .background).async {
                BinanaceAPI.getCandles(symbol: symbol, timeframe: .daily, limit: 30, completion: { (optionalCandles) in
                    if let candles = optionalCandles {
                        symbol.lastesThirtyDailyCandles = candles
                        DispatchQueue.main.async {
                            cell.previewChart.setNeedsDisplay()
                        }
                    }
                })
            }
        }
        
        if symbol.iconImage != nil {
            cell.iconImageView.image = symbol.iconImage
        } else {
            DispatchQueue.global(qos: .background).async {
                symbol.iconImage = UIImage(named: symbol.baseAsset.lowercased())
                DispatchQueue.main.async {
                    cell.iconImageView.image = symbol.iconImage
                }
            }
        }
        return cell
    }

    
    

}


// MARK: - Collection View Flow Layout Delegate
extension ListVC2 : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return CGSize(width: collectionView.bounds.width / 2, height: 80)
        }
        return CGSize(width: collectionView.bounds.width, height: 80)
    }

}


