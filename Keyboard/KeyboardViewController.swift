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

protocol KeyboardViewProvider {
    var swipeDownKeysEnabled: Bool { get set }
    
    var delegate: (KeyboardViewDelegate & KeyboardViewKeyboardKeyDelegate)? { get set }
    
    var page: BaseKeyboard.KeyboardPage { get set }
    
    func updateTheme(theme: Theme)
    
    func update()
    
    var topAnchor: NSLayoutYAxisAnchor { get }
    var heightAnchor: NSLayoutDimension { get }
    
    init(definition: KeyboardDefinition)
    
    func remove()
}

enum KeyboardMode {
    case normal
    case split
    case left
    case right
}

open class KeyboardViewController: UIInputViewController {
    @IBOutlet var nextKeyboardButton: UIButton!
    private var keyboardView: KeyboardViewProvider!
    
    // Gets updated to match device in viewDidAppear
    private var defaultHeightForDevice: CGFloat {
        return UIDevice.current.kind == .iPad ? 688.0/2.0 : 428.0/2.0
    }
    private var heightConstraint: NSLayoutConstraint!
    private let bannerHeight: CGFloat = 55.0
    private var extraSpacingView: UIView!
    private var deadKeyHandler: DeadKeyHandler!
    private(set) public var bannerView: BannerView!
    private(set) public var keyboardDefinition: KeyboardDefinition!
    
    var keyboardMode: KeyboardMode = .normal {
        didSet {
            KeyboardView.theme = self.textDocumentProxy.keyboardAppearance == UIKeyboardAppearance.dark ? DarkTheme : LightTheme

            setupKeyboardView()

            keyboardDidReset()
        }
    }
    
    var LightTheme: Theme { return self.keyboardMode == .normal && UIDevice.current.kind == UIDevice.Kind.iPad ? LightThemeIpadImpl() : LightThemeImpl() }
    var DarkTheme: Theme { return self.keyboardMode == .normal && UIDevice.current.kind == UIDevice.Kind.iPad ? DarkThemeIpadImpl() : DarkThemeImpl() }

    override open func viewDidLoad() {
        super.viewDidLoad()
        
        guard let kbdIndex = Bundle.main.infoDictionary?["DivvunKeyboardIndex"] as? Int else {
            fatalError("There was no DivvunKeyboardIndex")
        }
        keyboardDefinition = KeyboardDefinition.definitions[kbdIndex]
        deadKeyHandler = DeadKeyHandler(keyboard: keyboardDefinition)
        
        self.inputView?.allowsSelfSizing = true
        setupKeyboardView()
        setupBannerView()
        
        print("\(KeyboardDefinition.definitions.map { $0.internalName + " " })")
    }
    
    private func setupKeyboardView() {
        if keyboardView != nil {
            keyboardView.remove()
            keyboardView = nil
        }
        switch keyboardMode {
        case .split:
            let splitKeyboardView = SplitKeyboardView(definition: keyboardDefinition)
            
            self.view.addSubview(splitKeyboardView.leftKeyboardView)
            self.view.addSubview(splitKeyboardView.rightKeyboardView)
            
            splitKeyboardView.leftKeyboardView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            splitKeyboardView.leftKeyboardView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            splitKeyboardView.leftKeyboardView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.25).isActive = true
            
            splitKeyboardView.rightKeyboardView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            splitKeyboardView.rightKeyboardView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.25).isActive = true
            splitKeyboardView.rightKeyboardView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
            
            splitKeyboardView.rightKeyboardView.topAnchor.constraint(equalTo: splitKeyboardView.leftKeyboardView.topAnchor).isActive = true
            splitKeyboardView.rightKeyboardView.heightAnchor.constraint(equalTo: splitKeyboardView.leftKeyboardView.heightAnchor).isActive = true
            
            splitKeyboardView.delegate = self
            
            self.keyboardView = splitKeyboardView

        case .left:
            let keyboardView = KeyboardView(definition: keyboardDefinition)
            keyboardView.translatesAutoresizingMaskIntoConstraints = false
            
            self.view.addSubview(keyboardView)
            
