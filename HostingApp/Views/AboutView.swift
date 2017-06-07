//
//  AboutView.swift
//  GiellaKeyboard
//
//  Created by Brendan Molloy on 1/6/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

class AboutView: UIView, Nibbable {
    @IBOutlet weak var aboutLabel: UITextView!
    @IBOutlet weak var attributionLabel: UILabel!
    @IBOutlet weak var creditsLabel: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        aboutLabel.text = try? String(contentsOf: Strings.bundle.url(forResource: "About", withExtension: "txt")!)
        attributionLabel.text = Strings.attributions
        creditsLabel.attributedText = Strings.creditWithUrls()
        
        aboutLabel.sizeToFit()
        creditsLabel.sizeToFit()
    }
}
