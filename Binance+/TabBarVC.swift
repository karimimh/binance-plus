//
//  ViewController.swift
//  Binance+
//
//  Created by Behnam Karimi on 12/21/1397 AP.
//  Copyright © 1397 AP Behnam Karimi. All rights reserved.
//

import UIKit

class TabBarVC: UITabBarController {
    var app: App!
    var parentVC: ParentVC!
    
    
    override func willMove(toParent parent: UIViewController?) {
        self.parentVC = parent as? ParentVC
        self.app = parentVC.app
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        (UIApplication.shared.delegate as? AppDelegate)?.currentTabTag = item.tag
        if item.tag == 101 {
            parentVC.slideRightPanGR.isEnabled = true
        } else {
            parentVC.slideRightPanGR.isEnabled = false
        }
    }
    
    
}

