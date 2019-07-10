//
//  Enums.swift
//  Binance+
//
//  Created by Behnam Karimi on 12/22/1397 AP.
//  Copyright © 1397 AP Behnam Karimi. All rights reserved.
//

import Foundation

enum Timeframe: String {
    case oneMinute = "1m"
    case threeMinutes = "3m"
    case fiveMinutes = "5m"
    case fifteenMinutes = "15m"
    case thirtyMinutes = "30m"
    case hourly = "1h"
    case twoHourly = "2h"
    case fourHourly = "4h"
    case sixHourly = "6h"
    case eightHourly = "8h"
    case twelveHourly = "12h"
    case daily = "1d"
    case threeDaily = "3d"
    case weekly = "1w"
    case monthly = "1M"
    
    
    static func allValues() -> [String] {
        return ["1m", "3m", "5m", "15m", "30m", "1h", "2h", "4h", "6h", "8h", "12h", "1d", "3d", "1w", "1M"]
    }
    
    func toMinutes() -> Int {
        switch self {
        case .oneMinute:
            return 1
        case .threeMinutes:
            return 3
        case .fiveMinutes:
            return 5
        case .fifteenMinutes:
            return 15
        case .thirtyMinutes:
            return 30
        case .hourly:
            return 60
        case .twoHourly:
            return 120
        case .fourHourly:
            return 240
        case .sixHourly:
            return 360
        case .eightHourly:
            return 480
        case .twelveHourly:
            return 720
        case .daily:
            return 1440
        case .threeDaily:
            return 4320
        case .weekly:
            return 10080
        case .monthly:
            return 43200 // 30 day month
        }
    }
}



enum SymbolStatus: String {
    case PRE_TRADING
    case TRADING
    case POST_TRADING
    case END_OF_DAY
    case HALT
    case AUCTION_MATCH
    case BREAK
}


enum SymbolType: String {
    case SPOT
}

enum OrderStatus: String {
    case NEW
    case PARTIALLY_FILLED
    case FILLED
    case CANCELED
    case PENDING_CANCEL
    case REJECTED
    case EXPIRED

}

enum OrderType: String {
    case LIMIT
    case MARKET
    case STOP_LOSS
    case STOP_LOSS_LIMIT
    case TAKE_PROFIT
    case TAKE_PROFIT_LIMIT
    case LIMIT_MAKER
}


enum OrderSide: String {
    case BUY
    case SELL
}


enum TimeInForce: String {
    case GTC
    case IOC
    case FOK
}
