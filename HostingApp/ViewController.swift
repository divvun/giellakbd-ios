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

    func keyboardDidHide() {
        startTime = nil
        firstHeightTime = nil
        secondHeightTime = nil

        self.stats?.text = "(Waiting for keyboard...)"
    }

    func keyboardDidChangeFrame(notification: NSNotification) {
        let frameBegin: CGRect! = notification.userInfo?[UIKeyboardFrameBeginUserInfoKey]?.CGRectValue
        let frameEnd: CGRect! = notification.userInfo?[UIKeyboardFrameEndUserInfoKey]?.CGRectValue

        if frameEnd.height == referenceHeight {
            if firstHeightTime == nil {
                firstHeightTime = CACurrentMediaTime()

                if let startTime = self.startTime {
                    if let firstHeightTime = self.firstHeightTime {
                        let formatString = NSString(format: "First: %.2f, Total: %.2f", (firstHeightTime - startTime), (firstHeightTime - startTime))
                        self.stats?.text = formatString as String
                    }
                }
            }
        }
        else if frameEnd.height != 0 {
            if secondHeightTime == nil {
                secondHeightTime = CACurrentMediaTime()

                if let startTime = self.startTime {
                    if let firstHeightTime = self.firstHeightTime {
                        if let secondHeightTime = self.secondHeightTime {
                            let formatString = NSString(format: "First: %.2f, Second: %.2f, Total: %.2f", (firstHeightTime - startTime), (secondHeightTime - firstHeightTime), (secondHeightTime - startTime))
                            self.stats?.text = formatString as String
                        }
                    }
                }
            }
        }
    }
}
