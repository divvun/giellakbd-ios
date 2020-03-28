import UIKit

protocol KeyboardViewDelegate: class {
    func didSwipeKey(_ key: KeyDefinition)
    func didTriggerKey(_ key: KeyDefinition)
    func didTriggerDoubleTap(forKey key: KeyDefinition)
    func didTriggerHoldKey(_ key: KeyDefinition)
    func didMoveCursor(_ movement: Int)
}

@objc protocol KeyboardViewKeyboardKeyDelegate {
    @objc func didTriggerKeyboardButton(sender: UIView, forEvent event: UIEvent)
}

// FIXME: this could be simplified with a typealias
// swiftlint:disable all
final internal class KeyboardView: UIView,
    KeyboardViewProvider,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout,
    LongPressOverlayDelegate,
    LongPressCursorMovementDelegate
{
// swiftlint:enable all
    private static let pauseBeforeRepeatTimeInterval: TimeInterval = 0.5
    private static let keyRepeatTimeInterval: TimeInterval = 0.1
    private var theme: ThemeType

    private let definition: KeyboardDefinition

    weak var delegate: (KeyboardViewDelegate & KeyboardViewKeyboardKeyDelegate)?

    private var currentPage: [[KeyDefinition]] {
        return keyDefinitionsForPage(page)
    }

    private func keyDefinitionsForPage(_ page: KeyboardPage) -> [[KeyDefinition]] {
        switch page {
        case .symbols1:
            return definition.symbols1
        case .symbols2:
            return definition.symbols2
        case .shifted, .capslock:
            return definition.shifted
        default:
            return definition.normal
        }
    }

    public var page: KeyboardPage = .normal {
        didSet {
            update()
        }
    }

    private let reuseIdentifier = "cell"
    private let collectionView: UICollectionView
    private let layout = UICollectionViewFlowLayout()

    private var longpressController: LongPressBehaviorProvider?
    private var currentlyLongpressedKey: KeyDefinition?

    // Sorry. The globe button is the greatest lie of them all. This is the only known way to have a UIEvent we can trigger the
    // keyboard switcher popup with. I don't like it either.
    private var keyboardButtonFrame: CGRect? {
        didSet {
            if let keyboardButtonExtraButton = keyboardButtonExtraButton {
                keyboardButtonExtraButton.removeFromSuperview()
                self.keyboardButtonExtraButton = nil
            }
            if let keyboardButtonFrame = keyboardButtonFrame {
                keyboardButtonExtraButton = UIButton(frame: keyboardButtonFrame)
                keyboardButtonExtraButton?.backgroundColor = .clear
                keyboardButtonExtraButton?.isAccessibilityElement = true
                keyboardButtonExtraButton?.accessibilityLabel = NSLocalizedString("accessibility.nextKeyboard", comment: "")
            }
            if let keyboardButtonExtraButton = keyboardButtonExtraButton {
                addSubview(keyboardButtonExtraButton)
                keyboardButtonExtraButton.addTarget(delegate,
                                                    action: #selector(KeyboardViewKeyboardKeyDelegate.didTriggerKeyboardButton),
                                                    for: UIControl.Event.allEvents)
            }
        }
    }

    private var keyboardButtonExtraButton: UIButton?

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private(set) lazy var longpressGestureRecognizer: UILongPressGestureRecognizer = {
        let recognizer =  UILongPressGestureRecognizer(target: self, action: #selector(KeyboardView.touchesFoundLongpress))
        recognizer.cancelsTouchesInView = false
        return recognizer
    }()

    required init(definition: KeyboardDefinition, theme: ThemeType) {
        self.definition = definition
        self.theme = theme

        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)

        super.init(frame: CGRect.zero)
        update()

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(KeyCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.isUserInteractionEnabled = false
        collectionView.isScrollEnabled = false

        addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: topAnchor).enable()
        collectionView.bottomAnchor.constraint(equalTo: bottomAnchor).enable()
        collectionView.leftAnchor.constraint(equalTo: leftAnchor).enable()
        collectionView.rightAnchor.constraint(equalTo: rightAnchor).enable()
        collectionView.backgroundColor = .clear

        addGestureRecognizer(longpressGestureRecognizer)

        isMultipleTouchEnabled = true
    }

    func updateTheme(theme: ThemeType) {
        self.theme = theme
        update()
    }

    public func update() {
        backgroundColor = theme.backgroundColor
        keyboardButtonFrame = nil
        calculateRows()
    }

    func remove() {
        delegate = nil
        removeFromSuperview()
    }

    // MARK: - Overlay handling

    private(set) var overlays: [KeyType: KeyOverlayView] = [:]

    override var bounds: CGRect {
        didSet {
            update()
        }
    }

    private func ensureValidKeyView(at indexPath: IndexPath) -> Bool {
        guard collectionView.cellForItem(at: indexPath)?.subviews.first?.subviews.first?.subviews.first != nil else {
            return false
        }

        return true
    }

    private func applyOverlayConstraints(to overlay: KeyOverlayView, keyView: KeyView) {
        guard let superview = superview else {
            return
//            fatalError("superview not found for overlay constraints")
        }

        overlay.heightAnchor
            .constraint(greaterThanOrEqualTo: keyView.heightAnchor)
            .enable(priority: .defaultHigh)

        overlay.widthAnchor.constraint(
            greaterThanOrEqualTo: keyView.widthAnchor,
            constant: theme.popupCornerRadius * 2)
            .enable(priority: .required)

        overlay.topAnchor
            .constraint(greaterThanOrEqualTo: superview.topAnchor)
            .enable(priority: .defaultLow)

        let bottomAnchorView = keyView.contentView ?? keyView
        let offset: CGFloat = 0.5 // Without this small offset, the overlay appears slightly above the key
        overlay.bottomAnchor.constraint(equalTo: bottomAnchorView.bottomAnchor, constant: offset)
            .enable(priority: .defaultHigh)

        overlay.centerXAnchor.constraint(lessThanOrEqualTo: keyView.centerXAnchor)
            .enable(priority: .defaultHigh)

        // Handle the left and right sides not getting crushed on the edges of the screen

        overlay.leftAnchor.constraint(greaterThanOrEqualTo: keyView.leftAnchor)
            .enable(priority: .defaultHigh)
        overlay.leftAnchor
            .constraint(greaterThanOrEqualTo: superview.leftAnchor)
            .enable(priority: .required)

        overlay.rightAnchor.constraint(lessThanOrEqualTo: keyView.rightAnchor)
            .enable(priority: .defaultHigh)
        overlay.rightAnchor
            .constraint(lessThanOrEqualTo: superview.rightAnchor)
            .enable(priority: .required)
    }

    private func showOverlay(forKeyAtIndexPath indexPath: IndexPath) {
        guard let keyCell = collectionView.cellForItem(at: indexPath) as? KeyCell,
            let keyView = keyCell.keyView else {
            return
        }
        if !ensureValidKeyView(at: indexPath) {
            return
        }
        let key = currentPage[indexPath.section][indexPath.row]
        // removeOverlay(forKey: key)
        removeAllOverlays()

        let overlay = KeyOverlayView(origin: keyView, key: key, theme: theme)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(overlay)

        applyOverlayConstraints(to: overlay, keyView: keyView)
        overlays[key.type] = overlay

        overlay.clipsToBounds = false

        let keyLabel = UILabel(frame: .zero)
        keyLabel.clipsToBounds = false
        if case let .input(title, _) = key.type {
            keyLabel.text = title
        }
        keyLabel.textColor = theme.textColor

        switch page {
        case .normal:
            keyLabel.font = theme.popupLowerKeyFont
        default:
            keyLabel.font = theme.popupCapitalKeyFont
        }
        keyLabel.textAlignment = .center
        keyLabel.translatesAutoresizingMaskIntoConstraints = false
        overlay.originFrameView.addSubview(keyLabel)
        keyLabel.centerIn(superview: overlay.originFrameView)

        superview?.setNeedsLayout()
    }

    func removeOverlay(forKey key: KeyDefinition) {
        overlays[key.type]?.removeFromSuperview()
        overlays[key.type] = nil
    }

    func removeAllOverlays() {
        for overlay in overlays.values {
            overlay.removeFromSuperview()
        }
        overlays = [:]
    }

    // MARK: - LongPressOverlayDelegate

    func longpress(didCreateOverlayContentView contentView: UIView) {
        if overlays.first?.value.originFrameView == nil {
            if let activeKey = activeKey {
                showOverlay(forKeyAtIndexPath: activeKey.indexPath)
            }
        }

        guard let overlayContentView = self.overlays.first?.value.originFrameView else {
            return
        }

        overlayContentView.subviews.forEach { $0.removeFromSuperview() }
        overlayContentView.addSubview(contentView)
        contentView.setContentCompressionResistancePriority(.required, for: .vertical)
        contentView.fill(superview: overlayContentView)

        // HACK: Because uicollectionview's intrinsic size just isn't enough

        if activeKey != nil,
            let longpressValues = (self.longpressController as? LongPressOverlayController)?.longpressValues {
            let count = longpressValues.count

            let widthConstant: CGFloat
            if count > theme.popupLongpressKeysPerRow {
                widthConstant = longpressKeySize().width * ceil(CGFloat(count) / 2.0) + theme.keyHorizontalMargin
            } else {
                widthConstant = longpressKeySize().width * CGFloat(count) + theme.keyHorizontalMargin
            }

            let heightConstant: CGFloat

            if count > theme.popupLongpressKeysPerRow {
                heightConstant = longpressKeySize().height * 2
            } else {
                heightConstant = longpressKeySize().height
            }

            contentView.widthAnchor.constraint(equalToConstant: widthConstant).enable(priority: .required)
            contentView.heightAnchor.constraint(equalToConstant: heightConstant).enable(priority: .required)
        } else {
            let constant = longpressKeySize().height
            contentView.heightAnchor.constraint(equalToConstant: constant).enable(priority: .required)
        }
        contentView.layoutIfNeeded()
    }

    func longpressDidCancel() {
        longpressController = nil
        currentlyLongpressedKey = nil
        collectionView.alpha = 1.0
        if isLogicallyIPad, let activeKey = activeKey {
            delegate?.didTriggerKey(activeKey.key)
        }
    }

    func longpress(didSelectKey key: KeyDefinition) {
        delegate?.didTriggerKey(key)
        longpressController = nil
        currentlyLongpressedKey = nil
    }

    func longpressFrameOfReference() -> CGRect {
        return bounds
    }

    func longpressKeySize() -> CGSize {
        switch currentlyLongpressedKey?.type {
        case .returnkey(name: _):
            // iPhone keyboard mode overlay
            return CGSize(width: 50, height: 35)
        case .keyboardMode:
            // iPad keyboard mode overlay
            return CGSize(width: 75, height: 53)
        default:
            break
        }

        let width = bounds.size.width / CGFloat(currentPage.first?.count ?? 10)
        var height = (bounds.size.height / CGFloat(currentPage.count)) - theme.popupCornerRadius * 2
        height = max(32.0, height)
        return CGSize(
            width: width,
            height: height
        )
    }

    // MARK: - LongPressCursorMovementDelegate

    func longpress(movedCursor: Int) {
        delegate?.didMoveCursor(movedCursor)
    }

    // MARK: - Input handling

    struct KeyTriggerTiming {
        let time: TimeInterval
        let key: KeyDefinition

        static let doubleTapTime: TimeInterval = 0.4
        // static let longpressTime: TimeInterval = 0.9
    }

    var keyTriggerTiming: KeyTriggerTiming?
    var keyRepeatTimer: Timer?

    struct ActiveKey: Hashable {
        static func == (lhs: KeyboardView.ActiveKey, rhs: KeyboardView.ActiveKey) -> Bool {
            return lhs.key.type == rhs.key.type
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(key.type)
        }

        let key: KeyDefinition
        let indexPath: IndexPath
    }

    var activeKey: ActiveKey? {
        willSet {
            if let activeKey = activeKey,
                let cell = collectionView.cellForItem(at: activeKey.indexPath) as? KeyCell,
                newValue?.indexPath != activeKey.indexPath {
                cell.keyView?.active = false
            }
            if newValue == nil, activeKey != nil {
                removeAllOverlays()
                keyRepeatTimer?.invalidate()
                keyRepeatTimer = nil
            }

            // Should repeat trigger?
            if let key = newValue, key.key.type.supportsRepeatTrigger, keyRepeatTimer == nil {
                keyRepeatTimer = makeKeyRepeatTimer(timeInterval: KeyboardView.pauseBeforeRepeatTimeInterval)
            }
        }
        didSet {
            // Should show overlay?
            if let activeKey = activeKey,
                let cell = collectionView.cellForItem(at: activeKey.indexPath) as? KeyCell,
                activeKey.indexPath != oldValue?.indexPath {
                cell.keyView?.active = true
                if case .input = activeKey.key.type, !self.isLogicallyIPad {
                    showOverlay(forKeyAtIndexPath: activeKey.indexPath)
                }
            }
        }
    }

    private func makeKeyRepeatTimer(timeInterval: TimeInterval) -> Timer {
        return Timer.scheduledTimer(
            timeInterval: timeInterval,
            target: self,
            selector: #selector(KeyboardView.keyRepeatTimerDidTrigger),
            userInfo: nil,
            repeats: true)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
        // Forward to longpress controller?
        if let longpressController = self.longpressController, let touch = touches.first {
            longpressController.touchesBegan(touch.location(in: collectionView))
            return
        }

        // Trigger key if the user was already holding a key
        if let key = activeKey?.key {
            if key.type.triggersOnTouchUp {
                if let delegate = delegate {
                    delegate.didTriggerKey(key)
                }
            }
            activeKey = nil
        }

        handleTouches(touches)
    }

    private func handleTouches(_ touches: Set<UITouch>) {
        for touch in touches {
            if let indexPath = collectionView.indexPathForItem(at: touch.location(in: collectionView)) {
                let key = currentPage[indexPath.section][indexPath.row]

                if key.type.supportsDoubleTap {
                    let timeInterval = Date.timeIntervalSinceReferenceDate
                    if let keyTriggerTiming = keyTriggerTiming {
                        if max(0.0, timeInterval - keyTriggerTiming.time) < KeyTriggerTiming.doubleTapTime {
                            if let delegate = delegate {
                                delegate.didTriggerDoubleTap(forKey: key)
                                self.keyTriggerTiming = nil
                                return
                            }
                        }
                    }
                    keyTriggerTiming = KeyTriggerTiming(time: timeInterval, key: key)
                }

                if key.type.triggersOnTouchDown {
                    if let delegate = delegate {
                        delegate.didTriggerKey(key)
                    }
                }

                if key.type.triggersOnTouchUp || key.type.supportsRepeatTrigger {
                    activeKey = ActiveKey(key: key, indexPath: indexPath)
                }
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?) {
        // Forward to longpress controller?
        if let longpressController = self.longpressController, let touch = touches.first {
            longpressController.touchesMoved(touch.location(in: collectionView))
            return
        }

        // Swipe key handling
        if let activeKey = activeKey,
            let cell = collectionView.cellForItem(at: activeKey.indexPath) as? KeyCell,
            let swipeKeyView = cell.keyView,
            swipeKeyView.isSwipeKey,
            let touchLocation = touches.first?.location(in: cell.superview) {
            let deadZone: CGFloat = 20.0
            let delta: CGFloat = 60.0
            let yOffset = touchLocation.y - cell.center.y

            var percentage: CGFloat = 0.0
            if yOffset > deadZone {
                if yOffset - deadZone > delta {
                    percentage = 1.0
                } else {
                    percentage = (yOffset - deadZone) / delta
                }
            }
            swipeKeyView.percentageAlternative = percentage
            return
        }

        if activeKey != nil {
            for touch in touches {
                if let indexPath = collectionView.indexPathForItem(at: touch.location(in: collectionView)) {
                    let key = currentPage[indexPath.section][indexPath.row]
                    activeKey = ActiveKey(key: key, indexPath: indexPath)
                } else {
                    activeKey = nil
                }
            }
        }
    }

    override func touchesCancelled(_: Set<UITouch>, with _: UIEvent?) {
        longpressController = nil
        activeKey = nil
    }

    override func touchesEnded(_ touches: Set<UITouch>, with _: UIEvent?) {
        // Forward to longpress controller?
        if let longpressController = self.longpressController, let touch = touches.first {
            longpressController.touchesEnded(touch.location(in: collectionView))
            activeKey = nil

            return
        }

        if let activeKey = activeKey {
            if activeKey.key.type.triggersOnTouchUp {
                if let cell = collectionView.cellForItem(at: activeKey.indexPath) as? KeyCell,
                    let swipeKeyView = cell.keyView,
                    swipeKeyView.isSwipeKey,
                    swipeKeyView.percentageAlternative > 0.5 {
                    delegate?.didSwipeKey(activeKey.key)
                } else {
                    delegate?.didTriggerKey(activeKey.key)
                }
            }
        }

        activeKey = nil

        //        for touch in touches {
        //            if let indexPath = collectionView.indexPathForItem(at: touch.location(in: collectionView)) {
        //                let key = currentPage[indexPath.section][indexPath.row]
        //                if key.type.triggersOnTouchUp {
        //                    if let delegate = delegate {
        //                        delegate.didTriggerKey(currentPage[indexPath.section][indexPath.row])
        //                    }
        //                }
        //            }
        //        }
    }

    private func showKeyboardModeOverlay(_ longpressGestureRecognizer: UILongPressGestureRecognizer, key: KeyDefinition) {
        let longpressValues = keyboardModeDefinitions()
        let longpressController = LongPressOverlayController(key: key, page: page, theme: theme, longpressValues: longpressValues)
        longpressController.delegate = self

        self.longpressController = longpressController
        longpressController.touchesBegan(
            longpressGestureRecognizer.location(in: collectionView))
    }

    private func keyboardModeDefinitions() -> [KeyDefinition] {
        if isLogicallyIPad {
            return [
                KeyDefinition(type: .sideKeyboardLeft),
                KeyDefinition(type: .normalKeyboard),
                KeyDefinition(type: .sideKeyboardRight),
                KeyDefinition(type: .splitKeyboard)
            ]
        } else {
            return [
                KeyDefinition(type: .sideKeyboardLeft),
                KeyDefinition(type: .normalKeyboard),
                KeyDefinition(type: .sideKeyboardRight)
            ]
        }
    }

    @objc func touchesFoundLongpress(_ longpressGestureRecognizer: UILongPressGestureRecognizer) {
        if let indexPath = collectionView.indexPathForItem(at: longpressGestureRecognizer.location(in: collectionView)),
            longpressController == nil {
            let key = currentPage[indexPath.section][indexPath.row]
            currentlyLongpressedKey = key
            switch key.type {
            case let .input(string, _):
                guard let longpressValues = longpressKeys(for: string),
                    longpressGestureRecognizer.state == .began else {
                        break
                }
                let longpressController = LongPressOverlayController(
                    key: key,
                    page: page,
                    theme: theme,
                    longpressValues: longpressValues)
                longpressController.delegate = self

                self.longpressController = longpressController
                let location = longpressGestureRecognizer.location(in: collectionView)
                longpressController.touchesBegan(location)
            case .keyboardMode:
                if longpressGestureRecognizer.state == .began {
                    showKeyboardModeOverlay(longpressGestureRecognizer, key: key)
                }

            case .spacebar:
                if longpressGestureRecognizer.state == .began {
                    let longpressController = LongPressCursorMovementController()
                    longpressController.delegate = self
                    self.longpressController = longpressController
                    collectionView.alpha = 0.4
                }
            case .backspace:
                // Cancel, the repeat trigger timing deals with this
                break
            case .returnkey(name: _):
                if longpressGestureRecognizer.state == .began {
                    showKeyboardModeOverlay(longpressGestureRecognizer, key: key)
                }
            default:
                delegate?.didTriggerHoldKey(key)
            }
        }
    }

    @objc func keyRepeatTimerDidTrigger() {
        if let activeKey = activeKey, activeKey.key.type.supportsRepeatTrigger {
            delegate?.didTriggerKey(activeKey.key)
            increaseKeyRepeatRateIfNeeded()
        }
    }

    private func increaseKeyRepeatRateIfNeeded() {
        if keyRepeatTimer?.timeInterval == KeyboardView.pauseBeforeRepeatTimeInterval {
            keyRepeatTimer?.invalidate()
            keyRepeatTimer = makeKeyRepeatTimer(timeInterval: KeyboardView.keyRepeatTimeInterval)
        }
    }

    private func longpressKeys(for key: String) -> [KeyDefinition]? {
        let longpressKeys = self.definition
        .longPress[key]?
        .compactMap({
            KeyDefinition(type: .input(key: $0, alternate: nil))
        })

        guard var keys = longpressKeys else {
            return nil
        }

        if isLogicallyIPad == false {
            let originalKey = KeyDefinition(type: .input(key: key, alternate: nil))
            if keys.contains(where: { (keyDefinition) -> Bool in
                keyDefinition.type == originalKey.type
            }) {
                // Already contains this key. Do nothing.
            } else {
                // Add the originally pressed key to the list of long press options.
                keys = [originalKey] + keys
            }
        }

        return keys
    }

    // MARK: - CollectionView

    private var rowNumberOfUnits: [CGFloat]!

    private func calculateRows() {
        var mutableWidths = [CGFloat]()

        for row in currentPage {
            let numberOfUnits = row.reduce(0.0) { (sum, key) -> CGFloat in
                sum + key.size.width
            }
            mutableWidths.append(numberOfUnits)
        }

        rowNumberOfUnits = mutableWidths

        collectionView.reloadData()
    }

    func numberOfSections(in _: UICollectionView) -> Int {
        return currentPage.count
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentPage[section].count
    }

    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        let key = currentPage[indexPath.section][indexPath.row]

        if key.type == .keyboard {
            keyboardButtonFrame = cell.frame
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                            for: indexPath) as? KeyCell else {
            fatalError("Unable to cast to KeyCell")
        }
        let key = currentPage[indexPath.section][indexPath.row]

        cell.configure(page: page, key: key, theme: theme, traits: self.traitCollection)

        if let swipeKeyView = cell.keyView, swipeKeyView.isSwipeKey {
            // FIXME: this is a code smell side effect bad idea.
            swipeKeyView.percentageAlternative = 0.0
        }

        return cell
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let key = currentPage[indexPath.section][indexPath.row]

        // Using self.bounds here, because self.collectionView.frame isnt correctly sized in iOS 10
        let width = key.size.width * ((bounds.size.width - 1) / rowNumberOfUnits[indexPath.section])
        let height = bounds.size.height / CGFloat(currentPage.count)
        return CGSize(width: width, height: height)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt _: Int) -> CGFloat {
        return 0
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumLineSpacingForSectionAt _: Int) -> CGFloat {
        return 0
    }

    final class KeyCell: UICollectionViewCell {
        var keyView: KeyView?

        override init(frame: CGRect) {
            super.init(frame: frame)

            contentView.clipsToBounds = false
            contentView.translatesAutoresizingMaskIntoConstraints = false
            contentView.fill(superview: self)
        }

        func configure(page: KeyboardPage, key: KeyDefinition, theme: ThemeType, traits: UITraitCollection) {
            _ = contentView.subviews.forEach { view in
                view.removeFromSuperview()
            }
            keyView = nil

            if case .spacer = key.type {
                let emptyview = UIView(frame: .zero)
                emptyview.translatesAutoresizingMaskIntoConstraints = false
                emptyview.backgroundColor = .clear
                contentView.addSubview(emptyview)
                emptyview.fill(superview: contentView)
            } else {
                let keyView = KeyView(page: page, key: key, theme: theme, traits: traits)
                if let accessibilityLabel = key.accessibilityLabel(for: page) {
                    keyView.isAccessibilityElement = true
                    keyView.accessibilityLabel = accessibilityLabel
                }
                keyView.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview(keyView)
                keyView.fill(superview: contentView)
                self.keyView = keyView
            }
        }

        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
