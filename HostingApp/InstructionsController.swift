//
//  InstructionsController.swift
//  GiellaKeyboard
//
//  Created by Brendan Molloy on 15/5/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

class InstructionsController: ViewController<InstructionsView> {
    @objc private func openLanguages() {
        navigationController?.pushViewController(LanguagesController(), animated: true)
    }
    
    @objc private func applicationDidBecomeActive() {
        checkCurrentStep()
    }
    
    @objc private func onSkipTapped() {
        navigationController?.popViewController(animated: true)
    }
    
//    func openLayouts() {
//        guard let nc = navigationController else { return }
//
//        var vcs = nc.viewControllers
//        vcs.removeLast()
//        vcs.append(LayoutsController())
//        nc.setViewControllers(vcs, animated: true)
//    }
    
    func checkCurrentStep() {
        if AppDelegate.instance.isKeyboardEnabled {
//            openLayouts()
            onSkipTapped()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        contentView.bgImage.isHidden = false
        
        title = Strings.settingUp
        contentView.awakeFromNib()
        checkCurrentStep()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stops ugly transition
        contentView.bgImage.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "language")!.with(width: 24, height: 24),
            style: .plain,
            target: self,
            action: #selector(openLanguages))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.skip, style: .plain, target: self, action: #selector(onSkipTapped))
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
