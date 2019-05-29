//
//  CheckoutViewController.swift
//  Standard Integration (Swift)
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import UIKit
import Stripe

protocol CheckoutViewControllerDelegate: class {
    func checkoutViewControllerDidCompleteCheckout(_ vc: CheckoutViewController)
}

class CheckoutViewController: UIViewController, STPPaymentContextDelegate {

    // 1) To get started with this demo, first head to https://dashboard.stripe.com/account/apikeys
    // and copy your "Test Publishable Key" (it looks like pk_test_abcdef) into the line below.
    let stripePublishableKey = "pk_test_mHeSRjRFtORVXYQeFZty7pZD"

    // 2) Next, optionally, to have this demo save your user's payment details, head to
    // https://github.com/stripe/example-ios-backend/tree/v14.0.0, click "Deploy to Heroku", and follow
    // the instructions (don't worry, it's free). Replace nil on the line below with your
    // Heroku URL (it looks like https://blazing-sunrise-1234.herokuapp.com ).
    let backendBaseURL: String? = "https://apptemplatesios.herokuapp.com"

    // 3) Optionally, to enable Apple Pay, follow the instructions at https://stripe.com/docs/mobile/apple-pay
    // to create an Apple Merchant ID. Replace nil on the line below with it (it looks like merchant.com.yourappname).
    let appleMerchantID: String? = "merchant.com.iosapptemplates"

    // These values will be shown to the user when they purchase with Apple Pay.
    let companyName = "Shopertino"
    let paymentCurrency = "usd"

    let paymentContext: STPPaymentContext

