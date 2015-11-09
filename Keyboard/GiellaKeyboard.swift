//
//  GiellaKeyboard.swift
//  TastyImitationKeyboard
//
//  Created by Brendan Molloy on 24/10/2014.
//  Copyright (c) 2014
//

import UIKit

class GiellaKeyboard: KeyboardViewController {
    var keyNames: [String: String]
    
    override func keyPressed(key: Key) {
        let textDocumentProxy = self.textDocumentProxy as UIKeyInput
        
        textDocumentProxy.insertText(key.outputForCase(self.shiftState.uppercase()))
        
        hideLongPress()
    }
    
    init(keyboard: Keyboard, keyNames: [String: String]) {
        self.keyNames = keyNames
        super.init(nibName: nil, bundle: nil,
            keyboard: defaultControls(keyboard, keyNames: keyNames))
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
    
    override func setSpaceLocalName(keyView: KeyboardKey) {
        keyView.label.text = keyNames["keyboard"]
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
            if let keyView = self.lastKey {
                let key = self.layout!.keyForView(keyView)
                let longpresses = key!.longPressForCase(shiftState.uppercase())
                
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
        if let kbd = self.keyboard {
            let textDocumentProxy = kbd.textDocumentProxy as UIKeyInput
            textDocumentProxy.insertText(sender.titleLabel!.text!)
            
            kbd.hideLongPress()
            
            if kbd.shiftState == ShiftState.Enabled {
                kbd.shiftState = ShiftState.Disabled
            }
            
            kbd.setCapsIfNeeded()
        }
    }
    
    func applyConstraints(currentView: UIButton, prevView: UIView?, nextView: UIView?, firstView: UIView) {
        let parentView = self
        
        var leftConstraint: NSLayoutConstraint
        var rightConstraint: NSLayoutConstraint
        var topConstraint: NSLayoutConstraint
        var bottomConstraint: NSLayoutConstraint
        
        // Constrain to top of parent view
        topConstraint = NSLayoutConstraint(item: currentView, attribute: .Top, relatedBy: .Equal, toItem: parentView,
            attribute: .Top, multiplier: 1.0, constant: 1)
        
        // Constraint to bottom of parent too
        bottomConstraint = NSLayoutConstraint(item: currentView, attribute: .Bottom, relatedBy: .Equal, toItem: parentView, attribute: .Bottom, multiplier: 1.0, constant: -1)
        
        // If last, constrain to right
        if nextView == nil {
            rightConstraint = NSLayoutConstraint(item: currentView, attribute: .Right, relatedBy: .Equal, toItem: parentView, attribute: .Right, multiplier: 1.0, constant: -1)
        } else {
            rightConstraint = NSLayoutConstraint(item: currentView, attribute: .Right, relatedBy: .Equal, toItem: nextView, attribute: .Left, multiplier: 1.0, constant: -1)
        }
        
        // If first, constrain to left of parent
        if prevView == nil {
            leftConstraint = NSLayoutConstraint(item: currentView, attribute: .Left, relatedBy: .Equal, toItem: parentView, attribute: .Left, multiplier: 1.0, constant: 1)
        } else {
            leftConstraint = NSLayoutConstraint(item: currentView, attribute: .Left, relatedBy: .Equal, toItem: prevView, attribute: .Right, multiplier: 1.0, constant: 1)
            
            let widthConstraint = NSLayoutConstraint(item: firstView, attribute: .Width, relatedBy: .Equal, toItem: currentView, attribute: .Width, multiplier: 1.0, constant: 0)
            
            widthConstraint.priority = 800
            
            addConstraint(widthConstraint)
        }
        
        addConstraints([topConstraint, bottomConstraint, rightConstraint, leftConstraint])
        
    }
    
    
    func updateAlternateKeyList(keys: [String]) {
        let sv = self.subviews
        for v in sv {
            v.removeFromSuperview()
        }
        
        if keys.count == 0 {
            return
        }
        
        for char in keys {
            let btn: UIButton = UIButton(type: UIButtonType.System) as UIButton
            
            btn.frame = CGRectMake(0, 0, 20, 20)
            btn.setTitle(char, forState: .Normal)
            btn.sizeToFit()
            btn.titleLabel?.font = UIFont.systemFontOfSize(20)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.backgroundColor = UIColor(hue: (216/360.0), saturation: 0.1, brightness: 0.81, alpha: 1)
            btn.setTitleColor(UIColor(white: 1.0, alpha: 1.0), forState: .Normal)
            
            btn.setContentHuggingPriority(1000, forAxis: .Horizontal)
            btn.setContentCompressionResistancePriority(1000, forAxis: .Horizontal)
            
            btn.addTarget(self, action: Selector("handleBtnPress:"), forControlEvents: .TouchUpInside)
            
            self.addSubview(btn)
        }
        
        let firstBtn = self.subviews[0] as! UIButton
        let lastN = keys.count-1
        var prevBtn: UIButton?
        var nextBtn: UIButton?
        
        for (n, view) in self.subviews.enumerate() {
            let btn = view as! UIButton
            
            if n == lastN {
                nextBtn = nil
            } else {
                nextBtn = self.subviews[n+1] as? UIButton
            }
            
            if n == 0 {
                prevBtn = nil
            } else {
                prevBtn = self.subviews[n-1] as? UIButton
            }
            
            applyConstraints(btn, prevView: prevBtn, nextView: nextBtn, firstView: firstBtn)
        }
    }
}


func defaultControls(defaultKeyboard: Keyboard, keyNames: [String: String]) -> Keyboard {
    let isPad = UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad

    let backspace = Key(.Backspace)
    
    let keyModeChangeNumbers = Key(.ModeChange)
    keyModeChangeNumbers.uppercaseKeyCap = isPad ? ".?123" : "123"
    keyModeChangeNumbers.toMode = 1
    defaultKeyboard.addKey(keyModeChangeNumbers, row: 3, page: 0)
    
    let keyboardChange = Key(.KeyboardChange)
    defaultKeyboard.addKey(keyboardChange, row: 3, page: 0)
    
    let settings = Key(.Settings)
    defaultKeyboard.addKey(settings, row: 3, page: 0)
    
    let space = Key(.Space)
    space.uppercaseKeyCap = keyNames["space"]
    space.uppercaseOutput = " "
    space.lowercaseOutput = " "
    defaultKeyboard.addKey(space, row: 3, page: 0)
    
    let returnKey = Key(.Return)
    returnKey.uppercaseKeyCap = keyNames["return"]
    returnKey.uppercaseOutput = "\n"
    returnKey.lowercaseOutput = "\n"
    defaultKeyboard.addKey(isPad ? Key(keyModeChangeNumbers) : returnKey, row: 3, page: 0)
    
    if isPad {
        let hideKey = Key(.KeyboardHide)
        hideKey.uppercaseKeyCap = "⥥"
        defaultKeyboard.addKey(hideKey, row: 3, page: 0)
    }
    
    for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"] {
        let keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 0, page: 1)
    }
    
