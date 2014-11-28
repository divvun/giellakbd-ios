//
//  GiellaKeyboard.swift
//  TastyImitationKeyboard
//
//  Created by Brendan Molloy on 24/10/2014.
//  Copyright (c) 2014
//

import UIKit

class GiellaKeyboard: KeyboardViewController {
    override func keyPressed(key: Key) {
        if let textDocumentProxy = self.textDocumentProxy as? UIKeyInput {
            textDocumentProxy.insertText(key.outputForCase(self.shiftState.uppercase()))
        }
    }
    
    init(keyboard: Keyboard, keyNames: [String: String]) {
        super.init(nibName: nil, bundle: nil,
            keyboard: defaultControls(keyboard, keyNames))
    }
    
    convenience init() {
        // XXX: generatedKeyboard() must be generated! :)
        self.init(keyboard: generatedKeyboard(), keyNames: generatedConfig())
    }
    
    override func createBanner() -> ExtraView? {
        return GiellaBanner(keyboard: self)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func showLongPress() {
        super.showLongPress()
        
        if let banner = self.bannerView as? GiellaBanner {
            //self.lastKey?.label.text = "!"
            //banner.label.text = self.lastKey?.label.text
            if let keyView = self.lastKey? {
                let key = self.layout!.keyForView(keyView)
                banner.updateAlternateKeyList(key!.longPressForCase(shiftState.uppercase()))
            }
        }
    }
    
    override func hideLongPress() {
        super.hideLongPress()
        
        if let banner = self.bannerView as? GiellaBanner {
            //self.lastKey?.label.text = "!"
            //banner.label.text = ""
            banner.updateAlternateKeyList([])

        }
    }
}

class GiellaBanner: ExtraView {
    
    //var label: UILabel = UILabel()
    var keyboard: KeyboardViewController?;
    
    convenience init(keyboard: KeyboardViewController) {
        self.init(globalColors: nil, darkMode: false, solidColorMode: false)
        self.keyboard = keyboard
    }
    
    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
        super.init(globalColors: globalColors, darkMode: darkMode, solidColorMode: solidColorMode)
        self.keyboard = nil
        /*
        self.addSubview(self.label)
        
        //self.label.font = UIFont(name: "ChalkboardSE-Regular", size: 22)
        self.label.text = "Loaded."
        self.label.sizeToFit()
        */
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //self.label.center.y = self.center.y
    }
    
    func handleBtnPress(sender: UIButton) {
        if let textDocumentProxy = keyboard?.textDocumentProxy as? UIKeyInput {
            textDocumentProxy.insertText(sender.titleLabel!.text!)
        }
    }
    
    func updateAlternateKeyList(keys: [String]) {
        var sv = self.subviews
        for v in sv {
            v.removeFromSuperview()
        }
        
        var lastView: UIView = self
        var first = true;
        
        for char in keys {
            var btn: UIButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
            btn.setTitle(char, forState: UIControlState.Normal)
            
            btn.addTarget(self, action: "handleBtnPress:", forControlEvents: .TouchUpInside)

            self.addSubview(btn)
            
            btn.setTranslatesAutoresizingMaskIntoConstraints(false)
            
            var leftConstraint: NSLayoutConstraint;
            
            if first {
                first = false
                leftConstraint = NSLayoutConstraint(item: btn, attribute: .Left, relatedBy: .Equal, toItem: lastView, attribute: .Left, multiplier: 1.0, constant: 1)
            } else {
                leftConstraint = NSLayoutConstraint(item: btn, attribute: .Left, relatedBy: .Equal, toItem: lastView, attribute: .Right, multiplier: 1.0, constant: 1)
                let widthConstraint = NSLayoutConstraint(item: btn, attribute: .Width, relatedBy: .Equal, toItem: lastView, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0)
                
                self.addConstraint(widthConstraint)
            }
            
            let heightConstraint = NSLayoutConstraint(item: btn, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0)
            self.addConstraint(leftConstraint)

            self.addConstraint(heightConstraint)
            
            lastView = btn
        }

    }
}


func defaultControls(defaultKeyboard: Keyboard, keyNames: [String: String]) -> Keyboard {
    var backspace = Key(.Backspace)
    defaultKeyboard.addKey(backspace, row: 2, page: 0)
    
    var keyModeChangeNumbers = Key(.ModeChange)
    keyModeChangeNumbers.uppercaseKeyCap = "123"
    keyModeChangeNumbers.toMode = 1
    defaultKeyboard.addKey(keyModeChangeNumbers, row: 3, page: 0)
    
    var keyboardChange = Key(.KeyboardChange)
    defaultKeyboard.addKey(keyboardChange, row: 3, page: 0)
    
    var settings = Key(.Settings)
    defaultKeyboard.addKey(settings, row: 3, page: 0)
    
    var space = Key(.Space)
    space.uppercaseKeyCap = keyNames["space"]
    space.uppercaseOutput = " "
    space.lowercaseOutput = " "
    defaultKeyboard.addKey(space, row: 3, page: 0)
    
    var returnKey = Key(.Return)
    returnKey.uppercaseKeyCap = keyNames["return"]
    returnKey.uppercaseOutput = "\n"
    returnKey.lowercaseOutput = "\n"
    defaultKeyboard.addKey(returnKey, row: 3, page: 0)
    
    for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"] {
        var keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 0, page: 1)
    }
    
    for key in ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""] {
        var keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 1, page: 1)
    }
    
    var keyModeChangeSpecialCharacters = Key(.ModeChange)
    keyModeChangeSpecialCharacters.uppercaseKeyCap = "#+="
    keyModeChangeSpecialCharacters.toMode = 2
    defaultKeyboard.addKey(keyModeChangeSpecialCharacters, row: 2, page: 1)
    
    for key in [".", ",", "?", "!", "'"] {
        var keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 2, page: 1)
    }
    
    defaultKeyboard.addKey(Key(backspace), row: 2, page: 1)
    
    var keyModeChangeLetters = Key(.ModeChange)
    keyModeChangeLetters.uppercaseKeyCap = "ABC"
    keyModeChangeLetters.toMode = 0
    defaultKeyboard.addKey(keyModeChangeLetters, row: 3, page: 1)
    
    defaultKeyboard.addKey(Key(keyboardChange), row: 3, page: 1)
    
    defaultKeyboard.addKey(Key(settings), row: 3, page: 1)
    
    defaultKeyboard.addKey(Key(space), row: 3, page: 1)
    
    defaultKeyboard.addKey(Key(returnKey), row: 3, page: 1)
    
    for key in ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="] {
        var keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 0, page: 2)
    }
    
    for key in ["_", "\\", "|", "~", "<", ">", "€", "£", "Y", "•"] {
        var keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 1, page: 2)
    }
    
    defaultKeyboard.addKey(Key(keyModeChangeNumbers), row: 2, page: 2)
    
    for key in [".", ",", "?", "!", "'"] {
        var keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 2, page: 2)
    }
    
    defaultKeyboard.addKey(Key(backspace), row: 2, page: 2)
    
    defaultKeyboard.addKey(Key(keyModeChangeLetters), row: 3, page: 2)
    
    defaultKeyboard.addKey(Key(keyboardChange), row: 3, page: 2)
    
    defaultKeyboard.addKey(Key(settings), row: 3, page: 2)
    
    defaultKeyboard.addKey(Key(space), row: 3, page: 2)
    
    defaultKeyboard.addKey(Key(returnKey), row: 3, page: 2)
    
    return defaultKeyboard
}

