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
        
        if let infoDict = NSBundle.mainBundle().localizedInfoDictionary? {
            if let name = infoDict["CFBundleName"] as? String {
                titleFld.text = name
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func dismiss() {
        for view in self.view.subviews {
            if var inputView = view as? UITextField {
                inputView.resignFirstResponder()
            }
        }
    }
    
    @IBAction func openSettings() {
        if let url = NSURL(string: UIApplicationOpenSettingsURLString)? {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    @IBAction func goToImgSource() {
        if let url = NSURL(string: "https://flic.kr/p/cLhn9J")? {
            UIApplication.sharedApplication().openURL(url)
        }
    }
}

