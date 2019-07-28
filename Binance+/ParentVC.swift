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
    @IBOutlet weak var mainContainerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftContainerTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftContainerWidthConstraint: NSLayoutConstraint!
    
    var transition = SlideUpAnimator(duration: 0.2)
    
    var mainContainerVC: UIViewController!
    var leftContainerVC: UIViewController!
    var bottomContainerVC: UIViewController!
    
    var leftContainerBestWidth: CGFloat {
        get {
            return leftContainerWidthConstraint.multiplier * UIScreen.main.bounds.width
        }
    }
    
    var app: App!


    
    var slideRightPanGR: UIPanGestureRecognizer!
    var slideRightPanGR2: UIPanGestureRecognizer!
    var slideRightTapGR: UITapGestureRecognizer!
    var panBeganLeftContainerX: CGFloat = -UIScreen.main.bounds.width * 0.75
    
    
    
    var slidingDisabled: Bool = false
    
    
    var optionsChooserTitle = "Select Option"
    var optionsChooserOptions = [String]()
    var optionsChooserCompletion: ((Int) -> Void)?
    var optionsChooserShouldDismissOnSelection = true
    
    
    var slideupSelectorTitle = "Select Option"
    var slideupSelectorOptions = [String]()
    var slideupSelectorCompletion: ((Int) -> Void)?
    var slideupSelectorShouldDismissOnSelection = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for child in children {
            if let vc = child as? TabBarVC {
                mainContainerVC = vc
                break
            }
        }
    }
    

    //MARK: - SlideUp Chooser List
    
    func slideUpOptionsChooser(options: [String], title: String? = nil, shouldDismissOnSelection: Bool = true, completion: @escaping ((Int) -> Void)) {
        optionsChooserTitle = title ?? "SelectOption"
        optionsChooserShouldDismissOnSelection = shouldDismissOnSelection
        optionsChooserOptions = options
        optionsChooserCompletion = completion
        performSegue(withIdentifier: "ShowOptionsSegue", sender: self)
    }
    
    func slideUpSelector(options: [String], title: String? = nil, shouldDismissOnSelection: Bool = true, completion: @escaping ((Int) -> Void)) {
        slideupSelectorTitle = title ?? "SelectOption"
        slideupSelectorShouldDismissOnSelection = shouldDismissOnSelection
        slideupSelectorOptions = options
        slideupSelectorCompletion = completion
        performSegue(withIdentifier: "ShowSlideupSelectorSegue", sender: self)
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
    
    
    //MARK: - Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let chooseListVC as ChooseListVC:
            self.leftContainerVC = chooseListVC
        case let vc as OptionsChooserVC:
            bottomContainerVC = vc
            vc.title = optionsChooserTitle
            vc.shouldDismissOnSelect = optionsChooserShouldDismissOnSelection
            vc.options = optionsChooserOptions
            vc.completion = optionsChooserCompletion
            vc.transitioningDelegate = self
        case let vc as SlideupSelectorVC:
            bottomContainerVC = vc
            vc.title = slideupSelectorTitle
            vc.shouldDismissOnSelect = slideupSelectorShouldDismissOnSelection
            vc.options = slideupSelectorOptions
            vc.completion = slideupSelectorCompletion
            vc.transitioningDelegate = self
        default:
            break
        }
    }
    
}





extension ParentVC: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition = SlideUpAnimator(duration: 0.2)
        
        switch bottomContainerVC {
        case _ as OptionsChooserVC:
            var h = CGFloat(88 + 44 * optionsChooserOptions.count)
            if h > UIScreen.main.bounds.height * 0.65 { h = UIScreen.main.bounds.height * 0.65 }
            transition.height = h
        case let vc as SlideupSelectorVC:
            let n = Int(UIScreen.main.bounds.width / (vc.cellWidth + vc.spacingX)) - 1
            let rows = (slideupSelectorOptions.count / n) + 1
            var h = CGFloat(rows) * (vc.spacingY + vc.cellHeight)
            if h > UIScreen.main.bounds.height * 0.65 { h = UIScreen.main.bounds.height * 0.65 }
            transition.height = h
        default:
            break
        }
        return transition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transition
    }
}
