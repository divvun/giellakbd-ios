//
//  AboutView.swift
//  GiellaKeyboard
//
//  Created by Brendan Molloy on 1/6/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

class AboutView: UIView, Nibbable {
    @IBOutlet weak var attributionLabel: UILabel!
    @IBOutlet weak var creditsLabel: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        creditsLabel.attributedText = Strings.creditWithUrls()
    }
}
