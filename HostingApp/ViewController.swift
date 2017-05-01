//
//  ViewController.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

class HostingAppViewController: UIViewController {

    @IBOutlet var instructionsFld: UILabel!
    @IBOutlet var titleFld: UILabel!
    @IBOutlet var bgSrcBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Localise the title
        if let infoDict = Bundle.main.localizedInfoDictionary {
            if let name = infoDict["CFBundleName"] as? String {
                titleFld.text = name
            }
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(HostingAppViewController.maybeShowSettings),
            name: .UIKeyboardWillShow,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(HostingAppViewController.maybeShowSettings),
            name: .UIKeyboardDidHide,
            object: nil)
        
        // Avoids strange bug where settings will not show if loaded from unloaded app
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            self.maybeShowSettings()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        maybeShowSettings()
    }
    
    func maybeShowSettings() {
        if AppDelegate.instance.wantsKeyboardList {
            AppDelegate.instance.wantsKeyboardList = false
            
            selectKeyboard()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func dismiss() {
        for view in self.view.subviews {
            if let inputView = view as? UITextField {
                inputView.resignFirstResponder()
            }
        }
    }

    @IBAction func openSettings() {
        if let url = URL(string: NSString(format: "%@BundleID", UIApplicationOpenSettingsURLString) as String) {
            UIApplication.shared.openURL(url)
        }
    }

    @IBAction func goToImgSource() {
        if let url = URL(string: "https://flic.kr/p/cLhn9J") {
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction func selectKeyboard() {
        let alert = UIAlertController(title: "Keyboard Layouts", message: nil, preferredStyle: .actionSheet)
        
        KeyboardDefinition.definitions.enumerated().forEach({ i, def in
            alert.addAction(UIAlertAction(title: def.name, style: .default, handler: { _ in
                KeyboardSettings.currentKeyboard = i
            }))
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
}
