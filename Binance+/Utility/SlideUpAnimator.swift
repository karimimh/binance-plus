//
//  SlideUpAnimator.swift
//  Binance+
//
//  Created by Behnam Karimi on 4/27/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import UIKit

// MARK: - UIViewControllerAnimatedTransitioning

class SlideUpAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var duration = 2.0
    var presenting = true
    var height: CGFloat
    var presentedCompletion: (() -> Void)
    var dismissCompletion: (() -> Void)
    
    var presentingVC: UIViewController!
    var presentingView: UIView!
    private var bgView: UIView!
    private var containerView: UIView!
    
    var bgViewTapGR: UITapGestureRecognizer?
    var bgViewPanGR: UIPanGestureRecognizer?
    var presentingVCPanGR: UIPanGestureRecognizer?
    
    var shouldPanContainer = false
    
    //MARK: - Initializtion
    
    init(duration: Double, height: CGFloat = UIScreen.main.bounds.height * 0.65, dismissCompletion: @escaping () -> Void = {} , presentedCompletion: @escaping () -> Void = {}) {
        self.duration = duration
        self.height = height
        self.dismissCompletion = dismissCompletion
        self.presentedCompletion = presentedCompletion
        
        
        super.init()
    }
    
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    // MARK: - Animation
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        containerView = transitionContext.containerView
        if presenting {
            bgView = UIView(frame: containerView.frame)
            bgView.backgroundColor = .black
            bgView.alpha = 0.0
            
            presentingView = transitionContext.view(forKey: .to)!
            
            presentingView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            presentingView.layer.cornerRadius = 10.0
            presentingView.layer.masksToBounds = true
            
            
            containerView.addSubview(bgView)
            containerView.addSubview(presentingView)
            containerView.bringSubviewToFront(bgView)
            containerView.bringSubviewToFront(presentingView)
            
            presentingVC = transitionContext.viewController(forKey: .to)
            if let vc = presentingVC as? OptionsChooserVC {
                vc.tableViewBottomConstraint.constant =  height
            }

            bgViewTapGR = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            bgViewPanGR = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            presentingVCPanGR = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            
            let transform = CGAffineTransform(translationX: 0, y: -height)
            let alpha = height / UIScreen.main.bounds.height
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4444 * 2 * .pi / CGFloat(duration), options: [.preferredFramesPerSecond60], animations: {
                self.presentingView.transform = transform
                self.bgView.alpha = alpha
            }) { (_) in
                transitionContext.completeTransition(true)
                
                self.bgView.addGestureRecognizer(self.bgViewTapGR!)
                self.bgView.addGestureRecognizer(self.bgViewPanGR!)
                if let vc = self.presentingVC as? OptionsChooserVC {
                    vc.handleView.addGestureRecognizer(self.presentingVCPanGR!)
                    vc.tableView.panGestureRecognizer.addTarget(self, action: #selector(self.handlePanTV(_:)))
                }
                self.presentingVC.view.addGestureRecognizer(self.presentingVCPanGR!)
                self.presenting = !self.presenting
                self.presentedCompletion()
            }
        } else {
            let presentingView = transitionContext.view(forKey: .from)!
            let transform = CGAffineTransform(translationX: 0, y: 0)
            let alpha: CGFloat = 0.0
            
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4444 * 2 * .pi / CGFloat(duration), options: [.preferredFramesPerSecond60], animations: {
                presentingView.transform = transform
                self.bgView.alpha = alpha
            }) { _ in
                transitionContext.completeTransition(true)
                self.bgView.removeGestureRecognizer(self.bgViewTapGR!)
                self.bgView.removeGestureRecognizer(self.bgViewPanGR!)
                if let vc = self.presentingVC as? OptionsChooserVC {
                    vc.handleView.removeGestureRecognizer(self.presentingVCPanGR!)
                    vc.tableView.panGestureRecognizer.removeTarget(self, action: #selector(self.handlePanTV(_:)))
                }
                self.bgView.removeFromSuperview()
                self.presenting = !self.presenting
                
            }

        }
        
    }
    
    
    //MARK: - Handle Touches
    
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        self.presentingVC.dismiss(animated: true) {
            self.dismissCompletion()
        }
    }
    
    
    @IBAction func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let dy = recognizer.translation(in: self.containerView).y
        switch recognizer.state {
        case .began:
            break
        case .changed:
            if dy < 0 {
                moveContainerView(by: dy / 4)
            } else {
                moveContainerView(by: dy)
            }
        case .ended:
            if dy > height / 2 {
                self.presentingVC.dismiss(animated: true) {
                    self.dismissCompletion()
                }
            } else {
                let transform = CGAffineTransform(translationX: 0, y: -height)
                let alpha = height / UIScreen.main.bounds.height
                UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: {
                    self.presentingView.transform = transform
                    self.bgView.alpha = alpha
                })
            }
        case .failed, .cancelled:
            self.presentingVC.dismiss(animated: true) {
                self.dismissCompletion()
            }
        default:
            break
        }
    }
    
    @IBAction func handlePanTV(_ recognizer: UIPanGestureRecognizer) {
        guard let vc = presentingVC as? OptionsChooserVC else {
            return
        }
        let tv = vc.tableView!
        let dy = recognizer.translation(in: self.containerView).y
        let offsetedDy = dy - tv.contentOffset.y
        let maxContentOffsetDy = tv.contentSize.height - tv.frame.height
        switch recognizer.state {
        case .began:
            if (tv.contentOffset.y == 0  && dy > 0) || (tv.contentOffset.y >= maxContentOffsetDy - tv.rowHeight && dy < 0) {
                shouldPanContainer = true
            } else {
                shouldPanContainer = false
            }
        case .changed:
            if !shouldPanContainer { return }
            if offsetedDy > 0 {
                moveContainerView(by: offsetedDy)
            } else if dy < 0 {
                moveContainerView(by: dy / 4)
            }
            
        case .ended:
            if !shouldPanContainer { return }
            if offsetedDy > height / 2 {
                self.presentingVC.dismiss(animated: true) {
                    self.dismissCompletion()
                }
            } else {
                let transform = CGAffineTransform(translationX: 0, y: -height)
                let alpha = height / UIScreen.main.bounds.height
                UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: {
                    self.presentingView.transform = transform
                    self.bgView.alpha = alpha
                })
            }
        case .failed, .cancelled:
            self.presentingVC.dismiss(animated: true) {
                self.dismissCompletion()
            }
        default:
            break
        }
    }
    
    
    
    private func moveContainerView(by y: CGFloat) {
        let transform = CGAffineTransform(translationX: 0, y: y - height)
        let alpha = (height - y) / UIScreen.main.bounds.height
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: {
            self.presentingView.transform = transform
            self.bgView.alpha = alpha
        })
    }
}
