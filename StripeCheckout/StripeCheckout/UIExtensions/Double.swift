//
//  NSNumber.swift
//  DashboardApp
//
//  Created by Florian Marcu on 8/10/18.
//  Copyright © 2018 Instamobile. All rights reserved.
//

import UIKit

extension Double {
    func abbreviated() -> String {
        // less than 1000, no abbreviation
        if self < 1000 {
            return "\(self)"
        }

        // less than 1 million, abbreviate to thousands
        if self < 1000000 {
            var n = Double(self);
            n = Double( floor(n/100)/10 )
            if n == Double(Int(n)) {
                return "\(Int(n))K"
            }
            return "\(n.description)K"
        }

        // more than 1 million, abbreviate to millions
        var n = Double(self)
        n = Double( floor(n/100000)/10 )
        if n == Double(Int(n)) {
            return "\(Int(n))M"
        }
        return "\(n.description)M"
    }

    func twoDecimals() -> Double {
        return Double((1000 * self).rounded() / 1000)
    }

    func twoDecimalsString() -> String {
        return String(format: "%.2f", self.twoDecimals())
    }
}
