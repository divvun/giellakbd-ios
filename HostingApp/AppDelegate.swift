//
//  AppDelegate.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit
import Sentry

class AppNavControllerDelegate: NSObject, UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        viewController.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        if viewController is HideNavBar {
            navigationController.setNavigationBarHidden(true, animated: true)
        } else {
            navigationController.setNavigationBarHidden(false, animated: true)
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        toVC.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        return nil
    }
}

let str1 = "containing"
let str2 = "Bundle"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    static weak var instance: AppDelegate!
                            
    var window: UIWindow?
    var wantsKeyboardList = false
    
    let nc = UINavigationController(rootViewController: HomeController())
    let ncDelegate = AppNavControllerDelegate()
    
    var isKeyboardEnabled: Bool {
        let x: [Bundle] = UITextInputMode.activeInputModes.compactMap({
            let s = str1 + str2
            
            let v = $0.perform(Selector(s))
            if let x = v?.takeUnretainedValue() as? Bundle {
                return x
            }
            
            return nil
        })
        
        return x.contains(Bundle.main)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        AppDelegate.instance = self
        
        if let sentryDSN = Bundle.main.infoDictionary?["SentryDSN"] as? String {
            do {
                Client.shared = try Client(dsn: sentryDSN)
                try Client.shared?.startCrashHandler()
            } catch let error {
                print("\(error)")
                // Wrong DSN or KSCrash not installed
            }
        }
        
        Strings.languageCode = KeyboardSettings.languageCode
        
        nc.delegate = ncDelegate
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = nc
        window!.makeKeyAndVisible()
        
        if !isKeyboardEnabled && KeyboardSettings.firstLoad {
            KeyboardSettings.firstLoad = false
            nc.pushViewController(InstructionsController(), animated: false)
        }

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
        guard let _ = Bundle.main.bundleIdentifier else {
            return
        }
//
//        if url.scheme == bundleId && url.host == "settings" {
//            nc.pushViewController(LayoutsController(), animated: true)
//        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        parseUrl(url)
        return true
    }
}

