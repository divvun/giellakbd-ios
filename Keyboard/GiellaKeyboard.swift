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
        
        hideLongPress()
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
    
    func disableInput() {
        self.forwardingView.userInteractionEnabled = false
        
        // Workaround to kill current touches
        self.forwardingView.removeFromSuperview()
        self.view.addSubview(self.forwardingView)
        
        if self.lastKey != nil {
            super.hidePopup(self.lastKey!)
        }
    }
    
    func enableInput() {
        self.forwardingView.userInteractionEnabled = true
    }
    
    override func showLongPress() {
        super.showLongPress()
        
        if let banner = self.bannerView as? GiellaBanner {
            //self.lastKey?.label.text = "!"
            //banner.label.text = self.lastKey?.label.text
            if let keyView = self.lastKey? {
                let key = self.layout!.keyForView(keyView)
                var longpresses = key!.longPressForCase(shiftState.uppercase())
                
                if longpresses.count > 0 {
                    //self.disableInput()
                    banner.updateAlternateKeyList(longpresses)
                }
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
    var keyboard: GiellaKeyboard?
    
    convenience init(keyboard: GiellaKeyboard) {
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
        
        keyboard?.hideLongPress()
    }
    
    func applyConstraints(currentView: UIButton, prevView: UIView?, nextView: UIView?, firstView: UIView) {
        let parentView = self
        
        /*
        var leftConstraint: NSLayoutConstraint;
        
        btn.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        if first {
            leftConstraint = NSLayoutConstraint(item: btn, attribute: .Left, relatedBy: .Equal, toItem: lastView, attribute: .Left, multiplier: 1.0, constant: 1)
        } else if last {
            // Actually right but let's reuse a var.
            leftConstraint = NSLayoutConstraint(item: btn, attribute: .Right, relatedBy: .Equal, toItem: lastView, attribute: .Right, multiplier: 1.0, constant: -1)
        } else {
            leftConstraint = NSLayoutConstraint(item: btn, attribute: .Left, relatedBy: .Equal, toItem: lastView, attribute: .Right, multiplier: 1.0, constant: 1)
            let widthConstraint = NSLayoutConstraint(item: btn, attribute: .Width, relatedBy: .Equal, toItem: firstView, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0)
            widthConstraint.priority = 800
            
            self.addConstraint(widthConstraint)
        }
        
        let heightConstraint = NSLayoutConstraint(item: btn, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0)
        self.addConstraint(leftConstraint)
        
        self.addConstraint(heightConstraint)
        */
        // Constrain to top of parent view
        let topConstraint = NSLayoutConstraint(item: currentView, attribute: .Top, relatedBy: .Equal, toItem: parentView,
            attribute: .Top, multiplier: 1, constant: 1)
        
        // Constraint to bottmo of parent too
        let bottomConstraint = NSLayoutConstraint(item: currentView, attribute: .Bottom, relatedBy: .Equal, toItem: parentView, attribute: .Bottom, multiplier: 1, constant: 1)
        
        addConstraints([topConstraint, bottomConstraint])
        
        // If first, constrain to left of parent
        if prevView == nil {
            let leftConstraint = NSLayoutConstraint(item: currentView, attribute: .Left, relatedBy: .Equal, toItem: parentView, attribute: .Left, multiplier: 1, constant: 1)
            addConstraint(leftConstraint)
        }
        
        // If last, constrain to right
        if nextView == nil {
            let rightConstraint = NSLayoutConstraint(item: currentView, attribute: .Right, relatedBy: .Equal, toItem: parentView, attribute: .Right, multiplier: 1, constant: 1)
            addConstraint(rightConstraint)
        }
        
        // Constrain to previous button if all is well, and set same width
        if nextView != nil && prevView != nil {
            let rightConstraint = NSLayoutConstraint(item: currentView, attribute: .Right, relatedBy: .Equal, toItem: nextView, attribute: .Left, multiplier: 1, constant: -1)
            
            let leftConstraint = NSLayoutConstraint(item: currentView, attribute: .Left, relatedBy: .Equal, toItem: prevView, attribute: .Right, multiplier: 1, constant: 1)
            
            let widthConstraint = NSLayoutConstraint(item: firstView, attribute: .Width, relatedBy: .Equal, toItem: currentView, attribute: .Width, multiplier: 1, constant: 0)
            
            widthConstraint.priority = 800
            
            addConstraints([rightConstraint, leftConstraint, widthConstraint])
        }
    }

    
    func updateAlternateKeyList(keys: [String]) {
        var sv = self.subviews
        for v in sv {
            v.removeFromSuperview()
        }
        
        var lastN = keys.count-1
        var prevBtn: UIButton?
        var nextBtn: UIButton?
        
        for char in keys {
            var btn: UIButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
            btn.setTitle(char, forState: UIControlState.Normal)
            
            btn.addTarget(self, action: Selector("handleBtnPress:"), forControlEvents: .TouchUpInside)
            
            self.addSubview(btn)
        }
        
        let firstBtn = self.subviews[0] as UIButton
        
        for (n, view) in enumerate(self.subviews) {
            let btn = view as UIButton
            
            if n == lastN {
                nextBtn = nil
            } else {
                nextBtn = self.subviews[n+1] as? UIButton
            }
            
            applyConstraints(btn, prevView: prevBtn, nextView: nextBtn, firstView: firstBtn)
            
            prevBtn = btn
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

