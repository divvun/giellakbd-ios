//
//  KeyboardSettings.swift
//  GiellaKeyboard
//
//  Created by Brendan Molloy on 30/4/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation

fileprivate let defaults = UserDefaults(suiteName: "group.divvunkbd")!

class KeyboardSettings {
    static var currentKeyboard: Int {
        get { return defaults.integer(forKey: "currentKeyboard") }
        set { defaults.set(newValue, forKey: "currentKeyboard") }
    }
}
