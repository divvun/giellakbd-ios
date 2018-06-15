//
//  KeyboardViewController.swift
//  Keyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit
import Sentry
import AudioToolbox

let metrics: [String:Double] = [
    "topBanner": 38
]
func metric(_ name: String) -> CGFloat {
    if UIDevice.current.userInterfaceIdiom != UIUserInterfaceIdiom.pad {
        return CGFloat(metrics[name]!)
    } else {
        return CGFloat(metrics[name]!) * 1.4
    }
}

// TODO: move this somewhere else and localize
let kAutoCapitalization = "kAutoCapitalization"
let kPeriodShortcut = "kPeriodShortcut"
let kKeyboardClicks = "kKeyboardClicks"
let kSmallLowercase = "kSmallLowercase"

open class KeyboardViewController: UIInputViewController {
    open override func loadView() {
        if let sentryDSN = Bundle.top.infoDictionary?["SentryDSN"] as? String {
            do {
                Client.shared = try Client(dsn: sentryDSN)
                Client.shared?.tags?["bundle"] = Bundle.main.bundleIdentifier ?? "unknown"
                try Client.shared?.startCrashHandler()
            } catch let error {
                print("\(error)")
                // Wrong DSN or KSCrash not installed
            }
        }
        
        super.loadView()
    }

    let backspaceDelay: TimeInterval = 0.5
    let backspaceRepeat: TimeInterval = 0.07

    var keyboard: Keyboard!
    var forwardingView: ForwardingView!
    var layout: KeyboardLayout? = nil

    var bannerView: ExtraView? = nil
    var settingsView: ExtraView? = nil

    var currentMode: Int = 0 {
        didSet {
            if oldValue != currentMode {
                setMode(currentMode)
            }
        }
    }

    var backspaceActive: Bool {
        get {
            return (backspaceDelayTimer != nil) || (backspaceRepeatTimer != nil)
        }
    }
    var backspaceDelayTimer: Timer? = nil
    var backspaceRepeatTimer: Timer? = nil

    enum AutoPeriodState {
        case noSpace
        case firstSpace
    }

    var autoPeriodState: AutoPeriodState = .noSpace
    var lastCharCountInBeforeContext = 0

    var shiftState: ShiftState = .disabled {
        didSet {
            switch shiftState {
            case .disabled:
                self.updateKeyCaps(false)
            case .enabled:
                self.updateKeyCaps(true)
            case .locked:
                self.updateKeyCaps(true)
            }
        }
    }

    // state tracking during shift tap
    var shiftWasMultitapped: Bool = false
    var shiftStartingState: ShiftState? = nil

    var nameChangeTimer: Timer? = nil

    func configure(with keyboard: Keyboard) {
        UserDefaults.standard.register(defaults: [
            kAutoCapitalization: true,
            kPeriodShortcut: true,
            kKeyboardClicks: false,
            kSmallLowercase: true
        ])

        self.keyboard = keyboard

        self.shiftState = .disabled
        self.currentMode = 0
        
        self.forwardingView = ForwardingView(frame: CGRect.zero)
        self.view.addSubview(self.forwardingView)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(KeyboardViewController.defaultsChanged(_:)),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }
    
    deinit {
        backspaceDelayTimer?.invalidate()
        backspaceRepeatTimer?.invalidate()

        NotificationCenter.default.removeObserver(self)
    }

    @objc func defaultsChanged(_ notification: Notification) {
        _ = notification.object as? UserDefaults
        self.updateKeyCaps(self.shiftState.uppercase())
    }

    func setupLayout() {
        self.layout = KeyboardLayout(
            model: self.keyboard,
            superview: self.forwardingView,
            layoutConstants: LayoutConstants.self, // TODO: why
            darkMode: self.darkMode(),
            solidColorMode: self.solidColorMode()
        )

        self.setMode(0)

        self.updateKeyCaps(self.shiftState.uppercase())
        self.setCapsIfNeeded()

        self.updateAppearances(self.darkMode())
        self.addInputTraitsObservers()
    }

