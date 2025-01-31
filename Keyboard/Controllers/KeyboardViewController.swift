import UIKit
import DivvunSpell

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

private let portraitDeviceHeight: CGFloat = {
    let size = UIScreen.main.bounds.size
    return max(size.height, size.width)
}()

private let landscapeDeviceHeight: CGFloat = {
    let size = UIScreen.main.bounds.size
    return min(size.height, size.width)
}()

open class KeyboardViewController: UIInputViewController {
    @IBOutlet var nextKeyboardButton: UIButton!
    private var keyboardContainer: UIView!
    private var keyboardView: KeyboardViewProvider!
    private var bannerContainerView: UIView?
    private var heightConstraint: NSLayoutConstraint!
    private var extraSpacingView: UIView!
    private var deadKeyHandler: DeadKeyHandler!
    public private(set) var keyboardDefinition: KeyboardDefinition!
    private var keyboardMode: KeyboardMode = .normal

    private var bannerManager: BannerManager?

    private var showsBanner = true

    public var page: BaseKeyboard.KeyboardPage {
        keyboardView.page
    }

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

    private var landscapeHeight: CGFloat {
        switch UIDevice.current.dc.deviceFamily {
        case .iPad:
            if self.traitCollection.userInterfaceIdiom == .phone {
                // Hardcode because the device lies about the height
                return portraitHeight - 56
            }

            switch UIDevice.current.dc.deviceModel {
            case .iPadMini2, .iPadMini3, .iPadMini4, .iPadMini5:
                return 400.0
            case .iPadThirdGen, .iPadFourthGen, .iPadFifthGen, .iPadSixthGen, .iPadAir, .iPadAir2, .iPadPro9_7Inch:
                return 353.0
            case .iPadAir3, .iPadPro10_5Inch:
                return 405.0
            case .iPadPro11Inch:
                return 405.0
            case .iPadPro12_9Inch, .iPadPro12_9Inch_SecondGen, .iPadPro12_9Inch_ThirdGen, .iPadPro12_9Inch_FourthGen, .iPadPro12_9Inch_FifthGen, .iPadPro12_9Inch_SixthGen:
                return 426.0
            default:
                let sizeInches = UIDevice.current.dc.screenSize.sizeInches ?? 12.9

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
            if self.traitCollection.userInterfaceIdiom == .phone
                || !traitsAreLogicallyIPad(traitCollection: self.traitCollection) {
                // Hardcode because the device lies about the height
                if sizeInches <= 11 {
                    return 258.0
                } else {
                    return 328.0
                }
            }

            // Smol iPads and 9 inch iPad Pro
            if sizeInches < 12 {
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
        var preferredHeight: CGFloat

        if UIScreen.main.isDeviceLandscape {
            preferredHeight = landscapeHeight
        } else {
            preferredHeight = portraitHeight
        }

        guard let layout = keyboardDefinition.currentDeviceLayout else {
            // this can happen if for instance we're on iPad and there's no iPad layout for this particular keyboard
            return preferredHeight
        }

        // Ordinarily a keyboard has 4 rows, iPad 12 inch+ has 5. Some have more. We calculate for that.
        let rowCount = CGFloat(layout.normal.count)
        let normalRowCount: CGFloat = (UIDevice.current.dc.screenSize.sizeInches ?? 0.0) >= 12.0
            ? 5.0
            : 4.0
        let rowHeight = preferredHeight / normalRowCount
        preferredHeight = rowHeight * rowCount
        
        // Some keyboards are more than 4 rows, and on 9" iPads they take up
        // almost the whole screen in landscape unless we shave off some pixels
        let screenSize = UIDevice.current.dc.screenSize.sizeInches ?? 12
        let isLandscape = UIScreen.main.isDeviceLandscape
        if screenSize < 11 && rowCount > 4 && isLandscape {
            preferredHeight -= 40
        }

        if !bannerVisible {
             preferredHeight -= theme.bannerHeight
        }

        return preferredHeight
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
        setupKeyboard()
    }

    private func setupKeyboard() {
        self.keyboardDefinition = loadKeyboardDefinition()

        guard keyboardDefinition.supportsCurrentDevice else {
            setupKeyboardNotSupportedOnThisDeviceView()
            return
        }

        deadKeyHandler = DeadKeyHandler(keyboard: keyboardDefinition)
        setupKeyboardView(keyboardDefinition, withBanner: showsBanner)
    }

    private func loadKeyboardDefinition() -> KeyboardDefinition {
        let keyboardDefinitions: [KeyboardDefinition]
        let path = Bundle.top.url(forResource: "KeyboardDefinitions", withExtension: "json")!
        do {
            let data = try String(contentsOf: path).data(using: .utf8)!
            let raws = try JSONDecoder().decode([RawKeyboardDefinition].self, from: data)
            keyboardDefinitions = try raws.map { try KeyboardDefinition(fromRaw: $0, traits: self.traitCollection) }
            print("keyboard definition locales: \(keyboardDefinitions.map { $0.locale })")
        } catch {
            fatalError("Error getting keyboard definitions from json file: \(error)")
        }

        let kbdIndex: Int
        if isBeingRunFromTests() {
            kbdIndex = 0
        } else {
            guard let index = Bundle.main.infoDictionary?["DivvunKeyboardIndex"] as? Int else {
                fatalError("There was no DivvunKeyboardIndex")
            }

            if index < 0 || index >= keyboardDefinitions.count {
                fatalError("Invalid kbdIndex: \(index); count: \(keyboardDefinitions.count)")
            }

            kbdIndex = index
        }

        return keyboardDefinitions[kbdIndex]
    }

    private func setupKeyboardNotSupportedOnThisDeviceView() {
        setupKeyboardContainer()

        let notSupportedLabel = UILabel()
        notSupportedLabel.text = String(format: NSLocalizedString("The %@ keyboard is currently not supported on this device.\nYou can submit a request for support with one of the following options:", comment: ""), keyboardDefinition.name)
        notSupportedLabel.textAlignment = .center
        notSupportedLabel.lineBreakMode = .byWordWrapping
        notSupportedLabel.numberOfLines = 0
        notSupportedLabel.font = UIFont.systemFont(ofSize: 20)

        func actionButton(_ title: String, _ action: Selector) -> UIButton {
            let button = UIButton()
            button.backgroundColor = .white
            button.setTitle(title, for: .normal)
            button.setTitleColor(.blue, for: .normal)
            button.sizeToFit()
            let width = button.frame.width
            button.widthAnchor.constraint(equalToConstant: width + 20).enable()
            button.heightAnchor.constraint(equalToConstant: 44).enable()
            button.addTarget(self, action: action, for: .touchUpInside)
            button.layer.cornerRadius = 10
            return button
        }

        let emailButton = actionButton("Email Us", #selector(emailButtonTapped))
        let githubIssueButton = actionButton("Submit GitHub Issue", #selector(githubIssueButtonTapped))

        let vstack = UIStackView(arrangedSubviews: [notSupportedLabel, emailButton, githubIssueButton])
        keyboardContainer.addSubview(vstack)
        vstack.axis = .vertical
        vstack.spacing = 20
        vstack.alignment = .center
        vstack.translatesAutoresizingMaskIntoConstraints = false
        vstack.centerXAnchor.constraint(equalTo: keyboardContainer.centerXAnchor).enable()
        vstack.centerYAnchor.constraint(equalTo: keyboardContainer.centerYAnchor).enable()
        vstack.widthAnchor.constraint(equalTo: keyboardContainer.widthAnchor, multiplier: 0.9).enable()

        if needsInputModeSwitchKey {
            let globeButton = UIButton()
            keyboardContainer.addSubview(globeButton)
            let globeImage = UIImage(named: "globe", in: Bundle.top, compatibleWith: self.traitCollection)
            globeButton.setImage(globeImage, for: .normal)
            globeButton.backgroundColor = .clear
            globeButton.tintColor = theme.textColor
            globeButton.isAccessibilityElement = true
            globeButton.accessibilityLabel = NSLocalizedString("accessibility.nextKeyboard", comment: "")
            globeButton.translatesAutoresizingMaskIntoConstraints = false
            globeButton.bottomAnchor.constraint(equalTo: keyboardContainer.bottomAnchor, constant: -10).enable()
            globeButton.leftAnchor.constraint(equalTo: keyboardContainer.leftAnchor, constant: 10).enable()
            globeButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        }
    }

    private func setupKeyboardView(_ keyboardDefinition: KeyboardDefinition, withBanner: Bool) {
        if keyboardView != nil {
            keyboardView.remove()
            keyboardView = nil
        }

        setupKeyboardContainer()

        switch keyboardMode {
        case .split:
            setupSplitKeyboard(keyboardDefinition)
        case .left, .right:
            setupOneHandedKeyboard(keyboardDefinition, mode: keyboardMode)
        default:
            setupNormalKeyboard(keyboardDefinition)
        }

        if withBanner {
            bannerContainerView = makeBannerContainerView()
            if bannerManager == nil {
                bannerManager = BannerManager(view: bannerContainerView!, theme: theme, delegate: self)
            }
        } else {
            self.keyboardView.topAnchor.constraint(equalTo: keyboardContainer.topAnchor).enable()
        }

        updateCapitalization()
    }

    private func setupKeyboardContainer() {
        guard keyboardContainer == nil else {
            return
        }

        keyboardContainer = UIView()
        keyboardContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboardContainer)
        keyboardContainer.topAnchor.constraint(equalTo: view.topAnchor).enable(priority: .defaultHigh)
        keyboardContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor).enable(priority: .required)
        keyboardContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor).enable(priority: .required)
        keyboardContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor).enable(priority: .required)
    }

    private func setupSplitKeyboard(_ keyboardDefinition: KeyboardDefinition) {
        let splitKeyboard = SplitKeyboardView(definition: keyboardDefinition, theme: theme)

        keyboardContainer.addSubview(splitKeyboard.leftKeyboardView)
        keyboardContainer.addSubview(splitKeyboard.rightKeyboardView)

        let leftWidthMultiplier: CGFloat = 0.3181 // proportion used on native keyboard
        splitKeyboard.leftKeyboardView.bottomAnchor.constraint(equalTo: keyboardContainer.bottomAnchor).enable()
        splitKeyboard.leftKeyboardView.leftAnchor.constraint(equalTo: keyboardContainer.leftAnchor).enable()
        splitKeyboard.leftKeyboardView.widthAnchor.constraint(equalTo: keyboardContainer.widthAnchor,
                                                              multiplier: leftWidthMultiplier).enable()

        let rightWidthMultiplier: CGFloat = 0.3561 // proportion used on native keyboard
        splitKeyboard.rightKeyboardView.bottomAnchor.constraint(equalTo: keyboardContainer.bottomAnchor).enable()
        splitKeyboard.rightKeyboardView.widthAnchor.constraint(equalTo: keyboardContainer.widthAnchor,
                                                               multiplier: rightWidthMultiplier).enable()
        splitKeyboard.rightKeyboardView.rightAnchor.constraint(equalTo: keyboardContainer.rightAnchor).enable()

        splitKeyboard.rightKeyboardView.topAnchor.constraint(equalTo: splitKeyboard.leftKeyboardView.topAnchor).enable()
        splitKeyboard.rightKeyboardView.heightAnchor.constraint(equalTo: splitKeyboard.leftKeyboardView.heightAnchor).enable()

        splitKeyboard.delegate = self

        self.keyboardView = splitKeyboard
    }

    private func setupOneHandedKeyboard(_ keyboardDefinition: KeyboardDefinition, mode: KeyboardMode) {
        guard mode == .left || mode == .right else {
            fatalError("Attemtping to setup one-handed keyboard with invalid KeyboardMode")
        }

        let keyboardView = KeyboardView(definition: keyboardDefinition, theme: theme)
        keyboardView.translatesAutoresizingMaskIntoConstraints = false

        keyboardContainer.addSubview(keyboardView)

        keyboardView.bottomAnchor.constraint(equalTo: keyboardContainer.bottomAnchor).enable()
        keyboardView.widthAnchor.constraint(equalTo: keyboardContainer.widthAnchor, multiplier: 0.8).enable()

        if mode == .left {
            keyboardView.leftAnchor.constraint(equalTo: keyboardContainer.leftAnchor).enable()
        } else if mode == .right {
            keyboardView.rightAnchor.constraint(equalTo: keyboardContainer.rightAnchor).enable()
        }

        keyboardView.delegate = self

        self.keyboardView = keyboardView
    }

    private func setupNormalKeyboard(_ keyboardDefinition: KeyboardDefinition) {
        let keyboardView = KeyboardView(definition: keyboardDefinition, theme: theme)
        keyboardView.translatesAutoresizingMaskIntoConstraints = false

        keyboardContainer.addSubview(keyboardView)

        keyboardView.bottomAnchor.constraint(equalTo: keyboardContainer.bottomAnchor).enable()
        keyboardView.leftAnchor.constraint(equalTo: keyboardContainer.leftAnchor).enable()
        keyboardView.rightAnchor.constraint(equalTo: keyboardContainer.rightAnchor).enable()

        keyboardView.delegate = self

        self.keyboardView = keyboardView
    }

    private func makeBannerContainerView() -> UIView {
        let bannerContainer = UIView()

        bannerContainer.translatesAutoresizingMaskIntoConstraints = false

        keyboardContainer.insertSubview(bannerContainer, at: 0)

        bannerContainer.heightAnchor.constraint(equalToConstant: theme.bannerHeight).enable()
        bannerContainer.leftAnchor.constraint(equalTo: keyboardContainer.leftAnchor).enable()
        bannerContainer.rightAnchor.constraint(equalTo: keyboardContainer.rightAnchor).enable()

        bannerContainer.bottomAnchor.constraint(equalTo: keyboardView.topAnchor).enable()
        bannerContainer.topAnchor.constraint(equalTo: keyboardContainer.topAnchor).enable()

        bannerContainer.isHidden = false

        return bannerContainer
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
            bannerContainerView?.isHidden = !newValue
            updateHeightConstraint()
        }

        get {
            guard let bannerContainer = bannerContainerView else {
                return false
            }
            return bannerContainer.isHidden == false
        }
    }

