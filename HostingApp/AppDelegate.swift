//
//  AppDelegate.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    static weak var instance: AppDelegate!
                            
    var window: UIWindow?
    var wantsKeyboardList = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        AppDelegate.instance = self
        // Override point for customization after application launch.
        /*
        let zhfst = ZHFSTOSpeller()
        let path = "\(NSBundle.mainBundle().pathForResource("dicts", ofType: "bundle")!)/se.zhfst"
        NSLog("%@", path)
        zhfst.readZhfst(path, tempDir: NSTemporaryDirectory())
        zhfst.setQueueLimit(3)
        
        let suggs = zhfst.suggest("nuvviDspeller");
        
        for pair in suggs {
            NSLog("%@ %@", pair.first as! NSString, pair.second as! NSNumber);
        }
        */
        
        if let url = launchOptions?[UIApplicationLaunchOptionsKey.url] {
            let url = url as! URL
            
            parseUrl(url)
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }
    
    func parseUrl(_ url: URL) {
        if url.scheme == "giellakbd" && url.host == "settings" {
            wantsKeyboardList = true
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        parseUrl(url)
        return true
    }
}

