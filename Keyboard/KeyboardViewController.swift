import AudioToolbox
import Sentry
import UIKit

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

open class KeyboardViewController: UIInputViewController {
    @IBOutlet var nextKeyboardButton: UIButton!
    private var keyboardView: KeyboardViewProvider!

    private var defaultHeightForDevice: CGFloat {
        return UIDevice.current.kind == .iPad ? 688.0 / 2.0 : 420.0 / 2.0
    }

    private var heightConstraint: NSLayoutConstraint!
    private let bannerHeight: CGFloat = 55.0
    private var extraSpacingView: UIView!
    private var deadKeyHandler: DeadKeyHandler!
    public private(set) var bannerView: BannerView!
    public private(set) var keyboardDefinition: KeyboardDefinition!

    var keyboardMode: KeyboardMode = .normal {
        didSet {
            KeyboardView.theme = textDocumentProxy.keyboardAppearance == UIKeyboardAppearance.dark ? DarkTheme : LightTheme

            setupKeyboardView()

            keyboardDidReset()
        }
    }

    var LightTheme: Theme { return keyboardMode == .normal && UIDevice.current.kind == UIDevice.Kind.iPad ? LightThemeIpadImpl() : LightThemeImpl() }
    var DarkTheme: Theme { return self.keyboardMode == .normal && UIDevice.current.kind == UIDevice.Kind.iPad ? DarkThemeIpadImpl() : DarkThemeImpl() }

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
        //        self.bannerView.backgroundColor = KeyboardView.theme.bannerBackgroundColor
        bannerView.translatesAutoresizingMaskIntoConstraints = false

        view.insertSubview(bannerView, at: 0)

        bannerView.heightAnchor.constraint(equalToConstant: bannerHeight).isActive = true
        bannerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        bannerView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true

        bannerView.bottomAnchor.constraint(equalTo: keyboardView.topAnchor).isActive = true
        bannerView.topAnchor.constraint(equalTo: extraSpacingView.bottomAnchor).isActive = true

        bannerView.isHidden = false
    }

    private func updateHeightConstraint() {
        guard let _ = self.heightConstraint else { return }

        heightConstraint.constant = bannerVisible ? defaultHeightForDevice + bannerHeight : defaultHeightForDevice
    }

    open override func viewDidLayoutSubviews() {
        updateHeightConstraint()

        super.viewDidLayoutSubviews()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        KeyboardView.theme = textDocumentProxy.keyboardAppearance == UIKeyboardAppearance.dark ? DarkTheme : LightTheme
    }

    open override func viewDidAppear(_: Bool) {
        keyboardDidReset()
    }

    func keyboardDidReset() {
        KeyboardView.theme = textDocumentProxy.keyboardAppearance == UIKeyboardAppearance.dark ? DarkTheme : LightTheme

        heightConstraint = view.heightAnchor.constraint(equalToConstant: defaultHeightForDevice)

        heightConstraint.priority = UILayoutPriority.required
        heightConstraint.isActive = true

        keyboardView.heightAnchor.constraint(equalToConstant: defaultHeightForDevice).isActive = true

        keyboardView.update()
        bannerView.update()
        disablesDelayingGestureRecognizers = true

        view.backgroundColor = KeyboardView.theme.backgroundColor
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

        var textColor: UIColor
        let proxy = textDocumentProxy
        if proxy.keyboardAppearance == UIKeyboardAppearance.dark {
            textColor = UIColor.white
        } else {
            textColor = UIColor.black
        }
        
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

    func didTriggerKey(_ key: KeyDefinition) {
        switch key.type {
        case let .input(string):
            switch deadKeyHandler.handleInput(string, page: keyboardView.page) {
            case .none:
                insertText(string)
            case .transforming:
                // Do nothing for now
                break
            case let .output(value):
                insertText(value)
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
                insertText(value)
            }
            deleteBackward()
        case .spacebar:
            switch deadKeyHandler.handleInput(" ", page: keyboardView.page) {
            case .none:
                insertText(" ")
            case .transforming:
                // Do nothing for now
                break
            case let .output(value):
                insertText(value)
            }
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
