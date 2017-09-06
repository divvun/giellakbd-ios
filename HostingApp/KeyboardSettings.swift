//
//  KeyboardSettings.swift
//  GiellaKeyboard
//
//  Created by Brendan Molloy on 30/4/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation

fileprivate let defaults = UserDefaults(suiteName: "group.\(KeyboardSettings.groupId)")!

class KeyboardSettings {
    static var groupId: String = {
        let schemes = Bundle.main.infoDictionary!["LSApplicationQueriesSchemes"]! as! Array<String>
        return schemes.first!
    }()
    
    static var currentKeyboard: Int {
        get { return defaults.integer(forKey: "currentKeyboard") }
        set { defaults.set(newValue, forKey: "currentKeyboard") }
    }
    
    static var languageCode: String {
        get { return defaults.string(forKey: "language") ?? Locale.current.languageCode! }
        set { defaults.set(newValue, forKey: "language") }
    }
    
    static var firstLoad: Bool {
        get { return defaults.object(forKey: "firstLoad") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "firstLoad") }
    }
}
