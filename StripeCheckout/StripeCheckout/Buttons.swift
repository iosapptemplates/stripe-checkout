//
//  Buttons.swift
//  Standard Integration (Swift)
//
//  Created by Ben Guo on 4/25/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import UIKit
import Stripe

class HighlightingButton: UIButton {
    var highlightColor = UIColor(white: 0, alpha: 0.05)

    convenience init(highlightColor: UIColor) {
        self.init()
        self.highlightColor = highlightColor
    }

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                self.backgroundColor = self.highlightColor
            } else {
                self.backgroundColor = UIColor.clear
            }
        }
    }
}
