//
//  ViewController.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

class HostingAppViewController: UIViewController {

    @IBOutlet var stats: UILabel?
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

        NotificationCenter.default.addObserver(self, selector: #selector(HostingAppViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HostingAppViewController.keyboardDidHide), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillChangeFrame:"), name: UIKeyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HostingAppViewController.keyboardDidChangeFrame(_:)), name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil)
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
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    @IBAction func goToImgSource() {
        if let url = URL(string: "https://flic.kr/p/cLhn9J") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    var startTime: TimeInterval?
    var firstHeightTime: TimeInterval?
    var secondHeightTime: TimeInterval?
    var referenceHeight = CGFloat(216)

    func keyboardWillShow() {
        if startTime == nil {
            startTime = CACurrentMediaTime()
        }
    }

    func keyboardDidHide() {
        startTime = nil
        firstHeightTime = nil
        secondHeightTime = nil

        self.stats?.text = "(Waiting for keyboard...)"
    }

    func keyboardDidChangeFrame(_ notification: Notification) {
        //let frameBegin: CGRect! = notification.userInfo?[UIKeyboardFrameBeginUserInfoKey]?.CGRectValue
        let frameEnd: CGRect! = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue

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
