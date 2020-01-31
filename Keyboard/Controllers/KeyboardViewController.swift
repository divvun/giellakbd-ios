import UIKit
import UIDeviceComplete

protocol KeyboardViewProvider {
    var delegate: (KeyboardViewDelegate & KeyboardViewKeyboardKeyDelegate)? { get set }

    var page: BaseKeyboard.KeyboardPage { get set }

    func updateTheme(theme: ThemeType)

    func update()

    var topAnchor: NSLayoutYAxisAnchor { get }
    var heightAnchor: NSLayoutDimension { get }

    init(definition: KeyboardDefinition, theme: ThemeType)

    func remove()
}

enum KeyboardMode {
    case normal
    case split
    case left
    case right
}

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

private let portraitDeviceHeight: CGFloat = {
    let size = UIScreen.main.bounds.size
    return max(size.height, size.width)
}()

private let landscapeDeviceHeight: CGFloat = {
    let size = UIScreen.main.bounds.size
    return min(size.height, size.width)
}()

extension UIScreen {
    var isDeviceLandscape: Bool {
        let size = self.bounds.size
        return size.width > size.height
    }
}

open class KeyboardViewController: UIInputViewController {
    @IBOutlet var nextKeyboardButton: UIButton!
    private var keyboardContainer: UIView!
    private var keyboardView: KeyboardViewProvider!
    private var heightConstraint: NSLayoutConstraint!
    private var extraSpacingView: UIView!
    private var deadKeyHandler: DeadKeyHandler!
    public private(set) var bannerView: BannerView?
    public private(set) var keyboardDefinition: KeyboardDefinition!
    private var keyboardMode: KeyboardMode = .normal

    private var showsBanner = true

    public init(withBanner: Bool) {
        showsBanner = withBanner
        super.init(nibName: nil, bundle: nil)
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private(set) lazy var definitions: [KeyboardDefinition] = {
        let path = Bundle.top.url(forResource: "KeyboardDefinitions", withExtension: "json")!
        // swiftlint:disable force_try
        let data = try! String(contentsOf: path).data(using: .utf8)!
        let raws = try! JSONDecoder().decode([RawKeyboardDefinition].self, from: data)
        return raws.map { try! KeyboardDefinition(fromRaw: $0, traits: self.traitCollection) }
        // swiftlint:enable force_try
    }()

    private var landscapeHeight: CGFloat {
        switch UIDevice.current.dc.deviceFamily {
        case .iPad:
            if self.traitCollection.userInterfaceIdiom == .phone {
                // Hardcode because the device lies about the height
                return portraitHeight - 56
            }

            switch UIDevice.current.dc.deviceModel {
            case .iPadMini2, .iPadMini3, .iPadMini4, .iPadMini5:
                return 405.0
            case .iPadThirdGen, .iPadFourthGen, .iPadFifthGen, .iPadSixthGen, .iPadAir, .iPadAir2, .iPadPro9_7Inch:
                return 405.0
            case .iPadAir3, .iPadPro10_5Inch:
                return 405.0
            case .iPadPro11Inch:
                return 405.0
            case .iPadPro12_9Inch, .iPadPro12_9Inch_SecondGen, .iPadPro12_9Inch_ThirdGen:
                return 405.0
            case .iPadSevenGen:
                return 405.0
            default:
                let sizeInches = UIDevice.current.dc.screenSize.sizeInches ?? Screen.maxSupportedInches

                if sizeInches < 11 {
                    return landscapeDeviceHeight / 2.0
                }

                return landscapeDeviceHeight / 2.0 - 120
            }
        case .iPhone, .iPod:
            switch UIDevice.current.dc.deviceModel {
            case .iPhone5S, .iPhone5C, .iPhoneSE, .iPodTouchSeventhGen:
                return 203.0
            case .iPhone6, .iPhone6S, .iPhone7, .iPhone8:
                return 203.0
            case .iPhone6Plus, .iPhone6SPlus, .iPhone7Plus, .iPhone8Plus:
                return 203.0
            case .iPhone11, .iPhoneXR:
                return 190.0
            case .iPhoneX, .iPhoneXS, .iPhone11Pro:
                return 190.0
            case .iPhoneXSMax, .iPhone11ProMax:
                return 190.0
            default:
                return portraitHeight - 56
            }
        default:
            return portraitHeight - 56
        }
    }

    private var portraitHeight: CGFloat {
        let sizeInches = UIDevice.current.dc.screenSize.sizeInches ?? Screen.maxSupportedInches
        print("Size inches: \(sizeInches)")
        switch UIDevice.current.dc.deviceFamily {
        case .iPad:
            if self.traitCollection.userInterfaceIdiom == .phone {
                // Hardcode because the device lies about the height
                if sizeInches < 11 {
                    return 258.0
                } else {
                    return 328.0
                }
            }

            // Smol iPads and 9 inch iPad Pro
            if sizeInches < 11 {
                return 314.0
            }

            // iPads from 11 to 13 inches
            if sizeInches < 13 {
                return 384.0
            }

            return portraitDeviceHeight / 4.0
        case .iPhone, .iPod:
            // https://iosref.com/res/
            switch UIDevice.current.dc.deviceModel {
            case .iPhone5S, .iPhone5C, .iPhoneSE, .iPodTouchSeventhGen:
                return 254.0
            case .iPhone6, .iPhone6S, .iPhone7, .iPhone8:
                return 262.0
            case .iPhone6Plus, .iPhone6SPlus, .iPhone7Plus, .iPhone8Plus:
                return 272.0
            case .iPhone11, .iPhoneXR:
                return 272.0
            case .iPhoneX, .iPhoneXS, .iPhone11Pro:
                return 262.0
            case .iPhoneXSMax, .iPhone11ProMax:
                return 272.0
            default:
                return 262.0
            }
        default:
            return portraitDeviceHeight / 3.0
        }
    }

    private lazy var baseTheme: _Theme = { Theme(traits: self.traitCollection) }()
    private(set) lazy var theme: ThemeType = {
        baseTheme.select(traits: self.traitCollection)
    }()

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // This could have changed, so we hook here.
        Audio.checkIfSoundEnabled()

        DispatchQueue.main.async {
            self.updateHeightConstraint()
        }
    }

