//
//  ParentVC.swift
//  Binance+
//
//  Created by Behnam Karimi on 2/2/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

class ParentVC: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet weak var dimView: UIView!
    @IBOutlet weak var mainContainer: UIView!
    @IBOutlet weak var leftContainer: UIView!
    @IBOutlet weak var bottomContainer: UIView!
    @IBOutlet weak var rightContainer: UIView!
    @IBOutlet weak var mainContainerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomContainerTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftContainerTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightContainerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftContainerWidthConstraint: NSLayoutConstraint!
    
    var mainContainerVC: UIViewController!
    var leftContainerVC: UIViewController!
    var bottomContainerVC: UIViewController!
    var rightContainerVC: UIViewController!
    
    var bottomContainerBestHeight: CGFloat = 0
    var leftContainerBestWidth: CGFloat {
        get {
            return leftContainerWidthConstraint.multiplier * UIScreen.main.bounds.width
        }
    }
    var rightContainerBestWidth: CGFloat = UIScreen.main.bounds.width * 0.25
    
    var app: App!


    var slideUpPanGR: UIPanGestureRecognizer!
    var slideUpTapGR: UITapGestureRecognizer!
    
    
    var slideRightPanGR: UIPanGestureRecognizer!
    var slideRightPanGR2: UIPanGestureRecognizer!
    var slideRightTapGR: UITapGestureRecognizer!
    var panBeganLeftContainerX: CGFloat = -UIScreen.main.bounds.width * 0.75
    
    var slideLeftPanGR: UIPanGestureRecognizer!
    var slideLeftTapGR: UITapGestureRecognizer!
    var panBeganRightContainerX: CGFloat = UIScreen.main.bounds.width
    
    
    var slidingDisabled: Bool = false
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for child in children {
            if let vc = child as? TabBarVC {
                mainContainerVC = vc
                break
            }
        }
        bottomContainer.layer.borderWidth = 0.5
        bottomContainer.layer.borderColor = UIColor.blue.cgColor
        bottomContainer.layer.cornerRadius = 14
        bottomContainer.layer.masksToBounds = true
    }
    

    //MARK: - SlideUp Chooser List
    
    func slideUpOptionsChooser(options: [String], title: String? = nil, completion: @escaping ((Int) -> Void)) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "OptionsChooserVC") as! OptionsChooserVC
        vc.options = options
        vc.parentVC = self
        vc.completion = completion
        setAsBottomContainerVC(vc)
        var tableHeight = vc.tableView.tableFooterView!.frame.minY
        if tableHeight > UIScreen.main.bounds.height * 0.65 {
            tableHeight = UIScreen.main.bounds.height * 0.65
        }
        let h = tableHeight + vc.tableView.frame.minY
        vc.tableViewBottomConstraint.constant = bottomContainer.bounds.height - h
        
        if let t = title {
            vc.navItem.title = t
        }
        
        slideUp(height: tableHeight + vc.tableView.frame.minY) { (panGR2, panGR3) in
            vc.handleView.addGestureRecognizer(panGR2)
            vc.navBar.addGestureRecognizer(panGR3)
        }
    }
    
    
    
    
    // MARK: - SlideUp VC
    
    func setAsBottomContainerVC(_ vc: UIViewController) {
        bottomContainerVC = vc
        
        addChild(bottomContainerVC)
        bottomContainer.addSubview(bottomContainerVC.view)
        bottomContainerVC.didMove(toParent: self)
    }
    
    func slideUp(height: CGFloat, completion: @escaping (UIPanGestureRecognizer, UIPanGestureRecognizer) -> Void = {(_, _) in }) {
        app.busyShowingSTH = true
        mainContainerVC.view.isUserInteractionEnabled = false
        
        bottomContainerBestHeight = height
        bottomContainerTopConstraint.constant = -height
        
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseIn, animations: {
            let alpha = height / UIScreen.main.bounds.height
            self.dimView.backgroundColor = UIColor.clear.withAlphaComponent(alpha)
            self.view.layoutIfNeeded()
        }) { (b) in
            if self.slideUpTapGR == nil {
                self.slideUpTapGR = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
                self.mainContainer.addGestureRecognizer(self.slideUpTapGR)
            }
            if self.slideUpPanGR == nil {
                self.slideUpPanGR = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
                self.mainContainer.addGestureRecognizer(self.slideUpPanGR)
            }
            self.slideUpTapGR.isEnabled = true
            self.slideUpPanGR.isEnabled = true
            
            let panGR2 = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
            let panGR3 = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
            completion(panGR2, panGR3)
            
        }
    }
    
    func slideDown(completion: @escaping () -> Void = {}) {
        slideUpPanGR.isEnabled = false
        slideUpTapGR.isEnabled = false
        app.busyShowingSTH = false
        
        bottomContainerTopConstraint.constant = 0
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            self.dimView.backgroundColor = UIColor.clear
        }) { (b) in
            self.mainContainerVC.view.isUserInteractionEnabled = true
            self.bottomContainerVC.removeFromParent()
            
            completion()
        }

    }
    
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        slideDown()
    }
    
    
    @IBAction func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let dy = recognizer.translation(in: self.view).y
        switch recognizer.state {
        case .began:
            break
        case .changed:
            moveContainerView(to: bottomContainerBestHeight - dy)
        case .ended:
            if dy > bottomContainerBestHeight / 2 {
                slideDown()
            } else {
                slideBackUp()
            }
        case .failed, .cancelled:
            slideDown()
        default:
            break
        }
    }
    
    private func moveContainerView(to y: CGFloat) {
        self.bottomContainerTopConstraint.constant = -y
        let alpha = y / UIScreen.main.bounds.height
        self.dimView.backgroundColor = UIColor.clear.withAlphaComponent(alpha)
        self.view.layoutIfNeeded()
    }
    
    private func slideBackUp() {
        app.busyShowingSTH = true
        self.bottomContainerTopConstraint.constant = -self.bottomContainerBestHeight
        UIView.animate(withDuration: 0.15, delay: 0, options: .transitionCurlUp, animations: {
            let alpha = self.bottomContainerBestHeight / UIScreen.main.bounds.height
            self.dimView.backgroundColor = UIColor.clear.withAlphaComponent(alpha)
            self.view.layoutIfNeeded()
        }) { (_) in
            self.slideUpTapGR.isEnabled = true
            self.slideUpPanGR.isEnabled = true
        }
    }
    
    
    
    
    
    
    
    
    
    //MARK: - SlideRight VC
    func disableSliding() {
        if slidingDisabled { return }
        slideRightPanGR.isEnabled = false
        slideRightPanGR2.isEnabled = false
        slideRightTapGR.isEnabled = false
        self.slidingDisabled = true
    }
    func enableSliding() {
        if !slidingDisabled { return }
        slideRightPanGR.isEnabled = true
        slideRightPanGR2.isEnabled = true
        slideRightTapGR.isEnabled = true
        
        self.slidingDisabled = false
    }
    
    
    
    func setupLeftContainerGestureRecognizers() {
        slideRightPanGR = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan2(_:)))
        mainContainer.addGestureRecognizer(slideRightPanGR)
        slideRightTapGR = UITapGestureRecognizer(target: self, action: #selector(self.handleTap2(_:)))
        mainContainer.addGestureRecognizer(slideRightTapGR)
        slideRightTapGR.isEnabled = false
        slideRightPanGR2 = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan2(_:)))
        leftContainer.addGestureRecognizer(slideRightPanGR2)

        slideRightPanGR2.cancelsTouchesInView = false
    }
    
    func slideRight(completion: @escaping (UIPanGestureRecognizer, UIPanGestureRecognizer) -> Void = {(_, _) in }) {
        mainContainerVC.view.isUserInteractionEnabled = false
        leftContainerTrailingConstraint.constant = -leftContainerBestWidth
        mainContainerLeadingConstraint.constant = leftContainerBestWidth
        UIView.animate(withDuration: 0.2, delay: 0, options: .transitionCurlUp, animations: {
            let alpha = 0.25 * self.leftContainerBestWidth / UIScreen.main.bounds.width
            self.dimView.backgroundColor = UIColor.clear.withAlphaComponent(alpha)
            
            self.view.layoutIfNeeded()
        }) { (b) in
            self.slideRightTapGR.isEnabled = true
            
            let panGR2 = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan2(_:)))
            let panGR3 = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan2(_:)))
            completion(panGR2, panGR3)
        }
    }
    
    @IBAction func handleTap2(_ sender: UITapGestureRecognizer) {
        slideLeft()
    }
    
    
    @IBAction func handlePan2(_ recognizer: UIPanGestureRecognizer) {
        let dx = recognizer.translation(in: self.view).x
        
        switch recognizer.state {
        case .began:
            panBeganLeftContainerX = leftContainer.frame.origin.x
        case .changed:
            if panBeganLeftContainerX + dx < 0 && panBeganLeftContainerX + dx > -leftContainerBestWidth {
                moveContainerView(by: panBeganLeftContainerX + leftContainerBestWidth + dx)
            }
        case .ended:
            if dx < -leftContainerBestWidth / 5 && panBeganLeftContainerX >= 0 {
                slideLeft { }
            } else if dx > leftContainerBestWidth / 5 && panBeganLeftContainerX < 0 {
                slideBackRight()
            } else if dx > 0 && dx < leftContainerBestWidth / 5 && panBeganLeftContainerX < 0 {
                slideLeft { }
            } else if dx < 0 && dx > -leftContainerBestWidth / 5 && panBeganLeftContainerX >= 0 {
                slideBackRight()
            }
        case .failed, .cancelled:
            slideLeft { }
        default:
            break
        }
    }
    
    func slideLeft(completion: @escaping () -> Void = {}) {
        slideRightTapGR.isEnabled = false
        
        leftContainerTrailingConstraint.constant = 0
        mainContainerLeadingConstraint.constant = 0
        UIView.animate(withDuration: 0.2, delay: 0, options: .transitionCurlUp, animations: {
            self.view.layoutIfNeeded()
            let alpha: CGFloat = 0.0
            self.dimView.backgroundColor = UIColor.clear.withAlphaComponent(alpha)

        }) { (_) in
            self.mainContainerVC.view.isUserInteractionEnabled = true
            completion()
        }

    }
    
    private func moveContainerView(by dx: CGFloat) {
        leftContainerTrailingConstraint.constant = -dx
        mainContainerLeadingConstraint.constant = dx
        
        let alpha = 0.25 * mainContainerLeadingConstraint.constant / UIScreen.main.bounds.width
        self.dimView.backgroundColor = UIColor.clear.withAlphaComponent(alpha)

        self.view.layoutIfNeeded()
    }
    
    private func slideBackRight() {
        mainContainerVC.view.isUserInteractionEnabled = false
        leftContainerTrailingConstraint.constant = -leftContainerBestWidth
        mainContainerLeadingConstraint.constant = leftContainerBestWidth
        UIView.animate(withDuration: 0.2, delay: 0, options: .transitionCurlUp, animations: {
            let alpha = 0.25 * self.leftContainerBestWidth / UIScreen.main.bounds.width
            self.dimView.backgroundColor = UIColor.clear.withAlphaComponent(alpha)
            
            self.view.layoutIfNeeded()
        }) { (_) in
            self.slideRightTapGR.isEnabled = true
        }
    }
    
    

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let chooseListVC as ChooseListVC:
            self.leftContainerVC = chooseListVC
        default:
            break
        }
    }
    
    
}
