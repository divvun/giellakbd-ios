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
    weak var kbd: GiellaKeyboard?
    
    init (kbd: GiellaKeyboard, word: String) {
        self.kbd = kbd
        self.word = word
    }
    
    override func main() {
        if (cancelled) {
            return
        }
        
        let suggestions = self.kbd?.zhfst?.suggest(word).prefix(3).map({ (pair) in
            return pair.first as! String
        })
        
        dispatch_async(dispatch_get_main_queue()) {
            if let suggestions = suggestions {
                if let banner = self.kbd?.bannerView as? GiellaBanner {
                    banner.mode = .Suggestion
                    banner.updateList(suggestions);
                }
            }
        }
    }
}

class GiellaKeyboard: KeyboardViewController {
    var keyNames: [String: String]
    
    var zhfst: ZHFSTOSpeller?
    
    let opQueue = NSOperationQueue()
    
    func getCurrentWord() -> String {
        let documentProxy = self.textDocumentProxy as UITextDocumentProxy
        
        guard let beforeContext = documentProxy.documentContextBeforeInput else {
            return ""
        }
        
        guard let lastWord = beforeContext.componentsSeparatedByString(" ").last else {
            return ""
        }
        
        return lastWord
    }
    
    func updateSuggestions() {
        guard let banner = self.bannerView as? GiellaBanner else {
            return
        }
        
        let lastWord = getCurrentWord()
        
        if lastWord == "" {
            banner.updateList([])
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
                    banner.updateList(longpresses)
                }
            }
        }
    }
    
    override func hideLongPress() {
        super.hideLongPress()
        
        if let banner = self.bannerView as? GiellaBanner {
            banner.updateList([])
        }
    }
}

enum BannerModes {
    case None, LongPress, Suggestion
}

class GiellaBanner: ExtraView {
    var keyboard: GiellaKeyboard
    var mode: BannerModes = .Suggestion
    
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
        let kbd = self.keyboard
        let textDocumentProxy = kbd.textDocumentProxy as UITextDocumentProxy
        
        var text = sender.titleLabel?.text ?? ""
        
        if text == "" {
            return // Do nothing!
        }
        
        kbd.hideLongPress()

        if mode == .LongPress {
            textDocumentProxy.insertText(text)

        } else if (mode == .Suggestion) {
            kbd.hideLongPress()
            
            let lastWord = keyboard.getCurrentWord()
            
            for _ in 0..<(lastWord.characters.count) {
                textDocumentProxy.deleteBackward()
            }
            
            if text.hasPrefix("\"") && text.hasSuffix("\"") {
                text = text[text.startIndex.advancedBy(1)...text.endIndex.advancedBy(-2)]
            }
            
            textDocumentProxy.insertText(text)
            textDocumentProxy.insertText(" ")
        }
        
        kbd.contextChanged()
        
        if kbd.shiftState == ShiftState.Enabled {
            kbd.shiftState = ShiftState.Disabled
        }
        
        kbd.setCapsIfNeeded()
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
    
    func buttonHighlight(sender: UIButton) {
        sender.backgroundColor = UIColor(red: 235.0/255.0, green: 237.0/255.0, blue: 239.0/255.0, alpha: 1.0)
    }
    
    func buttonNormal(sender: UIButton) {
        sender.backgroundColor = UIColor(red: 187.0/255.0, green: 194.0/255.0, blue: 201.0/255.0, alpha: 1.0)
    }
    
    func updateList(keys: [String]) {
        let sv = self.subviews
        
        for v in sv {
            v.removeFromSuperview()
        }
        
        var mutKeys = keys
        
        if mode == .Suggestion {
            if mutKeys.count < 3 && keyboard.getCurrentWord() != "" {
                let k = "\"\(keyboard.getCurrentWord())\""
                if mutKeys.count == 0 {
                    mutKeys.append(k)
                } else {
                    mutKeys.insert(k, atIndex: 0)
                }
            }
        }
        // If still less than 3!
        while mutKeys.count < 3 {
            mutKeys.append("")
        }
        
        for char in mutKeys {
            let btn = UIButton(type: .Custom)
            //let btn: UIButton = UIButton(type: UIButtonType.System) as UIButton
            
            btn.frame = CGRectMake(0, 0, 20, 20)
            btn.setTitle(char, forState: .Normal)
            btn.sizeToFit()
            
            if let titleLabel = btn.titleLabel {
                titleLabel.font = UIFont.systemFontOfSize(18)
                titleLabel.numberOfLines = 1
                titleLabel.lineBreakMode = .ByTruncatingHead
                titleLabel.baselineAdjustment = .AlignCenters
            }
            
            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            
            btn.translatesAutoresizingMaskIntoConstraints = false
            buttonNormal(btn)
            
            btn.setTitleColor(UIColor(white: 1.0, alpha: 1.0), forState: .Normal)
            btn.setTitleColor(UIColor.blackColor(), forState: .Highlighted)
            
            btn.setContentHuggingPriority(1000, forAxis: .Horizontal)
            btn.setContentCompressionResistancePriority(1000, forAxis: .Horizontal)
            
            for event in [UIControlEvents.TouchDragOutside, .TouchDragExit, .TouchCancel, .TouchUpInside, .TouchUpOutside] {
                btn.addTarget(self, action: Selector("buttonNormal:"), forControlEvents: event)
            }
            
            for event in [UIControlEvents.TouchDragInside, .TouchDragEnter, .TouchDown, .TouchDragInside] {
                btn.addTarget(self, action: Selector("buttonHighlight:"), forControlEvents: event)
            }
            
            btn.addTarget(self, action: Selector("handleBtnPress:"), forControlEvents: .TouchUpInside)

            self.addSubview(btn)
        }
        
        let firstBtn = self.subviews[0] as! UIButton
        let lastN = mutKeys.count-1
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

