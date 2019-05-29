//
//  ViewController.swift
//  StripeCheckout
//
//  Created by Florian Marcu on 5/29/19.
//  Copyright © 2019 Instamobile. All rights reserved.
//

import Stripe
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let checkoutVC = self.checkoutViewController(with: 99.99)
        self.addChildViewControllerWithView(checkoutVC)
        checkoutVC.view.frame = self.view.frame
    }

    fileprivate func checkoutViewController(with price: Double) -> UIViewController {
        let theme = STPTheme()
        theme.primaryBackgroundColor = UIColor.white
        theme.secondaryBackgroundColor = UIColor.white
        theme.primaryForegroundColor = UIColor(hexString: "#333333")
        theme.secondaryForegroundColor = UIColor(hexString: "#555555")
        theme.accentColor = UIColor(hexString: "#333333")
        theme.errorColor = UIColor(red:0.87, green:0.18, blue:0.20, alpha:1.00)
        theme.font = UIFont.systemFont(ofSize: 17)
        theme.emphasisFont = UIFont.boldSystemFont(ofSize: 17)

        let stripeSettings = Settings(theme: theme,
                                      additionalPaymentOptions: .all,
                                      requiredBillingAddressFields: .none,
                                      requiredShippingAddressFields: [.emailAddress, .name, .postalAddress], // [.phoneNumber]
            shippingType: .shipping)

        let stripeVC = CheckoutViewController(price: Int(price * 100),
                                              settings: stripeSettings)
        stripeVC.delegate = self
        return stripeVC
    }
}

extension ViewController: CheckoutViewControllerDelegate {
    func checkoutViewControllerDidCompleteCheckout(_ vc: CheckoutViewController) {
    }
}
