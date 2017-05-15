//
//  InstructionsView.swift
//  GiellaKeyboard
//
//  Created by Brendan Molloy on 15/5/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

class InstructionsView: UIView, Nibbable {
    @IBOutlet weak var step1Label: UILabel!
    @IBOutlet weak var step2Label: UILabel!
    @IBOutlet weak var step3Label: UILabel!
    @IBOutlet weak var step4Label: UILabel!
    @IBOutlet weak var step5Label: UILabel!
    @IBOutlet weak var step6Label: UILabel!
    
    @IBOutlet weak var bgImage: UIImageView!
    
    override func awakeFromNib() {
        step1Label.attributedText = Strings.openApp(item: Strings.settings)
        step2Label.attributedText = Strings.tap(item: Strings.general)
        step3Label.attributedText = Strings.tap(item: Strings.keyboard)
        step4Label.attributedText = Strings.tap(item: Strings.keyboards)
        step5Label.attributedText = Strings.tap(item: Strings.addNewKeyboard)
        step6Label.attributedText = Strings.tap(item: Strings.localizedName)
    }
}
