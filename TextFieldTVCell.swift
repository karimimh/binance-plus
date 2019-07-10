//
//  TextFieldTVCell.swift
//  Binance+
//
//  Created by Behnam Karimi on 3/27/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class TextFieldTVCell: UITableViewCell, UITextFieldDelegate  {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var textField: UITextField!
    
    var newTextCompletion: ((String) -> Void)?
    var textFieldStartedEditing: (() -> Void)?
    var textFieldResignedCompletion : (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        textField.delegate = self
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textFieldStartedEditing?()
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if let t = textField.text, !t.isEmpty {
            newTextCompletion?(t)
        }
        textFieldResignedCompletion?()
        return true
    }
}