            keyboardView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            keyboardView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            keyboardView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8).isActive = true
            
            keyboardView.delegate = self
            
            self.keyboardView = keyboardView
            
        case .right:
            let keyboardView = KeyboardView(definition: keyboardDefinition)
            keyboardView.translatesAutoresizingMaskIntoConstraints = false
            
            self.view.addSubview(keyboardView)
            
            keyboardView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            keyboardView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
            keyboardView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8).isActive = true
            
            keyboardView.delegate = self
            
            self.keyboardView = keyboardView
            

        default:
            let keyboardView = KeyboardView(definition: keyboardDefinition)
            keyboardView.translatesAutoresizingMaskIntoConstraints = false
            
            self.view.addSubview(keyboardView)
            
            keyboardView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            keyboardView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            keyboardView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
            
            keyboardView.delegate = self
            
            self.keyboardView = keyboardView
        }
        if bannerView != nil {
            self.bannerView.bottomAnchor.constraint(equalTo: self.keyboardView.topAnchor).isActive = true
        }
    }
    
    private func setupBannerView() {
        self.extraSpacingView = UIView(frame: .zero)
        self.extraSpacingView.backgroundColor = UIColor.orange
        self.extraSpacingView.translatesAutoresizingMaskIntoConstraints = false
        self.view.insertSubview(self.extraSpacingView, at: 0)
        self.extraSpacingView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.extraSpacingView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.extraSpacingView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        
        self.bannerView = BannerView(frame: .zero)
//        self.bannerView.backgroundColor = KeyboardView.theme.bannerBackgroundColor
        self.bannerView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.insertSubview(self.bannerView, at: 0)
        
        self.bannerView.heightAnchor.constraint(equalToConstant: self.bannerHeight).isActive = true
        self.bannerView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.bannerView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        
        self.bannerView.bottomAnchor.constraint(equalTo: self.keyboardView.topAnchor).isActive = true
        self.bannerView.topAnchor.constraint(equalTo: self.extraSpacingView.bottomAnchor).isActive = true
        
        self.bannerView.isHidden = false
    }
    
    private func updateHeightConstraint() {
        guard let _ = self.heightConstraint else { return }
        
        self.heightConstraint.constant = bannerVisible ? defaultHeightForDevice + self.bannerHeight : defaultHeightForDevice
    }
    
    override open func viewDidLayoutSubviews() {
        updateHeightConstraint()
        
        super.viewDidLayoutSubviews()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KeyboardView.theme = self.textDocumentProxy.keyboardAppearance == UIKeyboardAppearance.dark ? DarkTheme : LightTheme
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        keyboardDidReset()
    }
    
    func keyboardDidReset() {
        KeyboardView.theme = self.textDocumentProxy.keyboardAppearance == UIKeyboardAppearance.dark ? DarkTheme : LightTheme

        self.heightConstraint = self.view.heightAnchor.constraint(equalToConstant: self.defaultHeightForDevice)
        
        self.heightConstraint.priority = UILayoutPriority.required
        self.heightConstraint.isActive = true
        
        self.keyboardView.heightAnchor.constraint(equalToConstant: self.defaultHeightForDevice).isActive = true
        
        keyboardView.update()
        bannerView.update()
        disablesDelayingGestureRecognizers = true
        
        self.view.backgroundColor = KeyboardView.theme.backgroundColor
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        disablesDelayingGestureRecognizers = false
    }
    
    var bannerVisible: Bool {
        set {
            self.bannerView.isHidden = !newValue
            updateHeightConstraint()
        }
        
        get {
            return !self.bannerView.isHidden
        }
    }
    
    private func propagateTextInputUpdateToBanner() {
        let proxy = self.textDocumentProxy
        if let bannerView = bannerView {
            bannerView.delegate?.textInputDidChange(bannerView, context: CursorContext.from(proxy: proxy))
        }
    }
    
    func replaceSelected(with input: String) {
        let ctx = CursorContext.from(proxy: self.textDocumentProxy)
        self.textDocumentProxy.adjustTextPosition(byCharacterOffset: ctx.currentWord.count - ctx.currentOffset)
        
        for _ in 0..<ctx.currentWord.count {
            self.deleteBackward()
        }
        insertText(input)
    }
    
    func insertText(_ input: String) {
        let proxy = self.textDocumentProxy
        proxy.insertText(input)
        propagateTextInputUpdateToBanner()
        updateCapitalization()
    }
    
    private func deleteBackward() {
        let proxy = self.textDocumentProxy
        proxy.deleteBackward()
        propagateTextInputUpdateToBanner()
        updateCapitalization()
    }
    
    override open func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    private func updateCapitalization() {
        let proxy = self.textDocumentProxy
        let ctx = CursorContext.from(proxy: self.textDocumentProxy)
        if let autoCapitalizationType = proxy.autocapitalizationType {
            switch autoCapitalizationType {
            case .words:
                if ctx.currentWord == "" {
                    self.keyboardView.page = .shifted
                }
            case .sentences:
                if ctx.currentWord == "" && (ctx.previousWord?.last == Character(".") || ctx.previousWord == nil) {
                    self.keyboardView.page = .shifted
                }
            case .allCharacters:
                self.keyboardView.page = .shifted
            default:
                break
            }
        }
    }
    
    override open func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
        
        
        var textColor: UIColor
        let proxy = self.textDocumentProxy
        if proxy.keyboardAppearance == UIKeyboardAppearance.dark {
            textColor = UIColor.white
        } else {
            textColor = UIColor.black
        }
        
        propagateTextInputUpdateToBanner()
        updateCapitalization()
    }
    
    
    // Disable edge swipe gestures
    private var recognizersThatDelayTouches: Set<Int> = Set<Int>()
    private var disablesDelayingGestureRecognizers: Bool = false {
        didSet {
            if disablesDelayingGestureRecognizers {
                if let window = view.window,
                    let recognizers = window.gestureRecognizers {
                    recognizers.forEach { r in
                        r.delaysTouchesBegan = false
                        self.recognizersThatDelayTouches.insert(r.hash)
                    }
                }
            } else {
                if let window = view.window,
                    let recognizers = window.gestureRecognizers {
                    recognizers.filter { self.recognizersThatDelayTouches.contains($0.hash) }.forEach { r in
                        r.delaysTouchesBegan = true
                    }
                }
            }
        }
    }
}

