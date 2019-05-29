//
//  UIViewController.swift
//  StripeCheckout
//
//  Created by Florian Marcu on 5/29/19.
//  Copyright © 2019 Instamobile. All rights reserved.
//

import UIKit

extension UIViewController {
    func addChildViewControllerWithView(_ childViewController: UIViewController, toView view: UIView? = nil) {
        let view: UIView = view ?? self.view

        childViewController.removeFromParent()
        childViewController.willMove(toParent: self)
        addChild(childViewController)
        view.addSubview(childViewController.view)
        childViewController.didMove(toParent: self)
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
}
