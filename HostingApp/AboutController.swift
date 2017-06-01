//
//  AboutController.swift
//  GiellaKeyboard
//
//  Created by Brendan Molloy on 1/6/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit
import WebKit

class AboutController: UIViewController, WKUIDelegate {
    
    var webView: WKWebView!
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Strings.about
        
        let myURL = URL(string: "http://divvun.no")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
    }
}
