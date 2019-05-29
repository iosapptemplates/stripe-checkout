//
//  ATCStripeThemeFactory.swift
//  Shopertino
//
//  Created by Florian Marcu on 5/22/19.
//  Copyright © 2019 Instamobile. All rights reserved.
//

import Stripe
import UIKit

class ATCStripeThemeFactory {

    func stripeTheme(for uiConfig: ATCUIGenericConfigurationProtocol) -> STPTheme {
        let theme = STPTheme()
        theme.primaryBackgroundColor = uiConfig.mainThemeBackgroundColor
        theme.secondaryBackgroundColor = uiConfig.mainThemeBackgroundColor
        theme.primaryForegroundColor = uiConfig.mainThemeForegroundColor
        theme.secondaryForegroundColor = uiConfig.mainTextColor
        theme.accentColor = uiConfig.mainThemeForegroundColor
        theme.errorColor = UIColor(red:0.87, green:0.18, blue:0.20, alpha:1.00)
        theme.font = uiConfig.regularFont(size: 17)
        theme.emphasisFont = uiConfig.boldFont(size: 17)
        return theme
    }

}