extension KeyboardViewController: KeyboardViewDelegate {
    func didMoveCursor(_ movement: Int) {
        self.textDocumentProxy.adjustTextPosition(byCharacterOffset: movement)
    }
    
    func didTriggerHoldKey(_ key: KeyDefinition) {
        if case .backspace = key.type {
            self.deleteBackward()
        }
    }
    
    func didTriggerDoubleTap(forKey key: KeyDefinition) {
        if case .shift = key.type {
            keyboardView.page = (keyboardView.page == .capslock ? .normal : .capslock)
        } else if key.type.supportsDoubleTap {
            didTriggerKey(key)
        }
    }
    
    func didTriggerKey(_ key: KeyDefinition) {
        switch key.type {
        case .input(let string):
            switch deadKeyHandler.handleInput(string, page: keyboardView.page) {
            case .none:
                self.insertText(string)
            case .transforming:
                // Do nothing for now
                break
            case let .output(value):
                self.insertText(value)
            }
            
            if keyboardView.page == .shifted {
                keyboardView.page = .normal
            }
        case .spacer:
            break
        case .shift:
            keyboardView.page = (keyboardView.page == .normal ? .shifted : .normal)
        case .backspace:
            if let value = deadKeyHandler.finish() {
                self.insertText(value)
            }
            self.deleteBackward()
        case .spacebar:
            switch deadKeyHandler.handleInput(" ", page: keyboardView.page) {
            case .none:
                self.insertText(" ")
            case .transforming:
                // Do nothing for now
                break
            case let .output(value):
                self.insertText(value)
            }
        case .returnkey:
            if let value = deadKeyHandler.finish() {
                self.insertText(value)
            }
            self.insertText("\n")
        case .symbols:
            keyboardView.page = (keyboardView.page == .symbols1 || keyboardView.page == .symbols2 ? .normal : .symbols1)
        case .shiftSymbols:
            keyboardView.page = (keyboardView.page == .symbols1 ? .symbols2 : .symbols1)
        case .keyboard:
            break
        case .splitKeyboard:
            keyboardMode = keyboardMode == .split ? .normal : .split
        case .sideKeyboardLeft:
            keyboardMode = keyboardMode == .left ? .normal : .left
        case .sideKeyboardRight:
            keyboardMode = keyboardMode == .right ? .normal : .right
        case .keyboardMode:
            self.dismissKeyboard()
        }
    }
}

extension KeyboardViewController: KeyboardViewKeyboardKeyDelegate {
    func didTriggerKeyboardButton(sender: UIView, forEvent event: UIEvent) {
        if #available(iOSApplicationExtension 10.0, *) {
            self.handleInputModeList(from: sender, with: event)
        } else {
            self.advanceToNextInputMode()
        }
    }
}
