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
        self.addChild(checkoutVC)
        checkoutVC.view.frame = self.view.frame
    }

    fileprivate func checkoutViewController(with price: Double) -> UIViewController {
        let stripeSettings = Settings(theme: ATCStripeThemeFactory().stripeTheme(for: uiConfig),
                                      additionalPaymentOptions: .all,
                                      requiredBillingAddressFields: .none,
                                      requiredShippingAddressFields: [.emailAddress, .name, .postalAddress], // [.phoneNumber]
            shippingType: .shipping)

        let stripeVC = CheckoutViewController(uiConfig: uiConfig,
                                              price: Int(price * 100),
                                              settings: stripeSettings)
        stripeVC.delegate = self
        self.navigationController?.pushViewController(stripeVC, animated: true)
    }
}