    private func propagateTextInputUpdateToBanner() {
        if let context = try? CursorContext.from(proxy: textDocumentProxy) {
            bannerManager?.propagateTextInputUpdateToBanners(newContext: context)
        }
    }

    func replaceSelected(with input: String) {
        do {
            let ctx = try CursorContext.from(proxy: textDocumentProxy)
            textDocumentProxy.adjustTextPosition(byCharacterOffset: ctx.current.1.count - Int(ctx.currentOffset))

            for _ in 0 ..< ctx.current.1.count {
                deleteBackward()
            }
            insertText(input)
        } catch let error {
            // Log and run
            print(error)
        }
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

    private let nonCapitalizingPunctuation: [Character] = [",", ":"]

    private func updateCapitalization() {
        let proxy = textDocumentProxy
        let ctx = InputContext.from(proxy: proxy)

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
            let hasNoCurrentWord = ctx.currentWord == ""

            switch autoCapitalizationType {
            case .words:
                if hasNoCurrentWord {
                    keyboardView.page = .shifted
                }
            case .sentences:
                let lastCharacter: Character? = ctx.previousWord?.last
                let hasNoPreviousWord = ctx.previousWord == nil
                var hasFinalPunctuator = false
                if let lastCharacter = lastCharacter {
                    if lastCharacter.isPunctuation && !nonCapitalizingPunctuation.contains(lastCharacter) {
                        hasFinalPunctuator = true
                    }
                }

                if hasNoCurrentWord, hasFinalPunctuator || hasNoPreviousWord {
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
        if traitCollection.userInterfaceIdiom == .pad,
            previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
            setupKeyboard()
            updateHeightConstraint()
        }
    }

    private func checkDarkMode(traits: UITraitCollection) {
        let newTheme = baseTheme.select(traits: traits)

        if theme.appearance != newTheme.appearance {
            theme = newTheme

            updateAfterThemeChange()
            bannerManager?.updateTheme(theme)
            if keyboardView != nil {
                keyboardView.updateTheme(theme: theme)
            }
            if keyboardDefinition.supportsCurrentDevice == false {
                // resetup the keyboard not supported view to update its theme
                setupKeyboardNotSupportedOnThisDeviceView()
            }
        }
    }

    private func checkDarkMode() {
        self.checkDarkMode(traits: self.traitCollection)
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

    // MARK: Actions

    @objc private func emailButtonTapped() {
        let keyboardName = keyboardDefinition.name
        let keyboardLocale = keyboardDefinition.locale
        let deviceName = DeviceVariant.from(traits: self.traitCollection).displayName()

        // TODO: get email dynamically from kbdgen bundle
        let email = Bundle.main.object(forInfoDictionaryKey: "DivvunContactEmail") as? String ?? "feedback@divvun.no"
        let subject = "Request for \(keyboardName) (keyboard-\(keyboardLocale)) on \(deviceName)"
        let body =
        """
        Keyboard: \(keyboardName)
        Repository: https://github.com/giellalt/keyboard-\(keyboardLocale)
        Device: \(deviceName)
        
        Additional notes (optional):
        
        """
        let coded = "mailto:\(email)?subject=\(subject)&body=\(body)"

        guard let escaped = coded.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: escaped) else {
            print("Error creating request email URL")
            return
        }

        URLOpener().aggresivelyOpenURL(url, responder: self)
    }

    @objc private func githubIssueButtonTapped() {
        let deviceName = DeviceVariant.from(traits: self.traitCollection).displayName()
        let repo = "keyboard-\(keyboardDefinition.locale)"
        let coded = "https://github.com/giellalt/\(repo)/issues/new?labels=enhancement&title=Add Support for \(deviceName)&body=Additional notes (optional):\n\n"

        guard let escaped = coded.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: escaped) else {
            print("Error creating request github URL")
            return
        }

        URLOpener().aggresivelyOpenURL(url, responder: self)
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
        var endShifted = endShifted
        switch deadKeyHandler.handleInput(string, page: keyboardView.page) {
        case .none:
            insertText(string)
        case .transforming:
            endShifted = false
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
            handleTab()
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
        case .normalKeyboard:
            updateKeyboardMode(.normal)
        case .splitKeyboard:
            updateKeyboardMode(.split)
        case .sideKeyboardLeft:
            updateKeyboardMode(.left)
        case .sideKeyboardRight:
            updateKeyboardMode(.right)
        case .keyboardMode:
            dismissKeyboard()
        }
    }

    private func updateKeyboardMode(_ keyboardMode: KeyboardMode) {
        self.keyboardMode = keyboardMode
        setupKeyboardView(keyboardDefinition, withBanner: showsBanner)
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

    fileprivate func handleTab() {
        if let value = deadKeyHandler.finish() {
            insertText(value)
        }
        insertText("\t")
    }

}

extension KeyboardViewController: KeyboardViewKeyboardKeyDelegate {
    func didTriggerKeyboardButton(sender: UIView, forEvent event: UIEvent) {
        self.handleInputModeList(from: sender, with: event)
    }
}

extension KeyboardViewController: BannerManagerDelegate {
    func bannerDidProvideInput(banner: Banner, inputText: String) {
        if banner is SpellBanner {
            Audio.playClickSound()
            replaceSelected(with: inputText)

            // If the keyboard is not compounding, we add a space
            if !self.keyboardDefinition.features.contains(.compounding) {
                insertText(" ")
            }
        }
    }
}
