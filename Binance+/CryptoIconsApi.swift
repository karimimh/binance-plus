//
//  CryptoIconsApi.swift
//  Binance+
//
//  Created by Behnam Karimi on 1/17/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import Network
import UIKit

class CryptoIconsApi {
    static func getIcon(for symbol: Symbol, completion: @escaping (UIImage?) -> Void) {
        let ur = URL(string: "https://github.com/atomiclabs/cryptocurrency-icons/raw/master/128/color/" + symbol.baseAsset.lowercased() + ".png")
        guard let url = ur else {
            completion(nil)
            return
        }
        let task = URLSession.shared.dataTask(with: url) { (dat, response, error) in
            guard error == nil else {
                completion(nil)
                return
            }
            guard let data = dat else {
                completion(nil)
                return
            }
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                completion(image)
            }
            
        }
        task.resume()
    }
}
