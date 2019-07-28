
//
//  TimeframeSelectorVC.swift
//  Binance+
//
//  Created by Behnam Karimi on 5/2/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class SlideupSelectorVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource  {
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewBottomConstraint: NSLayoutConstraint!
    
    var navItem: UINavigationItem!
    
    var options = [String]()
    var completion: ((Int) -> Void)?
    var shouldDismissOnSelect = true
    
    var cellWidth: CGFloat = 50
    var cellHeight: CGFloat = 50
    var spacingX: CGFloat = 10
    var spacingY: CGFloat = 10

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navBar.shadowImage = UIColor.fromHex(hex: "#D6D6D6").as1ptImage()
        navBar.setBackgroundImage(UIColor.white.as1ptImage(), for: .default)
        
        
        navItem = UINavigationItem(title: "")
        navItem.leftBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)
        navItem.leftBarButtonItem?.tintColor = UIColor.purple
        navItem.leftBarButtonItem?.isEnabled = false
        navItem.leftBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .bold), NSAttributedString.Key.foregroundColor: UIColor.purple], for: .disabled)
        navItem.leftBarButtonItem?.setTitlePositionAdjustment(UIOffset(horizontal: -7.5, vertical: -10), for: .default)
        navBar.items = [navItem]
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return options.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SimpleCVCell", for: indexPath) as! SimpleCVCell
        cell.label.text = options[indexPath.row]
        cell.label.layer.cornerRadius = 4
        cell.label.layer.borderColor = UIColor.purple.cgColor
        cell.label.layer.borderWidth = 1.0
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if shouldDismissOnSelect {
            self.dismiss(animated: true) {
                self.completion?(indexPath.row)
            }
        } else {
            completion?(indexPath.row)
        }
    }
    
    
}


// MARK: - Collection View Flow Layout Delegate
extension SlideupSelectorVC : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
}
