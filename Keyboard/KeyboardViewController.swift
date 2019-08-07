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

/*
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
let kSmallLowercase = "kSmallLowercase"*/

open class KeyboardViewController: UIInputViewController, KeyboardViewDelegate, BannerViewDelegate {
    func didSelectBannerItem(_ item: BannerItem) {
        print("Did select item \(item.title) - \(item.value)")
    }
    
    func didTriggerHoldKey(_ key: KeyDefinition) {
        if case .backspace = key.type {
            self.textDocumentProxy.deleteBackward()
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
            if keyboardView.page == .shifted {
                keyboardView.page = .normal
            }
            self.textDocumentProxy.insertText(string)
            
            if string == "c" {
                bannerVisible = !bannerVisible
                self.bannerView.items = [BannerItem(title: "Number uno", value: 1),BannerItem(title: "Number dos", value: 2),BannerItem(title: "Number tres", value: 3),BannerItem(title: "Number quattro", value: 4)]
            }
        case .spacer:
            break
        case .shift:
            keyboardView.page = (keyboardView.page == .normal ? .shifted : .normal)
        case .backspace:
            self.textDocumentProxy.deleteBackward()
        case .spacebar:
            self.textDocumentProxy.insertText(" ")
        case .returnkey:
            self.textDocumentProxy.insertText("\n")
        case .symbols:
            keyboardView.page = (keyboardView.page == .symbols1 || keyboardView.page == .symbols2 ? .normal : .symbols1)
        case .shiftSymbols:
            keyboardView.page = (keyboardView.page == .symbols1 ? .symbols2 : .symbols1)
        case .keyboard:
            self.advanceToNextInputMode()
        }
    }
    
    
    @IBOutlet var nextKeyboardButton: UIButton!
    var keyboardView: KeyboardView!
    
    override open func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Add custom view sizing constraints here
    }
    
    // Gets updated to match device in viewDidAppear
    var defaultHeightForDevice: CGFloat?
    
    var heightConstraint: NSLayoutConstraint!
    
    let bannerHeight: CGFloat = 55.0
    
    var bannerView: BannerView!
    
    var extraSpacingView: UIView!
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.inputView?.allowsSelfSizing = true
        
        setupKeyboardView()
        setupBannerView()
        
        print("\(KeyboardDefinition.definitions.map { $0.internalName + " " })")
    }
    
    private func setupKeyboardView() {
        keyboardView = KeyboardView(definition: KeyboardDefinition.definitions.first!)
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(keyboardView)
        
        keyboardView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        keyboardView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        keyboardView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        
        keyboardView.delegate = self
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
        self.bannerView.backgroundColor = KeyboardView.theme.bannerBackgroundColor
        self.bannerView.translatesAutoresizingMaskIntoConstraints = false
        self.bannerView.delegate = self
        
        self.view.insertSubview(self.bannerView, at: 0)
        
        self.bannerView.heightAnchor.constraint(equalToConstant: self.bannerHeight).isActive = true
        self.bannerView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.bannerView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        
        self.bannerView.bottomAnchor.constraint(equalTo: self.keyboardView.topAnchor)
        self.bannerView.topAnchor.constraint(equalTo: self.extraSpacingView.bottomAnchor).isActive = true
        
        self.bannerView.isHidden = true
    }
    
    private func updateHeightConstraint() {
        guard let defaultHeightForDevice = self.defaultHeightForDevice else {
            // Too early, device height not available yet
            return
        }
        
        self.heightConstraint.constant = bannerVisible ? defaultHeightForDevice + self.bannerHeight : defaultHeightForDevice
    }
    
    override open func viewDidLayoutSubviews() {
        updateHeightConstraint()
        
        super.viewDidLayoutSubviews()
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        if let _ = self.defaultHeightForDevice {} else {
            self.defaultHeightForDevice = self.view.bounds.height
            
            self.heightConstraint = self.view.heightAnchor.constraint(equalToConstant: self.defaultHeightForDevice!)
            
            self.heightConstraint.priority = UILayoutPriority.required
            self.heightConstraint.isActive = true
            
            self.keyboardView.heightAnchor.constraint(equalToConstant: self.defaultHeightForDevice!).isActive = true
            
            self.bannerVisible = false
        }
        
        keyboardView.update()
        
        disablesDelayingGestureRecognizers = true
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        disablesDelayingGestureRecognizers = false
    }
    
    var bannerVisible: Bool = false {
        didSet {
            self.bannerView.isHidden = !bannerVisible
            updateHeightConstraint()
        }
    }
    
    override open func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
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
