//
//  HomeView.swift
//  GiellaKeyboard
//
//  Created by Brendan Molloy on 12/5/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

class HomeView: UIView, Nibbable {
    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var langButton: UIButton!
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var layoutsButton: UIButton!
    @IBOutlet weak var aboutButton: UIButton!
    
    @IBOutlet weak var configStack: UIStackView?
    
    override func awakeFromNib() {
        titleLabel.text = Strings.localizedName
        langButton.setTitle(Strings.language, for: [])
        helpButton.setTitle(Strings.setUp(keyboard: Strings.localizedName), for: [])
        layoutsButton.setTitle(Strings.layouts, for: [])
        aboutButton.setTitle(Strings.about, for: [])
    }
}
