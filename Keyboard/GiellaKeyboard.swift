//
//  GiellaKeyboard.swift
//  TastyImitationKeyboard
//
//  Created by Brendan Molloy on 24/10/2014.
//  Copyright (c) 2014
//

import UIKit

class SuggestionOp: NSOperation {
    let word: String
    let kbd: GiellaKeyboard
    
    init (kbd: GiellaKeyboard, word: String) {
        self.kbd = kbd
        self.word = word
    }
    
    override func main() {
        if (cancelled) {
            return
        }
        
        let suggestions = self.kbd.zhfst?.suggest(word).prefix(3).map({ (pair) in
            return pair.first as! String
        })
        
        dispatch_async(dispatch_get_main_queue()) {
            if let suggestions = suggestions {
                if let banner = self.kbd.bannerView as? GiellaBanner {
                    banner.mode = .Suggestion
                    banner.updateAlternateKeyList(suggestions);
                }
            }
        }
    }
}

class GiellaKeyboard: KeyboardViewController {
    var keyNames: [String: String]
    
    var zhfst: ZHFSTOSpeller?
    
    let opQueue = NSOperationQueue()
    
    func updateSuggestions() {
        let documentProxy = self.textDocumentProxy as UITextDocumentProxy
        
        guard let banner = self.bannerView as? GiellaBanner else {
            return
        }
        
        guard let beforeContext = documentProxy.documentContextBeforeInput else {
            banner.updateAlternateKeyList([])
            return
        }
        
        guard let lastWord = beforeContext.componentsSeparatedByString(" ").last else {
            banner.updateAlternateKeyList([])
            return
        }
        
        if lastWord == "" {
            banner.updateAlternateKeyList([])
            return
        }
        
        opQueue.cancelAllOperations()
        opQueue.addOperation(SuggestionOp(kbd: self, word: lastWord))
    }
    
    override func contextChanged() {
        super.contextChanged()
        
        updateSuggestions()
    }
    
    override func keyPressed(key: Key) {
        let textDocumentProxy = self.textDocumentProxy as UIKeyInput
        
        textDocumentProxy.insertText(key.outputForCase(self.shiftState.uppercase()))
        
        updateSuggestions()
    }
    
    init(keyboard: Keyboard, keyNames: [String: String]) {
        self.keyNames = keyNames
        super.init(nibName: nil, bundle: nil,
            keyboard: defaultControls(keyboard, keyNames: keyNames))
        
        opQueue.maxConcurrentOperationCount = 1
        opQueue.qualityOfService = .UserInteractive
        loadZHFST()
    }
    
    /*
    override func didReceiveMemoryWarning(notification: NSNotification) {
        opQueue.cancelAllOperations()
        opQueue.addOperationWithBlock() {
            self.zhfst?.clearSuggestionCache()
        }
    }
    */
    
    func getPrimaryLanguage() -> String? {
        if let ex = NSBundle.mainBundle().infoDictionary!["NSExtension"] {
            if let attrs = ex["NSExtensionAttributes"] as? [String: AnyObject] {
                if let lang = attrs["PrimaryLanguage"] as? String {
                    return lang
                }
            }
        }
        
        return nil
    }
    
    func loadZHFST() {
        NSLog("%@", "Loading speller…")
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            NSLog("%@", "Dispatching request to load speller…")
            
            guard let bundle = NSBundle.mainBundle().pathForResource("dicts", ofType: "bundle") else {
                NSLog("No dict bundle found; ZHFST not loaded.")
                return
            }
            
            guard let lang = self.getPrimaryLanguage() else {
                NSLog("No primary language found for keyboard; ZHFST not loaded.")
                return
            }
            
            let path = "\(bundle)/\(lang).zhfst"
            let zhfst = ZHFSTOSpeller()
            
            do {
                try zhfst.readZhfst(path, tempDir: NSTemporaryDirectory())
            } catch let err as NSError {
                NSLog("%@", err)
                NSLog("ZHFSTOSpeller **not** loaded.")
                return
            }
            
            zhfst.setQueueLimit(3)
            zhfst.setWeightLimit(50)
            
            self.zhfst = zhfst
           
            NSLog("%@", "ZHFSTOSpeller loaded!")
        }
    }
    
    convenience init() {
        // XXX: generatedKeyboard() must be generated! :)
        self.init(keyboard: generatedKeyboard(), keyNames: generatedConfig())
    }
    
    override func createBanner() -> ExtraView? {
        return GiellaBanner(keyboard: self)
    }
    
    override func backspaceDown(sender: KeyboardKey) {
        super.backspaceDown(sender)
        
        updateSuggestions()
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
            banner.mode = .LongPress
            if let keyView = self.lastKey {
                let key = self.layout!.keyForView(keyView)
                let longpresses = key!.longPressForCase(shiftState.uppercase())
                
                if longpresses.count > 0 {
                    banner.updateAlternateKeyList(longpresses)
                }
            }
        }
    }
    
    override func hideLongPress() {
        super.hideLongPress()
        
        if let banner = self.bannerView as? GiellaBanner {
            banner.updateAlternateKeyList([])
        }
    }
}

enum BannerModes {
    case None, LongPress, Suggestion
}

class GiellaBanner: ExtraView {
    
    //var label: UILabel = UILabel()
    var keyboard: GiellaKeyboard?
    var mode: BannerModes = .None
    
    init(keyboard: GiellaKeyboard) {
        self.keyboard = keyboard
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setMode(mode: BannerModes) {
        self.mode = mode;
    }
    
    func handleBtnPress(sender: UIButton) {
        if let kbd = self.keyboard {
            let textDocumentProxy = kbd.textDocumentProxy as UITextDocumentProxy
            
            kbd.hideLongPress()
            
            if (mode == .LongPress) {
                textDocumentProxy.insertText(sender.titleLabel!.text!)
                
                kbd.contextChanged()

            } else if (mode == .Suggestion) {
                kbd.hideLongPress()
                
                guard let beforeContext = textDocumentProxy.documentContextBeforeInput else {
                    return
                }
                
                guard let lastWord = beforeContext.componentsSeparatedByString(" ").last else {
                    return
                }
                
                for _ in 0..<(lastWord.characters.count) {
                    textDocumentProxy.deleteBackward()
                }
                
                textDocumentProxy.insertText(sender.titleLabel!.text!)
                textDocumentProxy.insertText(" ")
            }
            
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
            
            btn.titleLabel!.font = UIFont.systemFontOfSize(18)
            btn.titleLabel!.numberOfLines = 1
            //btn.titleLabel!.adjustsFontSizeToFitWidth = true
            btn.titleLabel!.lineBreakMode = .ByTruncatingHead
            //btn.titleLabel!.lineBreakMode = .ByClipping
            btn.titleLabel!.baselineAdjustment = .AlignCenters
            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            
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

