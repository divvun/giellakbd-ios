//
//  HomeController.swift
//  GiellaKeyboard
//
//  Created by Brendan Molloy on 12/5/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

class HomeController: ViewController<HomeView>, HideNavBar {
//    @objc private func openLayouts() {
//        self.navigationController?.pushViewController(LayoutsController(), animated: true)
//    }
    
    @objc private func openLanguages() {
        self.navigationController?.pushViewController(LanguagesController(), animated: true)
    }
    
    @objc private func openInstructions() {
        self.navigationController?.pushViewController(InstructionsController(), animated: true)
    }
    
    @objc private func openAbout() {
        self.navigationController?.pushViewController(AboutController(), animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        contentView.configStack?.isHidden = AppDelegate.instance.isKeyboardEnabled
        contentView.awakeFromNib()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Strings.localizedName
        
//        contentView.layoutsButton.addTarget(self, action: #selector(openLayouts), for: [.touchUpInside])
        contentView.langButton.addTarget(self, action: #selector(openLanguages), for: [.touchUpInside])
        contentView.langButton2.addTarget(self, action: #selector(openLanguages), for: [.touchUpInside])
        contentView.helpButton.addTarget(self, action: #selector(openInstructions), for: [.touchUpInside])
        contentView.aboutButton.addTarget(self, action: #selector(openAbout), for: [.touchUpInside])
    }
}