    let theme: STPTheme
    let paymentRow: CheckoutRowView
    let shippingRow: CheckoutRowView
    let totalRow: CheckoutRowView
    let buyButton: UIButton
    let titleLabel: UILabel
    let rowHeight: CGFloat = 44
    let activityIndicator = UIActivityIndicatorView(style: .gray)
    let numberFormatter: NumberFormatter
    let shippingString: String
    var paymentInProgress: Bool = false {
        didSet {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
                if self.paymentInProgress {
                    self.activityIndicator.startAnimating()
                    self.activityIndicator.alpha = 1
                    self.buyButton.alpha = 0
                }
                else {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.alpha = 0
                    self.buyButton.alpha = 1
                }
                }, completion: nil)
        }
    }

    private var redirectContext: STPRedirectContext?

    weak var delegate: CheckoutViewControllerDelegate?

    init(price: Int,
         settings: Settings) {

        let stripePublishableKey = self.stripePublishableKey
        let backendBaseURL = self.backendBaseURL

        assert(stripePublishableKey.hasPrefix("pk_"), "You must set your Stripe publishable key at the top of CheckoutViewController.swift to run this app.")
        assert(backendBaseURL != nil, "You must set your backend base url at the top of CheckoutViewController.swift to run this app.")

        self.theme = settings.theme
        MyAPIClient.sharedClient.baseURLString = self.backendBaseURL

        // This code is included here for the sake of readability, but in your application you should set up your configuration and theme earlier, preferably in your App Delegate.
        let config = STPPaymentConfiguration.shared()
        config.publishableKey = self.stripePublishableKey
        config.appleMerchantIdentifier = self.appleMerchantID
        config.companyName = self.companyName
        config.requiredBillingAddressFields = settings.requiredBillingAddressFields
        config.requiredShippingAddressFields = settings.requiredShippingAddressFields
        config.shippingType = settings.shippingType
        config.additionalPaymentOptions = settings.additionalPaymentOptions

        // Create card sources instead of card tokens
        config.createCardSources = true;

        let customerContext = STPCustomerContext(keyProvider: MyAPIClient.sharedClient)
        let paymentContext = STPPaymentContext(customerContext: customerContext,
                                               configuration: config,
                                               theme: settings.theme)
        let userInformation = STPUserInformation()
        paymentContext.prefilledInformation = userInformation
        paymentContext.paymentAmount = price
        paymentContext.paymentCurrency = self.paymentCurrency

//        let paymentSelectionFooter = PaymentContextFooterView(text: "You can add custom footer views to the payment selection screen.")
//        paymentSelectionFooter.theme = settings.theme
//        paymentContext.paymentOptionsViewControllerFooterView = paymentSelectionFooter
//
//        let addCardFooter = PaymentContextFooterView(text: "You can add custom footer views to the add card screen.")
//        addCardFooter.theme = settings.theme
//        paymentContext.addCardViewControllerFooterView = addCardFooter

        self.paymentContext = paymentContext

        self.paymentRow = CheckoutRowView(title: "Payment", detail: "Select Payment",
                                          theme: settings.theme)
        var shippingString = "Contact"
        if config.requiredShippingAddressFields?.contains(.postalAddress) ?? false {
            shippingString = config.shippingType == .shipping ? "Shipping" : "Delivery"
        }
        self.shippingString = shippingString
        self.shippingRow = CheckoutRowView(title: self.shippingString,
                                           detail: "Enter \(self.shippingString) Info",
                                           theme: settings.theme)
        self.totalRow = CheckoutRowView(title: "Total", detail: "", tappable: false,
                                        theme: settings.theme)
        self.buyButton = UIButton(type: .system)
        buyButton.configure(color: .white,
                            font: theme.emphasisFont,
                            cornerRadius: 5,
                            borderColor: nil,
                            backgroundColor: theme.primaryForegroundColor)
        buyButton.setTitle("PLACE ORDER", for: .normal)

        self.titleLabel = UILabel(frame: .zero)

        var localeComponents: [String: String] = [
            NSLocale.Key.currencyCode.rawValue: self.paymentCurrency,
        ]
        localeComponents[NSLocale.Key.languageCode.rawValue] = NSLocale.preferredLanguages.first
        let localeID = NSLocale.localeIdentifier(fromComponents: localeComponents)
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale(identifier: localeID)
        numberFormatter.numberStyle = .currency
        numberFormatter.usesGroupingSeparator = true
        self.numberFormatter = numberFormatter
        super.init(nibName: nil, bundle: nil)
        self.paymentContext.delegate = self
        paymentContext.hostViewController = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hexString: "#fafafa")

        var red: CGFloat = 0
        self.theme.primaryBackgroundColor.getRed(&red, green: nil, blue: nil, alpha: nil)
        self.activityIndicator.style = red < 0.5 ? .white : .gray
        self.view.addSubview(self.titleLabel)
        self.view.addSubview(self.totalRow)
        self.view.addSubview(self.paymentRow)
        self.view.addSubview(self.shippingRow)
        self.view.addSubview(self.buyButton)
        self.view.addSubview(self.activityIndicator)

        self.titleLabel.text = "Check out"
        self.titleLabel.font = UIFont.boldSystemFont(ofSize: 34)
        self.titleLabel.textColor = theme.secondaryForegroundColor

        self.activityIndicator.alpha = 0
        self.buyButton.addTarget(self, action: #selector(didTapBuy), for: .touchUpInside)
        self.totalRow.detail = self.numberFormatter.string(from: NSNumber(value: Float(self.paymentContext.paymentAmount)/100))!
        self.paymentRow.onTap = { [weak self] in
            self?.paymentContext.presentPaymentOptionsViewController()
        }
        self.shippingRow.onTap = { [weak self]  in
            self?.paymentContext.presentShippingViewController()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var insets = UIEdgeInsets.zero
        if #available(iOS 11.0, *) {
            insets = view.safeAreaInsets
        }
        let width = self.view.bounds.width - (insets.left + insets.right)
        let height = self.view.bounds.height - (insets.top + insets.bottom)

        self.titleLabel.frame = CGRect(x: insets.left + 15, y: insets.top + 20, width: width, height: 40)
        self.paymentRow.frame = CGRect(x: insets.left, y: self.titleLabel.frame.maxY + rowHeight + 10,
                                       width: width, height: rowHeight)
        self.shippingRow.frame = CGRect(x: insets.left, y: self.paymentRow.frame.maxY,
                                        width: width, height: rowHeight)
        self.totalRow.frame = CGRect(x: insets.left, y: self.shippingRow.frame.maxY,
                                     width: width, height: rowHeight)
        self.buyButton.frame = CGRect(x: insets.left, y: height, width: width - 20, height: 50)
        self.buyButton.center = CGPoint(x: width / 2.0, y: self.buyButton.center.y)
        self.activityIndicator.center = self.buyButton.center
    }

    @objc func didTapBuy() {
        self.paymentInProgress = true
        self.paymentContext.requestPayment()
    }

    private func performAction(for paymentIntent: STPPaymentIntent, completion: @escaping STPErrorBlock) {
        if self.redirectContext != nil {
            completion(NSError(domain: StripeDomain, code: 123, userInfo: [NSLocalizedDescriptionKey: "Should not have multiple concurrent redirects."]))
            return
        }

        if let redirectContext = STPRedirectContext(paymentIntent: paymentIntent, completion: { [weak self] (clientSecret, error) in
            self?.redirectContext = nil
            if error != nil {
                completion(error)
            } else {
                STPAPIClient.shared().retrievePaymentIntent(withClientSecret: clientSecret, completion: { (retrievedIntent, retrieveError) in
                    if retrieveError != nil {
                        completion(retrieveError)
                    } else {
                        if let retrievedIntent = retrievedIntent {
                            MyAPIClient.sharedClient.confirmPaymentIntent(retrievedIntent
                                , completion: { (confirmedIntent, confirmError) in
                                    if confirmError != nil {
                                        completion(confirmError)
                                    } else {
                                        if let confirmedIntent: STPPaymentIntent = confirmedIntent {
                                            if confirmedIntent.status == .requiresAction {
                                                self?.performAction(for: confirmedIntent, completion: completion)
                                            } else {
                                                // success
                                                completion(nil)
                                            }
                                        } else {
                                            completion(NSError(domain: StripeDomain, code: 123, userInfo: [NSLocalizedDescriptionKey: "Error parsing confirmed payment intent"]))
                                        }
                                    }
                            })
                        } else {
                             completion(NSError(domain: StripeDomain, code: 123, userInfo: [NSLocalizedDescriptionKey: "Error retrieving payment intent"]))
                        }
                    }
                })
            }
            }) {
            self.redirectContext = redirectContext
            redirectContext.startRedirectFlow(from: self)
        } else {
            completion(NSError(domain: StripeDomain, code: 123, userInfo: [NSLocalizedDescriptionKey: "Unable to create redirect context for payment intent."]))
        }
    }

    // MARK: STPPaymentContextDelegate

    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPErrorBlock) {
        MyAPIClient.sharedClient.createAndConfirmPaymentIntent(paymentResult,
                                                               amount: self.paymentContext.paymentAmount,
                                                               returnURL: "payments-example://stripe-redirect",
                                                               shippingAddress: self.paymentContext.shippingAddress,
                                                               shippingMethod: self.paymentContext.selectedShippingMethod) { (paymentIntent, error) in
                                                                if error != nil {
                                                                    completion(error)
                                                                } else {
                                                                    if let paymentIntent = paymentIntent {
                                                                        if paymentIntent.status == .requiresAction {
                                                                            self.performAction(for: paymentIntent, completion: completion)
                                                                        } else {
                                                                            // successful
                                                                            completion(nil)
                                                                        }
                                                                    } else {
                                                                        let err = NSError(domain: StripeDomain, code: 123, userInfo: [NSLocalizedDescriptionKey: "Unable to parse payment intent from response"])
                                                                        completion(err)
                                                                    }
                                                                }
        }
    }

    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        self.paymentInProgress = false
        let title: String
        let message: String
        switch status {
        case .error:
            title = "Error"
            message = error?.localizedDescription ?? ""
        case .success:
            title = "Success"
            message = "Congratulations! Your order has been placed successfully."
            self.delegate?.checkoutViewControllerDidCompleteCheckout(self)
        case .userCancellation:
            return
        }
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { (action) in
            if status == .success {
                self.navigationController?.popViewController(animated: true)
            }
        }
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }

    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        self.paymentRow.loading = paymentContext.loading
        if let paymentOption = paymentContext.selectedPaymentOption {
            self.paymentRow.detail = paymentOption.label
        }
        else {
            self.paymentRow.detail = "Select Payment"
        }
        if let shippingMethod = paymentContext.selectedShippingMethod {
            self.shippingRow.detail = shippingMethod.label
        }
        else {
            self.shippingRow.detail = "Enter \(self.shippingString) Info"
        }
        self.totalRow.detail = self.numberFormatter.string(from: NSNumber(value: Float(self.paymentContext.paymentAmount)/100))!
    }

    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        let alertController = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            // Need to assign to _ because optional binding loses @discardableResult value
            // https://bugs.swift.org/browse/SR-1681
            _ = self.navigationController?.popViewController(animated: true)
        })
        let retry = UIAlertAction(title: "Retry", style: .default, handler: { action in
            self.paymentContext.retryLoading()
        })
        alertController.addAction(cancel)
        alertController.addAction(retry)
        self.present(alertController, animated: true, completion: nil)
    }

    // Note: this delegate method is optional. If you do not need to collect a
    // shipping method from your user, you should not implement this method.
    func paymentContext(_ paymentContext: STPPaymentContext, didUpdateShippingAddress address: STPAddress, completion: @escaping STPShippingMethodsCompletionBlock) {
        let upsGround = PKShippingMethod()
        upsGround.amount = 0
        upsGround.label = "UPS Ground"
        upsGround.detail = "Arrives in 3-5 days"
        upsGround.identifier = "ups_ground"
        let upsWorldwide = PKShippingMethod()
        upsWorldwide.amount = 10.99
        upsWorldwide.label = "UPS Worldwide Express"
        upsWorldwide.detail = "Arrives in 1-3 days"
        upsWorldwide.identifier = "ups_worldwide"
        let fedEx = PKShippingMethod()
        fedEx.amount = 5.99
        fedEx.label = "FedEx"
        fedEx.detail = "Arrives tomorrow"
        fedEx.identifier = "fedex"

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if address.country == nil || address.country == "US" {
                completion(.valid, nil, [upsGround, fedEx], fedEx)
            }
            else if address.country == "AQ" {
                let error = NSError(domain: "ShippingError", code: 123, userInfo: [NSLocalizedDescriptionKey: "Invalid Shipping Address",
                                                                                   NSLocalizedFailureReasonErrorKey: "We can't ship to this country."])
                completion(.invalid, error, nil, nil)
            }
            else {
                fedEx.amount = 20.99
                completion(.valid, nil, [upsWorldwide, fedEx], fedEx)
            }
        }
    }

}
