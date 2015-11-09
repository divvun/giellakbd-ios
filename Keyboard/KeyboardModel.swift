//
//  KeyboardModel.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/10/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import Foundation

var counter = 0

enum ShiftState {
    case Disabled
    case Enabled
    case Locked
    
    func uppercase() -> Bool {
        switch self {
        case Disabled:
            return false
        case Enabled:
            return true
        case Locked:
            return true
        }
    }
}

class Keyboard {
    var pages: [Page]
    
    init() {
        self.pages = []
    }
    
    func addKey(key: Key, row: Int, page: Int) {
        if self.pages.count <= page {
            for _ in self.pages.count...page {
                self.pages.append(Page())
            }
        }
        
        self.pages[page].addKey(key, row: row)
    }
}

class Page {
    var rows: [[Key]]
    
    init() {
        self.rows = []
    }
    
    func addKey(key: Key, row: Int) {
        if self.rows.count <= row {
            for _ in self.rows.count...row {
                self.rows.append([])
            }
        }

        self.rows[row].append(key)
    }
}

class Key: Hashable {
    enum KeyType {
        case Character
        case SpecialCharacter
        case Shift
        case Backspace
        case ModeChange
        case KeyboardChange
        case KeyboardHide
        case Period
        case Space
        case Return
        case Settings
        case Other
    }
    
    var type: KeyType
    var uppercaseKeyCap: String?
    var lowercaseKeyCap: String?
    var uppercaseOutput: String?
    var lowercaseOutput: String?
    var uppercaseLongPressOutput: [String]?
    var lowercaseLongPressOutput: [String]?
    var toMode: Int? //if the key is a mode button, this indicates which page it links to
    
    var isCharacter: Bool {
        get {
            switch self.type {
            case
            .Character,
            .SpecialCharacter,
            .Period:
                return true
            default:
                return false
            }
        }
    }
    
    var isSpecial: Bool {
        get {
            switch self.type {
            case
            .Shift,
            .Backspace,
            .ModeChange,
            .KeyboardChange,
            .KeyboardHide,
            .Return,
            .Settings:
                return true
            default:
                return false
            }
        }
    }
    
    var hasOutput: Bool {
        get {
            return (self.uppercaseOutput != nil) || (self.lowercaseOutput != nil)
        }
    }
    
    var hasLowercaseLongPress: Bool {
        get {
            return self.lowercaseLongPressOutput != nil
        }
    }
    
    var hasUppercaseLongPress: Bool {
        get {
            return self.uppercaseLongPressOutput != nil
        }
    }
    
    // TODO: this is kind of a hack
    var hashValue: Int
    
    init(_ type: KeyType) {
        self.type = type
        self.hashValue = counter
        counter += 1
    }
    
    convenience init(_ key: Key) {
        self.init(key.type)
        
        self.uppercaseKeyCap = key.uppercaseKeyCap
        self.lowercaseKeyCap = key.lowercaseKeyCap
        self.uppercaseOutput = key.uppercaseOutput
        self.lowercaseOutput = key.lowercaseOutput
        self.toMode = key.toMode
    }
    
    func setLetter(letter: String) {
        self.lowercaseOutput = (letter as NSString).lowercaseString
        self.uppercaseOutput = (letter as NSString).uppercaseString
        self.lowercaseKeyCap = self.lowercaseOutput
        self.uppercaseKeyCap = self.uppercaseOutput
    }
    
    func setUppercaseLongPress(letters: [String]) {
        self.uppercaseLongPressOutput = letters
    }
    
    func setLowercaseLongPress(letters: [String]) {
        self.lowercaseLongPressOutput = letters
    }
    
    func longPressForCase(uppercase: Bool) -> [String] {
        if uppercase && self.hasUppercaseLongPress {
            return self.uppercaseLongPressOutput!
        } else if !uppercase && self.hasLowercaseLongPress {
            return self.lowercaseLongPressOutput!
        } else {
            return []
        }
    }
    
    func outputForCase(uppercase: Bool) -> String {
        if uppercase {
            if self.uppercaseOutput != nil {
                return self.uppercaseOutput!
            }
            else if self.lowercaseOutput != nil {
                return self.lowercaseOutput!
            }
            else {
                return ""
            }
        }
        else {
            if self.lowercaseOutput != nil {
                return self.lowercaseOutput!
            }
            else if self.uppercaseOutput != nil {
                return self.uppercaseOutput!
            }
            else {
                return ""
            }
        }
    }
    
    func keyCapForCase(uppercase: Bool) -> String {
        if uppercase {
            if self.uppercaseKeyCap != nil {
                return self.uppercaseKeyCap!
            }
            else if self.lowercaseKeyCap != nil {
                return self.lowercaseKeyCap!
            }
            else {
                return ""
            }
        }
        else {
            if self.lowercaseKeyCap != nil {
                return self.lowercaseKeyCap!
            }
            else if self.uppercaseKeyCap != nil {
                return self.uppercaseKeyCap!
            }
            else {
                return ""
            }
        }
    }
}

func ==(lhs: Key, rhs: Key) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
