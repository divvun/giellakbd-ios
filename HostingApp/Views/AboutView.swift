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
        
        let aboutFile =
            Strings.bundle.url(forResource: "About", withExtension: "txt") ??
            Bundle.main.url(forResource: "About", withExtension: "txt")
        
        if let file = aboutFile {
            aboutLabel.text = try? String(contentsOf: file)
        }
        
        attributionLabel.text = Strings.attributions
        creditsLabel.attributedText = Strings.creditWithUrls()
        
        aboutLabel.sizeToFit()
        creditsLabel.sizeToFit()
    }
}
