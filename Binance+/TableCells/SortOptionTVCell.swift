//
//  SortOptionTVCell.swift
//  Binance+
//
//  Created by Behnam Karimi on 1/29/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class SortOptionTVCell: UITableViewCell {
    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    var binance: App!
    
    var sortBy: SortBy!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        
        if selected {
            if binance.sortBy == self.sortBy {
                binance.sortDirection.negate()
            } else {
                binance.sortBy = self.sortBy
            }
            if binance.sortDirection == .ASCENDING {
                rightLabel.text = "↑"
            } else {
                rightLabel.text = "↓"
            }
            
        } else {
            rightLabel.text = nil
        }
    }

}
