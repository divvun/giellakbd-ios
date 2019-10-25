import UIKit

protocol KeyboardViewDelegate {
    func didSwipeKey(_ key: KeyDefinition)
    func didTriggerKey(_ key: KeyDefinition)
    func didTriggerDoubleTap(forKey key: KeyDefinition)
    func didTriggerHoldKey(_ key: KeyDefinition)
    func didMoveCursor(_ movement: Int)
}

@objc protocol KeyboardViewKeyboardKeyDelegate {
    @objc func didTriggerKeyboardButton(sender: UIView, forEvent event: UIEvent)
}

internal class KeyboardView: UIView, KeyboardViewProvider, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, LongPressOverlayDelegate, LongPressCursorMovementDelegate {
    
    internal static var theme: Theme = UIDevice.current.dc.isIpad ? LightThemeIpadImpl() : LightThemeImpl()
    private static let keyRepeatTimeInterval: TimeInterval = 0.15

    let definition: KeyboardDefinition
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
    let collectionView: UICollectionView
    private let layout = UICollectionViewFlowLayout()

    var longpressController: LongPressBehaviorProvider?

    // Sorry. The globe button is the greatest lie of them all. This is the only known way to have a UIEvent we can trigger the
    // keyboard switcher popup with. I don't like it either.
    private var keyboardButtonFrame: CGRect? {
        didSet {
//            if let keyboardButtonExtraButton = keyboardButtonExtraButton {
//                keyboardButtonExtraButton.removeFromSuperview()
//                self.keyboardButtonExtraButton = nil
//            }
//            if let keyboardButtonFrame = keyboardButtonFrame {
//                keyboardButtonExtraButton = UIButton(frame: keyboardButtonFrame)
//                keyboardButtonExtraButton?.backgroundColor = .clear
//            }
//            if let keyboardButtonExtraButton = keyboardButtonExtraButton {
//                addSubview(keyboardButtonExtraButton)
//                keyboardButtonExtraButton.addTarget(delegate, action: #selector(KeyboardViewKeyboardKeyDelegate.didTriggerKeyboardButton), for: UIControl.Event.allEvents)
//            }
        }
    }

