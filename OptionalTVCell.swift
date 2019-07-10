//
//  OptionalTVCell.swift
//  Binance+
//
//  Created by Behnam Karimi on 3/27/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class OptionalTVCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button: UIButton!
    
    var parentVC: ParentVC!
    var options: [String]!
    
    var completion: ((Int) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func buttonPressed(_ sender: Any) {
        parentVC.slideUpOptionsChooser(options: options) { (index) in
            self.completion?(index)
        }
    }
    
}
