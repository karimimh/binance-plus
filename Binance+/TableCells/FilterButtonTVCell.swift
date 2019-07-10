//
//  FilterButtonTVCell.swift
//  Binance+
//
//  Created by Behnam Karimi on 4/13/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class FilterButtonTVCell: UITableViewCell {
    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var rightButton: UIButton!
    
    var buttonPressedAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func rightButtonPressed(_ sender: Any) {
        buttonPressedAction?()
    }
    
}
