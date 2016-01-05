//
//  ExtraView.swift
//  TastyImitationKeyboard
//
//  Created by Alexei Baboulevitch on 10/5/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

class ExtraView: UIView {
    
    var globalColors: GlobalColors.Type?
    var darkMode: Bool = false
    var solidColorMode: Bool = false
    
    init() {
        super.init(frame: CGRectZero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
