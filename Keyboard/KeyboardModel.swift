//
//  KeyboardModel.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/10/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import Foundation
import UIKit

var counter = 0

enum ShiftState {
    case disabled
    case enabled
    case locked
    
    func uppercase() -> Bool {
        switch self {
        case .disabled:
            return false
        case .enabled:
            return true
        case .locked:
            return true
        }
    }
}

class Keyboard {
    var pages: [Page]
    
    init() {
        self.pages = []
    }
    
    func addKey(_ key: Key, row: Int, page: Int) {
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
    
    func addKey(_ key: Key, row: Int) {
        if self.rows.count <= row {
            for _ in self.rows.count...row {
                self.rows.append([])
            }
        }

        self.rows[row].append(key)
    }
}

class ModeChangeKey: Key {
    init(cap: String = "ABC", mode: Int = 0) {
        super.init(.modeChange)
        
        uppercaseKeyCap = cap
        toMode = mode
    }
    
    override func bind(view: KeyboardKey, target: KeyboardViewController) {
        // super.bind(view: view, target: target)
        
        view.addTarget(target, action: #selector(KeyboardViewController.modeChangeTapped(_:)), for: .touchDown)
    }
}

class SettingsKey: Key {
    init() {
        super.init(.settings)
    }
    
    override func bind(view: KeyboardKey, target: KeyboardViewController) {
        super.bind(view: view, target: target)
        
        view.addTarget(target, action: #selector(KeyboardViewController.toggleSettings), for: .touchUpInside)
    }
}

class ShiftKey: Key {
    init() {
        super.init(.shift)
    }
    
    override func bind(view: KeyboardKey, target: KeyboardViewController) {
        // super.bind(view: view, target: target)
        
        view.addTarget(target, action: #selector(KeyboardViewController.shiftDown(_:)), for: .touchDown)
        view.addTarget(target, action: #selector(KeyboardViewController.shiftUp(_:)), for: .touchUpInside)
        view.addTarget(target, action: #selector(KeyboardViewController.shiftDoubleTapped(_:)), for: .touchDownRepeat)
    }
}

class SpaceKey: Key {
    let hasName: Bool
    
    init(hasName: Bool = false) {
        self.hasName = hasName
        super.init(.space)
    }
    
    var isFirstBind = true
    var isChanging = false
    
    override func bind(view: KeyboardKey, target: KeyboardViewController) {
        super.bind(view: view, target: target)
        
        if isFirstBind {
            isFirstBind = false
        } else {
            return
        }
        
        if isChanging {
            return
        }
        
        isChanging = true
        
        target.changeSpaceName(view, completion: { [weak self] in
          self?.isChanging = false
        })
    }
}

class ChangeKey: Key {
    init() {
        super.init(.keyboardChange)
    }
    
    override func bind(view: KeyboardKey, target: KeyboardViewController) {
        // Not calling super to make sure we _dont_ bind it to anything else
        //super.bind(view: view, target: target)
        
        if #available(iOSApplicationExtension 10.0, *) {
            view.addTarget(target, action: #selector(KeyboardViewController.handleInputModeList(from:with:)), for: .allTouchEvents)
        } else {
            view.addTarget(target, action: #selector(KeyboardViewController.advanceTapped(_:withEvent:)), for: .touchUpInside)
        }

    }
}

class HideKey: Key {
    init() {
        super.init(.keyboardHide)
    }
    
    override func bind(view: KeyboardKey, target: KeyboardViewController) {
        super.bind(view: view, target: target)
        
        view.addTarget(target, action: #selector(UIInputViewController.dismissKeyboard), for: .touchUpInside)
    }
}

class BackspaceKey: Key {
    init() {
        super.init(.backspace)
    }
    
    override func bind(view: KeyboardKey, target: KeyboardViewController) {
        super.bind(view: view, target: target)
        
        let cancelEvents: UIControlEvents = [UIControlEvents.touchUpInside, UIControlEvents.touchUpInside, UIControlEvents.touchDragExit, UIControlEvents.touchUpOutside, UIControlEvents.touchCancel, UIControlEvents.touchDragOutside]
        
        view.addTarget(target, action: #selector(KeyboardViewController.backspaceDown(_:)), for: .touchDown)
        view.addTarget(target, action: #selector(KeyboardViewController.backspaceUp(_:)), for: cancelEvents)
    }
}

class Key: Hashable {
    enum KeyType {
        case character
        case specialCharacter
        case shift
        case backspace
        case modeChange
        case keyboardChange
        case keyboardHide
        case period
        case space
        case `return`
        case settings
        case other
    }
    
    var type: KeyType
    var uppercaseKeyCap: String?
    var lowercaseKeyCap: String?
    var uppercaseOutput: String?
    var lowercaseOutput: String?
    var uppercaseLongPressOutput: [String]?
    var lowercaseLongPressOutput: [String]?
    var toMode: Int? //if the key is a mode button, this indicates which page it links to
    
    func bind(view: KeyboardKey, target: KeyboardViewController) {
        if isCharacter {
            view.addTarget(target, action: #selector(KeyboardViewController.showPopup(_:)), for: [.touchDown, /*.touchDragInside,*/ .touchDragEnter])
            // TODO ensure this works, target was view before.
            view.addTarget(target, action: #selector(KeyboardViewController.hidePopup(_:)), for: [.touchDragExit, .touchCancel])
            view.addTarget(target, action: #selector(KeyboardViewController.hidePopupDelay(_:)), for: [.touchUpInside, .touchUpOutside, .touchDragOutside])
        }
        
        if hasOutput {
            view.addTarget(target, action: #selector(KeyboardViewController.keyPressedHelper(_:)), for: .touchUpInside)
        }
        
        view.addTarget(target, action: #selector(KeyboardViewController.highlightKey(_:)), for: [.touchDown, .touchDragInside, .touchDragEnter])
        view.addTarget(target, action: #selector(KeyboardViewController.unHighlightKey(_:)), for: [.touchUpInside, .touchUpOutside, .touchDragOutside, .touchDragExit, .touchCancel])
        view.addTarget(target, action: #selector(KeyboardViewController.playKeySound), for: .touchDown)
    }
    
    var isCharacter: Bool {
        get {
            switch self.type {
            case
            .character,
            .specialCharacter,
            .period:
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
            .shift,
            .backspace,
            .modeChange,
            .keyboardChange,
            .keyboardHide,
            .return,
            .settings:
                return true
            default:
                return false
            }
        }
    }
    
    var hasOutput: Bool {
        get {
            if self.type == .space { return true }
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
    
    func setLetter(lower: String, upper: String? = nil) {
        self.lowercaseOutput = lower
        self.uppercaseOutput = upper ?? lower.uppercased()
        self.lowercaseKeyCap = self.lowercaseOutput
        self.uppercaseKeyCap = self.uppercaseOutput
    }
    
    func setUppercaseLongPress(_ letters: [String]) {
        self.uppercaseLongPressOutput = letters
    }
    
    func setLowercaseLongPress(_ letters: [String]) {
        self.lowercaseLongPressOutput = letters
    }
    
    func longPressForCase(_ uppercase: Bool) -> [String] {
        if uppercase && self.hasUppercaseLongPress {
            return self.uppercaseLongPressOutput!
        } else if !uppercase && self.hasLowercaseLongPress {
            return self.lowercaseLongPressOutput!
        } else {
            return []
        }
    }
    
    func outputForCase(_ uppercase: Bool) -> String {
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
    
    func keyCapForCase(_ uppercase: Bool) -> String {
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