    // only available after frame becomes non-zero
    func darkMode() -> Bool {
        let proxy = self.textDocumentProxy as UITextDocumentProxy
        return proxy.keyboardAppearance == UIKeyboardAppearance.dark
    }

    func solidColorMode() -> Bool {
        return UIAccessibilityIsReduceTransparencyEnabled()
    }

    var lastLayoutBounds: CGRect?
    override open func viewDidLayoutSubviews() {
        if view.bounds == CGRect.zero {
            return
        }

        let orientationSavvyBounds = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.heightForOrientation(self.orientation, withTopBanner: false))

        if (lastLayoutBounds != nil && lastLayoutBounds == orientationSavvyBounds) {
            // do nothing
        }
        else {
            let uppercase = self.shiftState.uppercase()
            let characterUppercase = (UserDefaults.standard.bool(forKey: kSmallLowercase) ? uppercase : true)

            self.forwardingView.frame = orientationSavvyBounds
            self.layout?.layoutKeys(self.currentMode, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
            self.lastLayoutBounds = orientationSavvyBounds
            self.setupKeys()
        }

        self.bannerView?.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: metric("topBanner"))

        let newOrigin = CGPoint(x: 0, y: self.view.bounds.height - self.forwardingView.bounds.height)
        self.forwardingView.frame.origin = newOrigin
    }

    var heightView: UIView?
    override open func viewDidLoad() {
        super.viewDidLoad()

        // iOS refuses to set the keyboards height directly, so this hidden view autolayouts it for us instead
        if heightView == nil {
            let heightView = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 500))
            heightView.backgroundColor = UIColor.clear
            heightView.isUserInteractionEnabled = false
            heightView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(heightView)
            heightView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            heightView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            heightView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            heightView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
            self.heightView = heightView
        }

    }
    
    open override func updateViewConstraints() {
        super.updateViewConstraints()
        
        if (view.frame.size.width == 0 || view.frame.size.height == 0) {
            return
        }

        self.updateHeightConstraint()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.bannerView?.isHidden = false
        
        setupLayout()
        
        view.setNeedsUpdateConstraints()
    }
    
    
    // MARK: Set up height constraint
    func updateHeightConstraint() {
        self.updateHeightConstraint(orientation: self.orientation)
    }
    
    func updateHeightConstraint(orientation: UIInterfaceOrientation) {
        var bannerEnabled = false
        if let bannerView = self.bannerView as? GiellaBanner {
            bannerEnabled = bannerView.mode == .suggestion
        }
        let h = self.heightForOrientation(orientation, withTopBanner: bannerEnabled)
        self.heightView?.heightAnchor.constraint(equalToConstant: h).isActive = true
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.removeConstraints(view.constraints)
    }
    
    var orientation: UIInterfaceOrientation {
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .unknown
        }
    }

    override open func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false

        // optimization: ensures smooth animation
        if let keyPool = self.layout?.keyPool {
            for view in keyPool {
                view.shouldRasterize = true
            }
        }
        
        self.updateHeightConstraint(orientation: toInterfaceOrientation)
    }

    override open func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        // optimization: ensures quick mode and shift transitions
        if let keyPool = self.layout?.keyPool {
            for view in keyPool {
                view.shouldRasterize = false
            }
        }
    }

    func heightForOrientation(_ orientation: UIInterfaceOrientation, withTopBanner: Bool) -> CGFloat {
        let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        let maxHeight = CGFloat(isPad ? 256 : 216)
        
        let screenHeight = UIScreen.main.nativeBounds.size.height / UIScreen.main.nativeScale
        
        let height = screenHeight.truncatingRemainder(dividingBy: 3)
        
        let topBannerHeight = withTopBanner ? metric("topBanner") : 0
        let additionalRowHeight = CGFloat(max(self.keyboard.pages[0].rows.count - 4, 0) * 56)
        
        return CGFloat(max(height, maxHeight) + topBannerHeight + additionalRowHeight)
    }

    /*
    BUG NOTE

    None of the UIContentContainer methods are called for this controller.
    */

    //override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    //    super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    //}

    func localName() -> String? {
        let ext = Bundle.main.infoDictionary?["NSExtension"] as! [String: Any]
        let attrs = ext["NSExtensionAttributes"] as! [String: Any]
        let primaryLanguage = attrs["PrimaryLanguage"] as! String
        
        let locale = Locale(identifier: primaryLanguage)
        var displayName = (locale as NSLocale).displayName(forKey: NSLocale.Key.identifier, value: primaryLanguage)?.capitalized

        if displayName == nil {
            displayName = (Locale.current as NSLocale).displayName(forKey: NSLocale.Key.identifier, value: primaryLanguage)?.capitalized
        }

        if displayName == nil {
            // Fallback to code itself.
            displayName = primaryLanguage
        }

        //keyView.label.text = displayName
        return displayName
    }
    
    var hasChangedSpace = false

    func changeSpaceName(_ keyView: KeyboardKey, completion: @escaping () -> Void) {
        //setSpaceLocalName(keyView)
        
        if hasChangedSpace {
            return
        }
        
        hasChangedSpace = true
        
        keyView.label.alpha = 1

        if let key = layout?.keyForView(keyView) {
            let saved = key.uppercaseKeyCap
            key.uppercaseKeyCap = localName() ?? ""

            UIView.animate(withDuration: 0.3, delay: 1, options: .curveEaseOut, animations: {
                    keyView.label.alpha = 0.0
                }, completion: {
                    (finished: Bool) -> Void in

                    keyView.label.text = saved
                    key.uppercaseKeyCap = saved

                    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
                        keyView.label.alpha = 1.0
                    }, completion: { _ in
                        completion()
                    })
                }
            )

        }
    }

    func setupKeys() {
        if self.layout == nil {
            return
        }

        for page in keyboard.pages {
            for rowKeys in page.rows { // TODO: quick hack
                for key in rowKeys {
                    if let keyView = self.layout?.viewForKey(key) {
                        keyView.removeTarget(nil, action: nil, for: UIControlEvents.allEvents)
                        
                        key.bind(view: keyView, target: self)
                    }
                }
            }
        }
    }

    /////////////////
    // POPUP DELAY //
    /////////////////

    var keyWithDelayedPopup: KeyboardKey?
    var lastKey: KeyboardKey?
    var popupDelayTimer: Timer?
    var longPressTimer: Timer?

    @objc func showPopup(_ sender: KeyboardKey) {
        if longPressTriggered {
            return
        }
        if sender == self.keyWithDelayedPopup {
            self.popupDelayTimer?.invalidate()
        }
        self.longPressTimer?.invalidate()


        if UIDevice.current.userInterfaceIdiom != UIUserInterfaceIdiom.pad {
            sender.showPopup()
        }

        self.lastKey = sender
        self.longPressTimer = Timer.scheduledTimer(timeInterval: 0.35, target: self, selector:
            #selector(KeyboardViewController.showLongPress), userInfo: nil, repeats: false)
    }

    @objc func hidePopupDelay(_ sender: KeyboardKey) {
        self.longPressTimer?.invalidate()

        if UIDevice.current.userInterfaceIdiom != UIUserInterfaceIdiom.pad {
            self.popupDelayTimer?.invalidate()

            if sender != self.keyWithDelayedPopup {
                self.keyWithDelayedPopup?.hidePopup()
                self.keyWithDelayedPopup = sender
            }

            if sender.popup != nil {
                self.popupDelayTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(KeyboardViewController.hidePopupCallback), userInfo: nil, repeats: false)
            }
        }
    }

    var longPressTriggered = false {
        didSet {
            self.forwardingView.longpressEnabled = longPressTriggered
        }
    }

    @objc func showLongPress() {
        if self.lastKey != nil {
            if let key = layout?.keyForView(self.lastKey!) {
                if (shiftState.uppercase() && key.hasUppercaseLongPress) ||
                    (!shiftState.uppercase() && key.hasUppercaseLongPress) {
                        self.longPressTriggered = true;
                        self.forwardingView.longpressedKey = self.lastKey
                }
            }
        }
    }

    @objc func hideLongPress() {
        self.longPressTimer = nil
        self.lastKey = nil
        self.longPressTriggered = false
    }

    @objc func hidePopup(_ sender: KeyboardKey) {
        if UIDevice.current.userInterfaceIdiom != UIUserInterfaceIdiom.pad {
            sender.hidePopup()
        }
        hideLongPress()
    }

    @objc func hidePopupCallback() {
        self.keyWithDelayedPopup?.hidePopup()
        self.keyWithDelayedPopup = nil
        self.popupDelayTimer = nil
    }

    /////////////////////
    // POPUP DELAY END //
    /////////////////////
    
    // TODO: this is currently not working as intended; only called when selection changed -- iOS bug
    override open func textDidChange(_ textInput: UITextInput?) {
        self.contextChanged()
    }

    func contextChanged() {
        self.setCapsIfNeeded()
        self.autoPeriodState = .noSpace
    }

    func updateAppearances(_ appearanceIsDark: Bool) {
        self.layout?.solidColorMode = self.solidColorMode()
        self.layout?.darkMode = appearanceIsDark
        self.layout?.updateKeyAppearance()

        self.bannerView?.darkMode = appearanceIsDark
        self.settingsView?.darkMode = appearanceIsDark
    }

    @objc func highlightKey(_ sender: KeyboardKey) {
        sender.isHighlighted = true
    }

    @objc func unHighlightKey(_ sender: KeyboardKey) {
        sender.isHighlighted = false
    }

    @objc func keyPressedHelper(_ sender: KeyboardKey) {
        if let model = self.layout?.keyForView(sender) {
            if (!self.longPressTriggered) {
                self.keyPressed(model)
            } else {
                self.longPressTriggered = false
                return
            }

            // auto exit from special char subkeyboard
            if model.type == Key.KeyType.space || model.type == Key.KeyType.return {
                self.currentMode = 0
            }
            else if model.lowercaseOutput == "'" {
                self.currentMode = 0
            }
            else if model.type == Key.KeyType.character {
                self.currentMode = 0
            }

            // auto period on double space
            // TODO: timeout

            self.handleAutoPeriod(model)
            // TODO: reset context
        }

        self.setCapsIfNeeded()
    }

    func handleAutoPeriod(_ key: Key) {
        if !UserDefaults.standard.bool(forKey: kPeriodShortcut) {
            return
        }

        if self.autoPeriodState == .firstSpace {
            if key.type != Key.KeyType.space {
                self.autoPeriodState = .noSpace
                return
            }

            let charactersAreInCorrectState = { () -> Bool in
                guard let previousContext = (self.textDocumentProxy as UITextDocumentProxy).documentContextBeforeInput else {
                    return false
                }
                
                if previousContext.count < 3 {
                    return false
                }
                
                var index = previousContext.endIndex
                
                index = previousContext.index(before: index)
                if previousContext[index] != " " {
                    return false
                }
                
                index = previousContext.index(before: index)
                if previousContext[index] != " " {
                    return false
                }
                
                index = previousContext.index(before: index)
                let char = previousContext[index]
                if self.characterIsWhitespace(char) || self.characterIsPunctuation(char) || char == "," {
                    return false
                }
                
                return true
            }()

            if charactersAreInCorrectState {
                let proxy = self.textDocumentProxy as UITextDocumentProxy
                
                proxy.deleteBackward()
                proxy.deleteBackward()
                proxy.insertText(". ")
            }

            self.autoPeriodState = .noSpace
        } else if key.type == Key.KeyType.space {
            self.autoPeriodState = .firstSpace
        }
    }

    func cancelBackspaceTimers() {
        self.backspaceDelayTimer?.invalidate()
        self.backspaceRepeatTimer?.invalidate()
        self.backspaceDelayTimer = nil
        self.backspaceRepeatTimer = nil
    }

    @objc func backspaceDown(_ sender: KeyboardKey) {
        self.cancelBackspaceTimers()

        let textDocumentProxy = self.textDocumentProxy as UIKeyInput
        textDocumentProxy.deleteBackward()
            
        self.setCapsIfNeeded()

        // trigger for subsequent deletes
        self.backspaceDelayTimer = Timer.scheduledTimer(timeInterval: backspaceDelay - backspaceRepeat, target: self, selector: #selector(KeyboardViewController.backspaceDelayCallback), userInfo: nil, repeats: false)
    }

    @objc func backspaceUp(_ sender: KeyboardKey) {
        self.cancelBackspaceTimers()
    }

    @objc func backspaceDelayCallback() {
        self.backspaceDelayTimer = nil
        self.backspaceRepeatTimer = Timer.scheduledTimer(timeInterval: backspaceRepeat, target: self, selector: #selector(KeyboardViewController.backspaceRepeatCallback), userInfo: nil, repeats: true)
    }

    @objc func backspaceRepeatCallback() {
        self.playKeySound()

        let textDocumentProxy = self.textDocumentProxy as UIKeyInput
        textDocumentProxy.deleteBackward()
        
        self.setCapsIfNeeded()
    }

    @objc func shiftDown(_ sender: KeyboardKey) {
        self.shiftStartingState = self.shiftState

        if let shiftStartingState = self.shiftStartingState {
            if shiftStartingState.uppercase() {
                // handled by shiftUp
                return
            }
            else {
                switch self.shiftState {
                case .disabled:
                    self.shiftState = .enabled
                case .enabled:
                    self.shiftState = .disabled
                case .locked:
                    self.shiftState = .disabled
                }

                (sender.shape as? ShiftShape)?.withLock = false
            }
        }
    }

    @objc func shiftUp(_ sender: KeyboardKey) {
        if self.shiftWasMultitapped {
            // do nothing
        }
        else {
            if let shiftStartingState = self.shiftStartingState {
                if !shiftStartingState.uppercase() {
                    // handled by shiftDown
                }
                else {
                    switch self.shiftState {
                    case .disabled:
                        self.shiftState = .enabled
                    case .enabled:
                        self.shiftState = .disabled
                    case .locked:
                        self.shiftState = .disabled
                    }

                    (sender.shape as? ShiftShape)?.withLock = false
                }
            }
        }

        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
    }

    @objc func shiftDoubleTapped(_ sender: KeyboardKey) {
        self.shiftWasMultitapped = true

        switch self.shiftState {
        case .disabled:
            self.shiftState = .locked
        case .enabled:
            self.shiftState = .locked
        case .locked:
            self.shiftState = .disabled
        }
    }

    func updateKeyCaps(_ uppercase: Bool) {
        let characterUppercase = (UserDefaults.standard.bool(forKey: kSmallLowercase) ? uppercase : true)
        self.layout?.updateKeyCaps(false, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
    }

    @objc func modeChangeTapped(_ sender: KeyboardKey) {
        if let toMode = self.layout?.viewToModel[sender]?.toMode {
            self.currentMode = toMode
        }
    }

    @objc func setMode(_ mode: Int) {
        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false

        let uppercase = self.shiftState.uppercase()
        let characterUppercase = (UserDefaults.standard.bool(forKey: kSmallLowercase) ? uppercase : true)
        self.layout?.layoutKeys(mode, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)

        self.setupKeys()
    }

    @objc func advanceTapped(_ sender: KeyboardKey, withEvent event: UIEvent) {
        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
        
        self.advanceToNextInputMode()
        
//        if #available(iOSApplicationExtension 10.0, *) {
//            DispatchQueue.main.async {
//                self.handleInputModeList(from: self.view, with: event)
//            }
//        } else {
//            self.advanceToNextInputMode()
//
//        }
    }

    @IBAction func toggleSettings() {
        // Make Apple leave us alone
        let sel = Selector("open" + "URL" + ":")
        
        var responder: UIResponder? = self
        
        while true {
            responder = responder?.next
            
            guard let res = responder else {
                break
            }
            
            if res.responds(to: sel) {
                res.perform(sel, with: URL(string: "\(KeyboardSettings.groupId)://settings")!)
            }
        }
        
        dismissKeyboard()
    }

    @discardableResult
    func setCapsIfNeeded() -> Bool {
        if self.shouldAutoCapitalize() {
            switch self.shiftState {
            case .disabled:
                self.shiftState = .enabled
            case .enabled:
                self.shiftState = .enabled
            case .locked:
                self.shiftState = .locked
            }

            return true
        }
        else {
            switch self.shiftState {
            case .disabled:
                self.shiftState = .disabled
            case .enabled:
                self.shiftState = .disabled
            case .locked:
                self.shiftState = .locked
            }

            return false
        }
    }

    func characterIsPunctuation(_ character: Character) -> Bool {
        return (character == ".") || (character == "!") || (character == "?")
    }

    func characterIsNewline(_ character: Character) -> Bool {
        return (character == "\n") || (character == "\r")
    }

    func characterIsWhitespace(_ character: Character) -> Bool {
        // there are others, but who cares
        return (character == " ") || (character == "\n") || (character == "\r") || (character == "\t")
    }

    func stringIsWhitespace(_ string: String?) -> Bool {
        if let string = string {
            for char in string {
                if !characterIsWhitespace(char) {
                    return false
                }
            }
        }
        
        return true
    }

    func shouldAutoCapitalize() -> Bool {
        if !UserDefaults.standard.bool(forKey: kAutoCapitalization) {
            return false
        }

        let traits = self.textDocumentProxy as UITextInputTraits
        if let autocapitalization = traits.autocapitalizationType {
            let documentProxy = self.textDocumentProxy as UITextDocumentProxy

            switch autocapitalization {
            case .none:
                return false
            case .words:
                let beforeContext = documentProxy.documentContextBeforeInput ?? ""
                let i = beforeContext.index(before: beforeContext.endIndex)
                let previousCharacter = beforeContext[i]
                return self.characterIsWhitespace(previousCharacter)
            case .sentences:
                let beforeContext = documentProxy.documentContextBeforeInput ?? ""
                let offset = min(3, beforeContext.count)
                var index = beforeContext.endIndex

                for i in 0..<offset {
                    index = beforeContext.index(before: index)
                    let char = beforeContext[index]

                    if characterIsPunctuation(char) {
                        if i == 0 {
                            return false //not enough spaces after punctuation
                        }
                        else {
                            return true //punctuation with at least one space after it
                        }
                    }
                    else {
                        if !characterIsWhitespace(char) {
                            return false //hit a foreign character before getting to 3 spaces
                        }
                        else if characterIsNewline(char) {
                            return true //hit start of line
                        }
                    }
                }

                return true //either got 3 spaces or hit start of line
            case .allCharacters:
                return true
            }
        }
        else {
            return false
        }
    }

    // this only works if full access is enabled
    @objc func playKeySound() {
        if !UserDefaults.standard.bool(forKey: kKeyboardClicks) {
            return
        }
        
        DispatchQueue.main.async {
            UIDevice.current.playInputClick()
        }
    }

    //////////////////////////////////////
    // MOST COMMONLY EXTENDABLE METHODS //
    //////////////////////////////////////

    //static let layoutClass: KeyboardLayout.Type = KeyboardLayout.self
    //static let layoutConstants: LayoutConstants.Type = LayoutConstants.self

    func keyPressed(_ key: Key) {
        let proxy = (self.textDocumentProxy as UIKeyInput)
        
        proxy.insertText(key.outputForCase(self.shiftState.uppercase()))
    }

    // a banner that sits in the empty space on top of the keyboard
    func createBanner() -> ExtraView? {
        return nil
    }
}