    private var preferredHeight: CGFloat {
        var value: CGFloat

        if UIScreen.main.isDeviceLandscape {
            value = landscapeHeight
        } else {
            value = portraitHeight
        }

        // Ordinarily a keyboard has 4 rows, iPad 12 inch+ has 5. Some have more. We calculate for that.
        let rowCount = CGFloat(keyboardDefinition.normal.count)
        let normalRowCount: CGFloat = (UIDevice.current.dc.screenSize.sizeInches ?? 0.0) >= 12.0
            ? 5.0
            : 4.0
        value = value / normalRowCount * rowCount

        if !bannerVisible {
             value -= theme.bannerHeight
        }

        return value
    }

    private func initHeightConstraint() {
        // If this is removed, iPhone 5s glitches before finding the correct height.
        DispatchQueue.main.async {
            self.heightConstraint = self.keyboardContainer.heightAnchor
                .constraint(equalToConstant: self.preferredHeight)
                .enable(priority: UILayoutPriority(999))
        }
    }

    private func updateHeightConstraint() {
        DispatchQueue.main.async {
            self.heightConstraint?.constant = self.preferredHeight
        }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        guard let kbdIndex = Bundle.main.infoDictionary?["DivvunKeyboardIndex"] as? Int else {
            fatalError("There was no DivvunKeyboardIndex")
        }

        if kbdIndex < 0 || kbdIndex >= definitions.count {
            fatalError("Invalid kbdIndex: \(kbdIndex); count: \(definitions.count)")
        }

        keyboardDefinition = definitions[kbdIndex]
        deadKeyHandler = DeadKeyHandler(keyboard: keyboardDefinition)

        setupKeyboardView(withBanner: showsBanner)

        print("\(definitions.map { $0.locale })")
    }

