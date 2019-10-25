import Sentry
import UIKit
import UIDeviceComplete
import AVFoundation

protocol KeyboardViewProvider {
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

private let almostRequiredPriority = UILayoutPriority(rawValue: 1.0)

extension NSLayoutConstraint {
    @discardableResult
    func enable(priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        if let priority = priority {
            self.priority = priority
        }
        self.isActive = true
        return self
    }
}

fileprivate let portraitDeviceHeight: CGFloat = {
    let size = UIScreen.main.bounds.size
    return max(size.height, size.width)
}()

fileprivate let landscapeDeviceHeight: CGFloat = {
    let size = UIScreen.main.bounds.size
    return min(size.height, size.width)
}()

open class KeyboardViewController: UIInputViewController {
    @IBOutlet var nextKeyboardButton: UIButton!
    private var keyboardView: KeyboardViewProvider!
    
    private var landscapeHeight: CGFloat {
        let height = landscapeDeviceHeight
        
        switch UIDevice.current.dc.deviceFamily {
        default:
            return height / 2.0 - 55
        }
    }
    
    private var portraitHeight: CGFloat {
        let height = portraitDeviceHeight
        let sizeInches = UIDevice.current.dc.screenSize.sizeInches ?? 0
        
        switch UIDevice.current.dc.deviceFamily {
        case .iPad:
            // Smol iPads and 9 inch iPad Pro
            if sizeInches < 10 {
                return 314.0
            }
            
            // iPads from 10 to 13 inches
            if sizeInches < 13 {
                return 384.0
            }
            
            return height / 4.0
        case .iPhone, .iPod:
            switch UIDevice.current.dc.deviceModel {
            case .iPhone5S, .iPhone5C:
                return 254.0
            case .iPhone6, .iPhone6S, .iPhone6Plus, .iPhone6SPlus, .iPhone7, .iPhone7Plus:
                return 260.0
            case .iPhone8:
                return 260.0
            case .iPhone8Plus, .iPhoneX, .iPhoneXR, .iPhoneXS, .iPhone11, .iPhone11Pro, .iPhone11ProMax:
                return 272.0
            case .iPhoneXSMax:
                return 272.0
            default:
                break
            }
            return 254.0
        default:
            return height / 3.0
        }
    }

    private var heightConstraint: NSLayoutConstraint!
    private var extraSpacingView: UIView!
    private var deadKeyHandler: DeadKeyHandler!
    public private(set) var bannerView: BannerView!
    public private(set) var keyboardDefinition: KeyboardDefinition!

    var keyboardMode: KeyboardMode = .normal {
        didSet {
            KeyboardView.theme = textDocumentProxy.keyboardAppearance == UIKeyboardAppearance.dark ? DarkTheme : LightTheme

//            setupKeyboardView()
//            keyboardDidReset()
        }
    }

    var LightTheme: Theme {
        return keyboardMode == .normal && UIDevice.current.dc.deviceFamily == .iPad
            ? LightThemeIpadImpl()
            : LightThemeImpl()
    }
    
    var DarkTheme: Theme {
        return self.keyboardMode == .normal && UIDevice.current.dc.deviceFamily == .iPad
            ? DarkThemeIpadImpl()
            : DarkThemeImpl()
    }
    
    private var isSoundEnabled = KeyboardSettings.isKeySoundEnabled
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // This could have changed, so we hook here.
        isSoundEnabled = KeyboardSettings.isKeySoundEnabled
        
        DispatchQueue.main.async {
            self.updateHeightConstraint()
        }
    }
    
    private var isDeviceLandscape: Bool {
        let s = UIScreen.main.bounds.size
        return s.width > s.height
    }
    
    private func initHeightConstraint() {
        let c: NSLayoutConstraint
        if isDeviceLandscape {
            c = view.heightAnchor.constraint(equalToConstant: landscapeHeight)
        } else {
            c = view.heightAnchor.constraint(equalToConstant: portraitHeight)
        }
        heightConstraint = c.enable(priority: .required)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        guard let kbdIndex = Bundle.main.infoDictionary?["DivvunKeyboardIndex"] as? Int else {
            fatalError("There was no DivvunKeyboardIndex")
        }
        keyboardDefinition = KeyboardDefinition.definitions[kbdIndex]
        deadKeyHandler = DeadKeyHandler(keyboard: keyboardDefinition)

        inputView?.allowsSelfSizing = true
        setupKeyboardView()
        setupBannerView()
        
        print("\(KeyboardDefinition.definitions.map { $0.locale + " " })")
    }

    private func setupKeyboardView() {
        if keyboardView != nil {
            keyboardView.remove()
            keyboardView = nil
        }
        switch keyboardMode {
        case .split:
            let splitKeyboardView = SplitKeyboardView(definition: keyboardDefinition)

            view.addSubview(splitKeyboardView.leftKeyboardView)
            view.addSubview(splitKeyboardView.rightKeyboardView)

            splitKeyboardView.leftKeyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            splitKeyboardView.leftKeyboardView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            splitKeyboardView.leftKeyboardView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.25).isActive = true

            splitKeyboardView.rightKeyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            splitKeyboardView.rightKeyboardView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.25).isActive = true
            splitKeyboardView.rightKeyboardView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true

