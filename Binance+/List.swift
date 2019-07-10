//
//  List.swift
//  Binance+
//
//  Created by Behnam Karimi on 12/24/1397 AP.
//  Copyright © 1397 AP Behnam Karimi. All rights reserved.
//

import Foundation
import UIKit
import os.log

class List: NSObject, NSCoding {
    
    //MARK: - Properties
    var name: String
    var isServerList: Bool
    var symbols = [String]()

    
    //MARK: Types
    struct Key {
        static let name = "list.name"
        static let symbols = "list.symbols"
        static let isServerList = "list.isServerList"
    }
    
    
    
    
    //MARK: - Initialization
    init(name: String, isServerList: Bool) {
        self.name = name
        self.isServerList = isServerList
        super.init()
    }
    
    init(name: String, symbols: [String], isServerList: Bool) {
        self.name = name
        self.symbols = symbols
        self.isServerList = isServerList
        super.init()
    }

    
    //MARK: - NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: Key.name)
        aCoder.encode(symbols, forKey: Key.symbols)
        aCoder.encode(isServerList, forKey: Key.isServerList)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(forKey: Key.name) as? String else {
            os_log("Unable to decode the name for a List object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let symbols = aDecoder.decodeObject(forKey: Key.symbols) as? [String] else {
            os_log("Unable to decode the symbols for a List object.", log: OSLog.default, type: .debug)
            return nil
        }
        let isServerList = aDecoder.decodeBool(forKey: Key.isServerList)
        
        
        self.init(name: name, symbols: symbols, isServerList: isServerList)
    }
    
    //MARK: - Public Methods
    func getSymbols(_ app: App) -> [Symbol] {
        var arr = [Symbol]()
        for name in symbols {
            if let s = app.getSymbol(name) { arr.append(s) }
        }
        return arr
    }
    
    
    func contains(symbolName: String) -> Bool {
        return symbols.contains(symbolName)
    }
    
    func getSymbol(_ name: String, in app: App) -> Symbol? {
        return app.getSymbol(name)
    }
    
    
}
