//
//  PickSymbolTVCell.swift
//  Binance+
//
//  Created by Behnam Karimi on 2/21/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class PickSymbolTVCell: UITableViewCell {
    @IBOutlet weak var iconIV: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        iconIV.image = UIImage()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
