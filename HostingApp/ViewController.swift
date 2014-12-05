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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let infoDict = NSBundle.mainBundle().infoDictionary? {
            if let name: AnyObject = infoDict["CFBundleName"]? {
                titleFld.text = name as? String
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
}

