//
//  ListTitleView.swift
//  Binance+
//
//  Created by Behnam Karimi on 1/29/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class ListTitleView: UIView {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    
    class func instantiateFromNib() -> ListTitleView {
        let nib = UINib(nibName: "ListTitleView", bundle: nil)
        let nibObjects = nib.instantiate(withOwner: nil, options: nil)
        let listTitleView = nibObjects.first as! ListTitleView
        return listTitleView
    }
    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
