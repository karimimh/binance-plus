//
//  LaunchVC.swift
//  Binance+
//
//  Created by Behnam Karimi on 1/17/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit
import os.log
import SpriteKit

class LaunchVC: UIViewController {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageView: UIImageView!
    
    var app: App!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.image = Util.createGradientImage(color1: UIColor.fromHex(hex: "#16BEFF"), color2: UIColor.fromHex(hex: "#16BEFF"), width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        
        connect {
            if let savedApp = self.loadApp() {
                self.app = savedApp
                for symbol in self.app.allBinanceSymbols {
                    if let image = UIImage(named: symbol.baseAsset.lowercased() + ".png") {
                        symbol.iconImage = image
                    } else {
                        symbol.iconImage = UIImage()
                    }
                }
                self.presentTheViewController()
            } else {
                self.app = App()
                self.app.appFirstTimeLaunch = true
                self.getExchageInfo {
                    self.createLists {
                        self.downloadSymbolsAll24HPriceChangeStatistics {
                            self.loadSymbolIcons {
                                self.app.save()
                                self.presentTheViewController { }
                            }
                        }
                    }
                }
            }
        }
        

        
    }
    
    //MARK: - Private Methods
    private func connect(completion: @escaping () -> Void) {
        BinanaceApi.connect { (connected) in
            if !connected {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                }
                return
            } else {
                DispatchQueue.main.async {
                    self.activityIndicator.startAnimating()
                }
                completion()
            }
        }
    }
    
    
    private func getExchageInfo(completion: @escaping () -> Void) {
        BinanaceApi.getExchangeInfo { (json) in
            guard let exchangeInfo = json else { return }
            self.app.allBinanceSymbols.removeAll()
            let symbolsJsonArray = exchangeInfo["symbols"] as! [[String: Any]]
            for symbolInfo in symbolsJsonArray {
                let symbolName = symbolInfo["symbol"] as! String
                let symbolStatus = symbolInfo["status"] as! String
                let baseAsset = symbolInfo["baseAsset"] as! String
                let baseAssetPrecision = symbolInfo["baseAssetPrecision"] as! Int
                let quoteAsset = symbolInfo["quoteAsset"] as! String
                let quoteAssetPrecision = symbolInfo["quotePrecision"] as! Int
                /*let orderTypes = symbolInfo["orderTypes"]
                 let icebergAllowed = symbolInfo["icebergAllowed"]*/
                let filters = symbolInfo["filters"] as! [[String: Any]]
                
                
                
                let symbol = Symbol(name: symbolName, status: symbolStatus, baseAsset: baseAsset, baseAssetPrecision: baseAssetPrecision, quoteAsset: quoteAsset, quoteAssetPrecision: quoteAssetPrecision)
                
                
                //filters:
                for filter in filters {
                    let filterType = filter["filterType"] as! String
                    if filterType == "PRICE_FILTER" {
                        let tickSize = Decimal(string: filter["tickSize"] as! String)!
                        symbol.tickSize = tickSize
                    } else if filterType == "LOT_SIZE" {
                        let stepSize = Decimal(string: filter["stepSize"] as! String)!
                        symbol.stepSize = stepSize
                    }
                }
                
                self.app.allBinanceSymbols.append(symbol)
                
            }

            completion()
        }
    }
    
    
    private func createLists(completion: @escaping () -> Void) {
        
        let predefinedLists = ["BTC", "ETH", "BNB", "PAX", "XRP"]
        
        for symbol in app.allBinanceSymbols {
            let quoteAsset = symbol.quoteAsset
            if let list = self.app.getList(with: quoteAsset) {
                list.symbols.append(symbol.name)
            } else {
                let newList = List(name: quoteAsset, isServerList: true)
                newList.isServerList = true
                newList.symbols.append(symbol.name)
                app.lists.append(newList)
            }
        }
        
        for i in 0 ..< predefinedLists.count {
            let listName = predefinedLists[i]
            let index = app.getListIndex(with: listName)
            app.lists.swapAt(index, i)
        }
        
        completion()
    }
    
    private func downloadSymbolsAll24HPriceChangeStatistics(completion: @escaping () -> Void) {
        BinanaceApi.all24HPriceChagneStatistics { (array) in
            guard let jsonArray = array else { return }
            for json in jsonArray {
                let symbolName = json["symbol"] as! String
                let closePrice = json["prevClosePrice"] as! String
                let baseAssetVolume = json["volume"] as! String
                let quoteAssetVolume = json["quoteVolume"] as! String
                let percentChange = json["priceChangePercent"] as! String
                
                guard let symbol = self.app.getSymbol(symbolName) else { return }
                
                symbol.price = Decimal(string: closePrice)!
                symbol.volume = Decimal(string: baseAssetVolume)!
                symbol.quoteAssetVolume = Decimal(string: quoteAssetVolume)!
                symbol.percentChange = Decimal(string: percentChange)!
                
            }
            completion()
        }
    }
    
    private func loadSymbolIcons(completion: @escaping () -> Void) {
        for i in 0..<app.allBinanceSymbols.count {
            let symbol = app.allBinanceSymbols[i]
            if let image = UIImage(named: symbol.baseAsset.lowercased() + ".png") {
                symbol.iconImage = image
            } else {
                symbol.iconImage = UIImage()
            }
        }
        completion()
    }
    
    
    
    
    
    
    // MARK: - Navigation
    
    private func presentTheViewController(completion: @escaping () -> Void = {}) {
        DispatchQueue.main.async {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "ParentVC") as! ParentVC
            vc.app = self.app
            self.present(vc, animated: true, completion: completion)
        }
    }
    
    private func saveImageDocumentDirectory(image: UIImage, symbol: Symbol) {
        let fileManager = FileManager.default
        let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("icons")
        if !fileManager.fileExists(atPath: path) {
            try! fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        let url = NSURL(string: path)
        let imagePath = url!.appendingPathComponent(symbol.baseAsset.lowercased() + ".png")
        let urlString: String = imagePath!.absoluteString
        let imageData = image.pngData()!
        fileManager.createFile(atPath: urlString as String, contents: imageData, attributes: nil)
    }
    
    private func getImageFromDocumentDirectory(symbol: Symbol) -> UIImage? {
        let fileManager = FileManager.default
        let imagePath = (self.getDirectoryPath() as NSURL).appendingPathComponent(symbol.baseAsset.lowercased() + ".png")
        let urlString: String = imagePath!.absoluteString
        if fileManager.fileExists(atPath: urlString) {
            let image = UIImage(contentsOfFile: urlString)
            return image
        }
        return nil
    }
    
    
    private func getDirectoryPath() -> NSURL {
        let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("icons")
        let url = NSURL(string: path)
        return url!
    }
    
    //MARK: Load Previous App Data
    
    func loadApp() -> App? {
        guard let data = try? Data(contentsOf: App.ArchiveURL) else {
            os_log("Failed to decode app url data content...", log: OSLog.default, type: .error)
            return nil
        }
        var result: App?
        do {
            result = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? App
        } catch {
            os_log("Failed to load App...", log: OSLog.default, type: .error)
        }
        return result
    }
}