            splitKeyboardView.rightKeyboardView.topAnchor.constraint(equalTo: splitKeyboardView.leftKeyboardView.topAnchor).isActive = true
            splitKeyboardView.rightKeyboardView.heightAnchor.constraint(equalTo: splitKeyboardView.leftKeyboardView.heightAnchor).isActive = true

            splitKeyboardView.delegate = self

            self.keyboardView = splitKeyboardView

        case .left:
            let keyboardView = KeyboardView(definition: keyboardDefinition)
            keyboardView.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(keyboardView)

            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            keyboardView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            keyboardView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true

            keyboardView.delegate = self

            self.keyboardView = keyboardView

        case .right:
            let keyboardView = KeyboardView(definition: keyboardDefinition)
            keyboardView.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(keyboardView)

            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            keyboardView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            keyboardView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true

            keyboardView.delegate = self

            self.keyboardView = keyboardView

        default:
            let keyboardView = KeyboardView(definition: keyboardDefinition)
            keyboardView.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(keyboardView)

            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            keyboardView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            keyboardView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true

            keyboardView.delegate = self

            self.keyboardView = keyboardView
        }
        if bannerView != nil {
            bannerView.bottomAnchor.constraint(equalTo: keyboardView.topAnchor).isActive = true
        }
    }

    private func setupBannerView() {
        extraSpacingView = UIView(frame: .zero)
        extraSpacingView.backgroundColor = UIColor.orange
        extraSpacingView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(extraSpacingView, at: 0)
        extraSpacingView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        extraSpacingView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        extraSpacingView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true

        bannerView = BannerView(frame: .zero)
        bannerView.translatesAutoresizingMaskIntoConstraints = false

        view.insertSubview(bannerView, at: 0)

        bannerView.heightAnchor.constraint(equalToConstant: KeyboardView.theme.bannerHeight).isActive = true
        bannerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        bannerView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true

        bannerView.bottomAnchor.constraint(equalTo: keyboardView.topAnchor).isActive = true
        bannerView.topAnchor.constraint(equalTo: extraSpacingView.bottomAnchor).isActive = true

        bannerView.isHidden = false
    }

    private func updateHeightConstraint() {
        guard let _ = self.heightConstraint else { return }
        
        DispatchQueue.main.async {
            var value = self.bannerVisible ? KeyboardView.theme.bannerHeight : 0
            
            if !self.isDeviceLandscape {
                print("Portrait")
                value += self.portraitHeight
            } else {
                print("Landscape")
                value += self.landscapeHeight
            }
            
            self.heightConstraint.constant = value
        }
    }

    private var isFirstRun = true
    open override func viewDidLayoutSubviews() {
        if isFirstRun {
            isFirstRun = false
            initHeightConstraint()
        }

        super.viewDidLayoutSubviews()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        KeyboardView.theme = textDocumentProxy.keyboardAppearance == UIKeyboardAppearance.dark ? DarkTheme : LightTheme
    }
    
    private var application: UIApplication? {
        var responder: UIResponder? = self
        while responder != nil {
            if let app = responder as? UIApplication {
                return app
            }
            responder = responder?.next
        }
        return nil
    }

    func keyboardDidReset() {
//        updateHeightConstraint()
        
//            KeyboardView.theme = (self.textDocumentProxy.keyboardAppearance == UIKeyboardAppearance.dark)
//                ? self.DarkTheme
//                : self.LightTheme
//
//            self.keyboardView.update()
//            self.bannerView.update()
        self.disablesDelayingGestureRecognizers = true

        self.view.backgroundColor = KeyboardView.theme.backgroundColor
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        disablesDelayingGestureRecognizers = false
    }

    var bannerVisible: Bool {
        set {
            bannerView.isHidden = !newValue
            updateHeightConstraint()
        }

        get {
            return !bannerView.isHidden
        }
    }

    private func propagateTextInputUpdateToBanner() {
        let proxy = textDocumentProxy
        if let bannerView = bannerView {
            bannerView.delegate?.textInputDidChange(bannerView, context: CursorContext.from(proxy: proxy))
        }
    }

    func replaceSelected(with input: String) {
        let ctx = CursorContext.from(proxy: textDocumentProxy)
        textDocumentProxy.adjustTextPosition(byCharacterOffset: ctx.currentWord.count - ctx.currentOffset)

        for _ in 0 ..< ctx.currentWord.count {
            deleteBackward()
        }
        insertText(input)
    }
    
    private var lastInput: String = ""

    func insertText(_ input: String) {
        let proxy = textDocumentProxy
        proxy.insertText(input)
        
        if lastInput != " " && input == " " {
            handleAutoFullStop()
            lastInput = ""
        } else {
            lastInput = input
        }
        
        updateInputState()
    }

    private func deleteBackward() {
        let proxy = textDocumentProxy
        proxy.deleteBackward()
        updateInputState()
    }

    open override func textWillChange(_: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }

    private func updateCapitalization() {
        let proxy = textDocumentProxy
        let ctx = CursorContext.from(proxy: textDocumentProxy)
        
        guard let page = keyboardView?.page else {
            return
        }
        
        switch page {
        case .symbols1, .symbols2:
            keyboardView.page = .normal
            return
        default:
            break
        }
        
        if let autoCapitalizationType = proxy.autocapitalizationType {
            switch autoCapitalizationType {
            case .words:
                if ctx.currentWord == "" {
                    keyboardView.page = .shifted
                }
            case .sentences:
                if ctx.currentWord == "", ctx.previousWord?.last == Character(".") || ctx.previousWord == nil {
                    keyboardView.page = .shifted
                } else if case .shifted = page {
                    if !(ctx.previousWord?.last?.isUppercase ?? false) {
                        keyboardView.page = .normal
                    }
                }
            case .allCharacters:
                keyboardView.page = .shifted
            default:
                break
            }
        }
    }
    
    private func handleAutoFullStop() {
        let proxy = textDocumentProxy
        
        if let text = proxy.documentContextBeforeInput?.suffix(3), text.count == 3 && text.suffix(2) == "  " {
            let first = text.prefix(1)
            
            if first != "." && first != " " {
                proxy.deleteBackward()
                proxy.deleteBackward()
                proxy.insertText(". ")
            }
        }
    }
    
    private func updateInputState() {
        propagateTextInputUpdateToBanner()
        updateCapitalization()
    }

    open override func textDidChange(_: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.

        updateInputState()
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

private let clickSound: SystemSoundID = 1123
private let deleteSound: SystemSoundID = 1155
private let modifierSound: SystemSoundID = 1156
private let fallbackSound: SystemSoundID = 1104

extension KeyboardViewController: KeyboardViewDelegate {
    func didMoveCursor(_ movement: Int) {
        textDocumentProxy.adjustTextPosition(byCharacterOffset: movement)
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
    
    private func handleDeadKey(string: String, endShifted: Bool = true) {
        switch deadKeyHandler.handleInput(string, page: keyboardView.page) {
        case .none:
            insertText(string)
        case .transforming:
            // Do nothing for now
            break
        case let .output(value):
            insertText(value)
        }
        
        if endShifted {
            if keyboardView.page == .shifted {
                keyboardView.page = .normal
            }
        }
    }
    
    private func playSound(_ key: KeyDefinition) {
        if !isSoundEnabled {
            return
        }
        
        var sound: SystemSoundID? = nil
        
        switch key.type {
        case .input(_), .comma, .fullStop, .tab:
            sound = clickSound
        case .caps, .keyboard, .keyboardMode, .shift, .shiftSymbols, .symbols, .spacebar, .returnkey:
            sound = modifierSound
        case .backspace:
            sound = deleteSound
        default:
            return
        }
        
        if #available(iOS 10.0, *) {
            // Nothing
        } else if sound != nil {
            sound = fallbackSound
        }
        
        DispatchQueue.global().async {
            if let sound = sound {
                AudioServicesPlaySystemSound(sound)
            }
        }
    }
    
    func didSwipeKey(_ key: KeyDefinition) {
        switch key.type {
        case let .input(_, alt):
            if let alt = alt {
                handleDeadKey(string: alt)
            }
        default:
            break
        }
    }

    func didTriggerKey(_ key: KeyDefinition) {
        playSound(key)
        
        switch key.type {
        case .comma:
            handleDeadKey(string: ",")
        case .fullStop:
            handleDeadKey(string: ".")
        case .tab:
            break
//            textDocumentProxy.
        case let .input(string, _):
            handleDeadKey(string: string)
        case .spacer:
            // TODO: hit most approximate key instead!
            break
        case .shift:
            keyboardView.page = (keyboardView.page == .normal ? .shifted : .normal)
        case .caps:
            keyboardView.page = (keyboardView.page == .capslock ? .normal : .capslock)
        case .backspace:
            if let value = deadKeyHandler.finish() {
                insertText(value)
            }
            deleteBackward()
        case .spacebar:
            handleDeadKey(string: " ", endShifted: false)
        case .returnkey:
            if let value = deadKeyHandler.finish() {
                insertText(value)
            }
            insertText("\n")
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
            dismissKeyboard()
        }
    }
}

extension KeyboardViewController: KeyboardViewKeyboardKeyDelegate {
    func didTriggerKeyboardButton(sender: UIView, forEvent event: UIEvent) {
        if #available(iOSApplicationExtension 10.0, *) {
            self.handleInputModeList(from: sender, with: event)
        } else {
            advanceToNextInputMode()
        }
    }
}