    for key in ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""] {
        let keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 1, page: 1)
    }
    
    let keyModeChangeSpecialCharacters = Key(.ModeChange)
    keyModeChangeSpecialCharacters.uppercaseKeyCap = "#+="
    keyModeChangeSpecialCharacters.toMode = 2
    defaultKeyboard.addKey(keyModeChangeSpecialCharacters, row: 2, page: 1)
    
    for key in [".", ",", "?", "!", "'"] {
        let keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 2, page: 1)
    }
    
    defaultKeyboard.addKey(Key(backspace), row: 2, page: 1)
    
    let keyModeChangeLetters = Key(.ModeChange)
    keyModeChangeLetters.uppercaseKeyCap = "ABC"
    keyModeChangeLetters.toMode = 0
    defaultKeyboard.addKey(keyModeChangeLetters, row: 3, page: 1)
    
    defaultKeyboard.addKey(Key(keyboardChange), row: 3, page: 1)
    
    defaultKeyboard.addKey(Key(settings), row: 3, page: 1)
    
    defaultKeyboard.addKey(Key(space), row: 3, page: 1)
    
    defaultKeyboard.addKey(Key(returnKey), row: 3, page: 1)
    
    for key in ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="] {
        let keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 0, page: 2)
    }
    
    for key in ["_", "\\", "|", "~", "<", ">", "€", "£", "Y", "•"] {
        let keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 1, page: 2)
    }
    
    defaultKeyboard.addKey(Key(keyModeChangeNumbers), row: 2, page: 2)
    
    for key in [".", ",", "?", "!", "'"] {
        let keyModel = Key(.SpecialCharacter)
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

