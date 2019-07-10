//
//  Util.swift
//  Binance+
//
//  Created by Behnam Karimi on 12/22/1397 AP.
//  Copyright © 1397 AP Behnam Karimi. All rights reserved.
//

import UIKit
import Darwin


class Util {
    static func createGradientImage(color1: UIColor, color2: UIColor, width: CGFloat, height: CGFloat) -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        let ctx = UIGraphicsGetCurrentContext()
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)
        gradientLayer.colors = [color1.cgColor, color2.cgColor]
        gradientLayer.render(in: ctx!)
        
        
        let image =  UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image!
    }
    static func createGradientLayer(color1: UIColor, color2: UIColor, width: CGFloat, height: CGFloat) -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)
        gradientLayer.colors = [color1.cgColor, color2.cgColor]
        
        return gradientLayer
    }
    
    static func allSymbolsIcon(width: CGFloat, height: CGFloat) -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        let ctx = UIGraphicsGetCurrentContext()!

        let btc = UIImage(named: "btc.png")!
        let eth = UIImage(named: "eth.png")!
        let xrp = UIImage(named: "xrp.png")!
        let ltc = UIImage(named: "ltc.png")!
        
        ctx.draw(ltc.cgImage!, in: CGRect(x: 0, y: 0, width: width * 5 / 8, height: height * 5 / 8))
        ctx.draw(xrp.cgImage!, in: CGRect(x: width * 3 / 8, y: 0, width: width * 5 / 8, height: height * 5 / 8))
        ctx.draw(eth.cgImage!, in: CGRect(x: 0, y: height * 3 / 8, width: width * 5 / 8, height: height * 5 / 8))
        ctx.draw(btc.cgImage!, in: CGRect(x: width * 3 / 8, y: height * 3 / 8, width: width * 5 / 8, height: height * 5 / 8))
        
        let image =  UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    
    static func greatestPowerOfTenLess(than x: Decimal) -> Int {
        var i = 0
        var y = x
        while y > 10 {
            y /= 10
            i += 1
        }
        return i
    }
    
    static func y(price: Decimal, frameHeight: CGFloat, highestPrice: Decimal, lowestPrice: Decimal) -> CGFloat {
        let ratio = ((highestPrice - price) / (highestPrice - lowestPrice)).cgFloatValue
        return frameHeight * ratio
    }
    
}


extension Date {
    func localToUTC() -> Date {
        let seconds = TimeZone.current.secondsFromGMT()
        var offset: TimeInterval = 0
        if !NSTimeZone.local.isDaylightSavingTime(for: self) {
            offset = NSTimeZone.local.daylightSavingTimeOffset()
        }
        let i = self.timeIntervalSince1970 - TimeInterval(exactly: seconds)! + offset
        return Date(timeIntervalSince1970: i)
    }
    
    func utcToLocal() -> Date {
        let seconds = TimeZone.current.secondsFromGMT()
        var offset: TimeInterval = 0
        if !NSTimeZone.local.isDaylightSavingTime(for: self) {
            offset = NSTimeZone.local.daylightSavingTimeOffset()
        }
        let i = self.timeIntervalSince1970 + TimeInterval(exactly: seconds)! - offset
        return Date(timeIntervalSince1970: i)
    }
    
    func toMillis() -> Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

extension Decimal {
    var doubleValue: Double {
        return NSDecimalNumber(decimal:self).doubleValue
    }
    var cgFloatValue: CGFloat {
        return CGFloat(doubleValue)
    }
    var stringValue: String {
        return NSDecimalNumber(decimal: self).stringValue
    }
}

extension UIView {
    func takeScreenshot() -> UIImage? {
        // Begin context
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        
        // Draw view in that context
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        
        // And finally, get image
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}

extension UIColor {
    static func fromHex(hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    

    
    
}



extension Collection {
    
    /**
     * Returns a random element of the Array or nil if the Array is empty.
     */
    var sample : Element? {
        guard !isEmpty else { return nil }
        let offset = arc4random_uniform(numericCast(self.count))
        let idx = self.index(self.startIndex, offsetBy: numericCast(offset))
        return self[idx]
    }
    
    /**
     * Returns `count` random elements from the array.
     * If there are not enough elements in the Array, a smaller Array is returned.
     * Elements will not be returned twice except when there are duplicate elements in the original Array.
     */
    func sample(_ count : UInt) -> [Element] {
        let sampleCount = Swift.min(numericCast(count), self.count)
        
        var elements = Array(self)
        var samples : [Element] = []
        
        while samples.count < sampleCount {
            let idx = (0..<elements.count).sample!
            samples.append(elements.remove(at: idx))
        }
        
        return samples
    }
    
}

extension Array {
    
    /**
     * Shuffles the elements in the Array in-place using the
     * [Fisher-Yates shuffle](https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle).
     */
    mutating func shuffle() {
        guard self.count >= 1 else { return }
        
        for i in (1..<self.count).reversed() {
            let j = (0...i).sample!
            self.swapAt(j, i)
        }
    }
    
    /**
     * Returns a new Array with the elements in random order.
     */
    var shuffled : [Element] {
        var elements = self
        elements.shuffle()
        return elements
    }
    
}



extension UITableView {
    func setEmptyView(title: String, message: String) {
        let emptyView = UIView(frame: CGRect(x: self.center.x, y: self.center.y, width: self.bounds.size.width, height: self.bounds.size.height))
        let titleLabel = UILabel()
        let messageLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = UIColor.black
        titleLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 18)
        messageLabel.textColor = UIColor.lightGray
        messageLabel.font = UIFont(name: "HelveticaNeue-Regular", size: 17)
        emptyView.addSubview(titleLabel)
        emptyView.addSubview(messageLabel)
        titleLabel.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor).isActive = true
        messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20).isActive = true
        messageLabel.leftAnchor.constraint(equalTo: emptyView.leftAnchor, constant: 20).isActive = true
        messageLabel.rightAnchor.constraint(equalTo: emptyView.rightAnchor, constant: -20).isActive = true
        titleLabel.text = title
        messageLabel.text = message
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        // The only tricky part is here:
        self.backgroundView = emptyView
        self.separatorStyle = .none
    }
    func restore() {
        self.backgroundView = nil
        self.separatorStyle = .singleLine
    }
}