    private var keyboardButtonExtraButton: UIButton?

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private(set) lazy var longpressGestureRecognizer: UILongPressGestureRecognizer = {
        let x =  UILongPressGestureRecognizer(target: self, action: #selector(KeyboardView.touchesFoundLongpress))
        x.cancelsTouchesInView = false
        return x
    }()
    
    required init(definition: KeyboardDefinition) {
        self.definition = definition

        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        
        super.init(frame: CGRect.zero)
        update()

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(KeyCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.isUserInteractionEnabled = false

        addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        collectionView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        collectionView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        collectionView.backgroundColor = .clear

        addGestureRecognizer(longpressGestureRecognizer)

        isMultipleTouchEnabled = true
    }

    public func updateTheme(theme: Theme) {
        KeyboardView.theme = theme
        update()
    }

    public func update() {
        backgroundColor = KeyboardView.theme.backgroundColor
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
        guard let _ = collectionView.cellForItem(at: indexPath)?.subviews.first?.subviews.first?.subviews.first else {
            return false
        }

        return true
    }

    private func showOverlay(forKeyAtIndexPath indexPath: IndexPath) {
        guard let keyCell = collectionView.cellForItem(at: indexPath)?.subviews.first else {
            return
        }
        if !ensureValidKeyView(at: indexPath) {
            return
        }
        let key = currentPage[indexPath.section][indexPath.row]
        // removeOverlay(forKey: key)
        removeAllOverlays()

        let overlay = KeyOverlayView(origin: keyCell, key: key)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        ( /* self.superview ?? */ self).addSubview(overlay)

        let height = overlay.heightAnchor.constraint(greaterThanOrEqualTo: keyCell.heightAnchor, multiplier: 2.0)
        height.priority = UILayoutPriority.defaultLow
        height.isActive = true

        let width = overlay.widthAnchor.constraint(greaterThanOrEqualTo: keyCell.widthAnchor, multiplier: 1.0, constant: KeyboardView.theme.popupCornerRadius * 2)
        width.isActive = true

        let bottom = overlay.bottomAnchor.constraint(equalTo: keyCell.bottomAnchor)
        bottom.priority = .defaultLow
        bottom.isActive = true

        let center = overlay.centerXAnchor.constraint(equalTo: keyCell.centerXAnchor)
        center.priority = UILayoutPriority.defaultLow
        center.isActive = true

        overlay.leftAnchor.constraint(lessThanOrEqualTo: keyCell.leftAnchor).isActive = true
        overlay.rightAnchor.constraint(greaterThanOrEqualTo: keyCell.rightAnchor).isActive = true

        overlay.topAnchor.constraint(greaterThanOrEqualTo: (superview ?? self).topAnchor).isActive = true
        overlay.leftAnchor.constraint(greaterThanOrEqualTo: (superview ?? self).leftAnchor).isActive = true
        overlay.rightAnchor.constraint(lessThanOrEqualTo: (superview ?? self).rightAnchor).isActive = true
        overlays[key.type] = overlay

        let keyLabel = UILabel(frame: .zero)
        if case let .input(title, _) = key.type {
            keyLabel.text = title
        }
        keyLabel.textColor = KeyboardView.theme.textColor
        keyLabel.font = KeyboardView.theme.popupKeyFont
        keyLabel.textAlignment = .center
        keyLabel.translatesAutoresizingMaskIntoConstraints = false
        overlay.contentView.addSubview(keyLabel)
        keyLabel.fillSuperview(overlay.contentView)

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

    func longpress(didCreateOverlayContentView contentView: UIView) {
        if overlays.first?.value.contentView == nil {
            if let activeKey = activeKey {
                showOverlay(forKeyAtIndexPath: activeKey.indexPath)
            }
        }

        guard let overlayContentView = self.overlays.first?.value.contentView else {
            return
        }

        overlayContentView.subviews.forEach { $0.removeFromSuperview() }
        overlayContentView.addSubview(contentView)
        contentView.setContentCompressionResistancePriority(.required, for: .vertical)
        contentView.fillSuperview(overlayContentView)

        // MARK: Hack! Because uicollectionview's intrinsic size just isn't enough

        if activeKey != nil,
            let longpressValues = (self.longpressController as? LongPressOverlayController)?.longpressValues {
            let count = longpressValues.count

            let widthConstant: CGFloat
            if count >= LongPressOverlayController.multirowThreshold {
                widthConstant = longpressKeySize().width * ceil(CGFloat(count) / 2.0) + KeyboardView.theme.keyHorizontalMargin
            } else {
                widthConstant = longpressKeySize().width * CGFloat(count) + KeyboardView.theme.keyHorizontalMargin
            }

            let heightConstant: CGFloat

            if count >= LongPressOverlayController.multirowThreshold {
                heightConstant = longpressKeySize().height * 2
            } else {
                heightConstant = longpressKeySize().height
            }

            contentView.widthAnchor.constraint(equalToConstant: widthConstant).isActive = true
            contentView.heightAnchor.constraint(equalToConstant: heightConstant).isActive = true
        } else {
            contentView.heightAnchor.constraint(equalToConstant: longpressKeySize().height).isActive = true
        }
        contentView.layoutIfNeeded()
    }

    func longpressDidCancel() {
        longpressController = nil
        collectionView.alpha = 1.0
    }

    func longpress(didSelectKey key: KeyDefinition) {
        delegate?.didTriggerKey(key)
        longpressController = nil
    }

    func longpressFrameOfReference() -> CGRect {
        return bounds
    }

    func longpressKeySize() -> CGSize {
        return CGSize(width: bounds.size.width / CGFloat(currentPage.first?.count ?? 10), height: (bounds.size.height / CGFloat(currentPage.count)) - KeyboardView.theme.popupCornerRadius * 2)
    }

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
                keyRepeatTimer = Timer.scheduledTimer(
                    timeInterval: KeyboardView.keyRepeatTimeInterval,
                    target: self,
                    selector: #selector(KeyboardView.keyRepeatTimerDidTrigger),
                    userInfo: nil,
                    repeats: true)
            }
        }
        didSet {
            // Should show overlay?
            if let activeKey = activeKey,
                let cell = collectionView.cellForItem(at: activeKey.indexPath) as? KeyCell,
                activeKey.indexPath != oldValue?.indexPath {
                cell.keyView?.active = true
                if case .input = activeKey.key.type, !UIDevice.current.dc.isIpad {
                    showOverlay(forKeyAtIndexPath: activeKey.indexPath)
                }
            }
        }
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
            let touchLocation = touches.first?.location(in: cell.superview)
        {
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

        if let _ = activeKey {
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
        let longpressController = LongPressOverlayController(key: key, longpressValues: [
            KeyDefinition(type: .sideKeyboardLeft),
            KeyDefinition(type: .splitKeyboard),
            KeyDefinition(type: .sideKeyboardRight)
        ])
        longpressController.delegate = self

        self.longpressController = longpressController
        longpressController.touchesBegan(
            longpressGestureRecognizer.location(in: collectionView))
    }

    @objc func touchesFoundLongpress(_ longpressGestureRecognizer: UILongPressGestureRecognizer) {
        if let indexPath = collectionView.indexPathForItem(at: longpressGestureRecognizer.location(in: collectionView)), longpressController == nil {
            let key = currentPage[indexPath.section][indexPath.row]
            switch key.type {
            case let .input(string, _):
                let x = self.definition
                    .longPress[string]?
                    .compactMap({
                        KeyDefinition(type: .input(key: $0, alternate: nil))
                    })
                
                if let longpressValues = x,
                    longpressGestureRecognizer.state == .began
                {
                    let longpressController = LongPressOverlayController(
                        key: key,
                        longpressValues: longpressValues)
                    longpressController.delegate = self

                    self.longpressController = longpressController
                    let location = longpressGestureRecognizer.location(in: collectionView)
                    longpressController.touchesBegan(location)
                }
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
            default:
                delegate?.didTriggerHoldKey(key)
            }
        }
    }

    @objc func keyRepeatTimerDidTrigger() {
        if let activeKey = activeKey, activeKey.key.type.supportsRepeatTrigger {
            delegate?.didTriggerKey(activeKey.key)
        }
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

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let key = currentPage[indexPath.section][indexPath.row]

        if key.type == .keyboard {
            keyboardButtonFrame = cell.frame
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! KeyCell
        let key = currentPage[indexPath.section][indexPath.row]
        
        cell.setKey(page: page, key: key)

        if let swipeKeyView = cell.keyView, swipeKeyView.isSwipeKey {
            // FIXME: this is a code smell side effect bad idea.
            swipeKeyView.percentageAlternative = 0.0
        }

        return cell
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let key = currentPage[indexPath.section][indexPath.row]

        // Using self.bounds here, because self.collectionView.frame isnt correctly sized in iOS 10
        return CGSize(width: key.size.width * ((bounds.size.width - 1) / rowNumberOfUnits[indexPath.section]), height: bounds.size.height / CGFloat(currentPage.count))
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumInteritemSpacingForSectionAt _: Int) -> CGFloat {
        return 0
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumLineSpacingForSectionAt _: Int) -> CGFloat {
        return 0
    }

    class KeyCell: UICollectionViewCell {
        var keyView: KeyView?

        override init(frame: CGRect) {
            super.init(frame: frame)
        }

        func setKey(page: KeyboardPage, key: KeyDefinition) {
            _ = contentView.subviews.forEach { view in
                view.removeFromSuperview()
            }
            keyView = nil

            if case .spacer = key.type {
                let emptyview = UIView(frame: .zero)
                emptyview.translatesAutoresizingMaskIntoConstraints = false
                emptyview.backgroundColor = .clear
                contentView.addSubview(emptyview)
                emptyview.fillSuperview(contentView)
            } else {
                let keyView = KeyView(page: page, key: key)
                keyView.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview(keyView)
                keyView.fillSuperview(contentView)
                self.keyView = keyView
            }
            
            contentView.clipsToBounds = false
        }

        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