    private func setupKeyboardContainer() {
        if keyboardContainer != nil {
            keyboardContainer.removeFromSuperview()
            keyboardContainer = nil
        }

        keyboardContainer = UIView()
        keyboardContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboardContainer)
        keyboardContainer.topAnchor.constraint(equalTo: view.topAnchor).enable(priority: .defaultHigh)
        keyboardContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor).enable(priority: .required)
        keyboardContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor).enable(priority: .required)
        keyboardContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor).enable(priority: .required)
    }

    private func setupKeyboardView(withBanner: Bool) {
        if keyboardView != nil {
            keyboardView.remove()
            keyboardView = nil
        }

        setupKeyboardContainer()

        switch keyboardMode {
        case .split:
            setupSplitKeyboard()
        case .left, .right:
            setupOneHandedKeyboard(mode: keyboardMode)
        default:
            setupNormalKeyboard()
        }

        if withBanner {
            setupBannerView()
        } else {
            self.keyboardView.topAnchor.constraint(equalTo: keyboardContainer.topAnchor).enable()
        }
    }

    private func setupSplitKeyboard() {
        let splitKeyboard = SplitKeyboardView(definition: keyboardDefinition, theme: theme)

        keyboardContainer.addSubview(splitKeyboard.leftKeyboardView)
        keyboardContainer.addSubview(splitKeyboard.rightKeyboardView)

        splitKeyboard.leftKeyboardView.bottomAnchor.constraint(equalTo: keyboardContainer.bottomAnchor).isActive = true
        splitKeyboard.leftKeyboardView.leftAnchor.constraint(equalTo: keyboardContainer.leftAnchor).isActive = true
        splitKeyboard.leftKeyboardView.widthAnchor.constraint(equalTo: keyboardContainer.widthAnchor, multiplier: 0.25).isActive = true

        splitKeyboard.rightKeyboardView.bottomAnchor.constraint(equalTo: keyboardContainer.bottomAnchor).enable()
        splitKeyboard.rightKeyboardView.widthAnchor.constraint(equalTo: keyboardContainer.widthAnchor, multiplier: 0.25).enable()
        splitKeyboard.rightKeyboardView.rightAnchor.constraint(equalTo: keyboardContainer.rightAnchor).isActive = true

        splitKeyboard.rightKeyboardView.topAnchor.constraint(equalTo: splitKeyboard.leftKeyboardView.topAnchor).enable()
        splitKeyboard.rightKeyboardView.heightAnchor.constraint(equalTo: splitKeyboard.leftKeyboardView.heightAnchor).enable()

        splitKeyboard.delegate = self

        self.keyboardView = splitKeyboard
    }

    private func setupOneHandedKeyboard(mode: KeyboardMode) {
        guard mode == .left || mode == .right else {
            fatalError("Attemtping to setup one-handed keyboard with invalid KeyboardMode")
        }

        let keyboardView = KeyboardView(definition: keyboardDefinition, theme: theme)
        keyboardView.translatesAutoresizingMaskIntoConstraints = false

        keyboardContainer.addSubview(keyboardView)

        keyboardView.bottomAnchor.constraint(equalTo: keyboardContainer.bottomAnchor).isActive = true
        keyboardView.widthAnchor.constraint(equalTo: keyboardContainer.widthAnchor, multiplier: 0.8).isActive = true

        if mode == .left {
            keyboardView.leftAnchor.constraint(equalTo: keyboardContainer.leftAnchor).isActive = true
        } else if mode == .right {
            keyboardView.rightAnchor.constraint(equalTo: keyboardContainer.rightAnchor).isActive = true
        }

        keyboardView.delegate = self

        self.keyboardView = keyboardView
    }

    private func setupNormalKeyboard() {
        let keyboardView = KeyboardView(definition: keyboardDefinition, theme: theme)
        keyboardView.translatesAutoresizingMaskIntoConstraints = false

        keyboardContainer.addSubview(keyboardView)

        keyboardView.bottomAnchor.constraint(equalTo: keyboardContainer.bottomAnchor).isActive = true
        keyboardView.leftAnchor.constraint(equalTo: keyboardContainer.leftAnchor).isActive = true
        keyboardView.rightAnchor.constraint(equalTo: keyboardContainer.rightAnchor).isActive = true

        keyboardView.delegate = self

        self.keyboardView = keyboardView
    }

    private func setupBannerView() {
        bannerView = BannerView(theme: theme)
        guard let bannerView = bannerView else { fatalError("No banner view found in setupBannerView") }

        bannerView.translatesAutoresizingMaskIntoConstraints = false

        keyboardContainer.insertSubview(bannerView, at: 0)

        bannerView.heightAnchor.constraint(equalToConstant: theme.bannerHeight).isActive = true
        bannerView.leftAnchor.constraint(equalTo: keyboardContainer.leftAnchor).isActive = true
        bannerView.rightAnchor.constraint(equalTo: keyboardContainer.rightAnchor).isActive = true

        bannerView.bottomAnchor.constraint(equalTo: keyboardView.topAnchor).isActive = true
        bannerView.topAnchor.constraint(equalTo: keyboardContainer.topAnchor).isActive = true

        bannerView.isHidden = false
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

        self.disablesDelayingGestureRecognizers = true
        checkDarkMode()
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

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        disablesDelayingGestureRecognizers = false
    }

    var bannerVisible: Bool {
        set {
            bannerView?.isHidden = !newValue
            updateHeightConstraint()
        }

        get {
            guard let bannerView = bannerView else {
                return false
            }
            return bannerView.isHidden == false
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
                let lastCharacter: Character? = ctx.previousWord?.last

                if ctx.currentWord == "",
                    ((lastCharacter?.isPunctuation ?? false) && lastCharacter != ",") || ctx.previousWord == nil {
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

    open override func willTransition(to newCollection: UITraitCollection,
                                      with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.checkDarkMode()
        }, completion: nil)
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        checkDarkMode()
    }

    @available(iOSApplicationExtension 12.0, *)
    private func checkDarkMode(traits: UITraitCollection) {
        let newTheme = baseTheme.select(traits: traits)

        if theme.appearance != newTheme.appearance {
            theme = newTheme

            updateAfterThemeChange()
            bannerView?.updateTheme(theme: theme)
            keyboardView.updateTheme(theme: theme)
        }
    }

    private func checkDarkMode() {
        if #available(iOSApplicationExtension 12.0, *) {
            self.checkDarkMode(traits: self.traitCollection)
        }
    }

    private func updateAfterThemeChange() {
        self.view.backgroundColor = theme.backgroundColor
    }

    private func updateInputState() {
        checkDarkMode()
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
                    recognizers.forEach { recognizer in
                        recognizer.delaysTouchesBegan = false
                        self.recognizersThatDelayTouches.insert(recognizer.hash)
                    }
                }
            } else {
                if let window = view.window,
                    let recognizers = window.gestureRecognizers {
                    recognizers.filter { self.recognizersThatDelayTouches.contains($0.hash) }.forEach { recognizer in
                        recognizer.delaysTouchesBegan = true
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
        switch key.type {
        case .input, .comma, .fullStop, .tab:
            Audio.playClickSound()
        case .caps, .keyboard, .keyboardMode, .shift, .shiftSymbols, .symbols, .spacebar, .returnkey:
            Audio.playModifierSound()
        case .backspace:
            Audio.playDeleteSound()
        default:
            return
        }
    }

    func didSwipeKey(_ key: KeyDefinition) {
        switch key.type {
        case let .input(_, alt):
            if let alt = alt {
                handleDeadKey(string: alt)
            }
        case .fullStop:
            handleDeadKey(string: ":")
        case .comma:
            handleDeadKey(string: ";")
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
            handleBackspace()
        case .spacebar:
            handleSpace()
        case .returnkey:
            handleReturn()
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

    private func handleBackspace() {
        if let value = deadKeyHandler.finish() {
            insertText(value)
        }
        deleteBackward()
    }

    fileprivate func handleSpace() {
        if let page = keyboardView?.page, page == .symbols1 || page == .symbols2 {
            keyboardView.page = .normal
        }
        handleDeadKey(string: " ", endShifted: false)
    }

    fileprivate func handleReturn() {
        if let value = deadKeyHandler.finish() {
            insertText(value)
        }
        insertText("\n")
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
