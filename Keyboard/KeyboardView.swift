//
//  KeyboardView.swift
//  NewKeyboard
//
//  Created by Ville Petersson on 2019-06-24.
//  Copyright © 2019 The Techno Creatives AB. All rights reserved.
//

import UIKit

protocol KeyboardViewDelegate {
    func didTriggerKey(_ key: KeyDefinition)
    func didTriggerDoubleTap(forKey key: KeyDefinition)
    func didTriggerHoldKey(_ key: KeyDefinition)
    func didMoveCursor(_ movement: Int)
}

@objc protocol KeyboardViewKeyboardKeyDelegate {
    @objc func didTriggerKeyboardButton(sender: UIView, forEvent event: UIEvent)
}

class KeyboardView: UIView, KeyboardViewProvider, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, LongPressOverlayDelegate, LongPressCursorMovementDelegate {
    
    static public var theme: Theme = LightThemeImpl()
    static private let keyRepeatTimeInterval: TimeInterval = 0.15
    
    public var swipeDownKeysEnabled: Bool = UIDevice.current.kind == UIDevice.Kind.iPad
    
    let definition: KeyboardDefinition
    weak var delegate: (KeyboardViewDelegate & KeyboardViewKeyboardKeyDelegate)?
    

    private var currentPage: [[KeyDefinition]] {
        return keyDefinitionsForPage(self.page)
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
            self.update()
        }
    }
    
    private let reuseIdentifier = "cell"
    let collectionView: UICollectionView
    private let layout = UICollectionViewFlowLayout.init()
    
    var longpressController: LongPressBehaviorProvider? = nil
    
    // Sorry. The globe button is the greatest lie of them all. This is the only known way to have a UIEvent we can trigger the
    // keyboard switcher popup with. I don't like it either.
    private var keyboardButtonFrame: CGRect? {
        didSet {
            if let keyboardButtonExtraButton = keyboardButtonExtraButton {
                keyboardButtonExtraButton.removeFromSuperview()
                self.keyboardButtonExtraButton = nil
            }
            if let keyboardButtonFrame = keyboardButtonFrame {
                self.keyboardButtonExtraButton = UIButton(frame: keyboardButtonFrame)
                self.keyboardButtonExtraButton?.backgroundColor = .clear
            }
            if let keyboardButtonExtraButton = keyboardButtonExtraButton {
                self.addSubview(keyboardButtonExtraButton)
                keyboardButtonExtraButton.addTarget(self.delegate, action: #selector(KeyboardViewKeyboardKeyDelegate.didTriggerKeyboardButton), for: UIControl.Event.allEvents)
            }
        }
    }
    private var keyboardButtonExtraButton: UIButton?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(definition: KeyboardDefinition) {
        self.definition = definition

        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        
        super.init(frame: CGRect.zero)
        self.update()

        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.register(KeyCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView.isUserInteractionEnabled = false

        self.addSubview(self.collectionView)
        
        self.collectionView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        self.collectionView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.collectionView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.collectionView.backgroundColor = .clear
        
        let longpressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(KeyboardView.touchesFoundLongpress))
        longpressGestureRecognizer.cancelsTouchesInView = false

        self.addGestureRecognizer(longpressGestureRecognizer)
        
        self.isMultipleTouchEnabled = true
    }
    
    public func updateTheme(theme: Theme) {
        KeyboardView.theme = theme
        self.update()
    }
    
    public func update() {
        self.backgroundColor = KeyboardView.theme.backgroundColor
        self.keyboardButtonFrame = nil
        self.calculateRows()
    }
    
    func remove() {
        self.delegate = nil
        self.removeFromSuperview()
    }
    
    // MARK: - Overlay handling
    // MARK: -
    
    private(set) var overlays: [KeyType:KeyOverlayView] = [:]
    
    override var bounds: CGRect {
        didSet {
            update()
        }
    }

    private func showOverlay(forKeyAtIndexPath indexPath: IndexPath) {
        guard let keyCell = collectionView.cellForItem(at: indexPath)?.subviews.first else {
            return
        }
        guard let keyView = collectionView.cellForItem(at: indexPath)?.subviews.first?.subviews.first?.subviews.first else {
            return
        }
        let key = currentPage[indexPath.section][indexPath.row]
        //removeOverlay(forKey: key)
        removeAllOverlays()
        
        let overlay = KeyOverlayView(origin: keyCell, key: key)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        (/*self.superview ??*/ self).addSubview(overlay)
        
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
        
        overlay.topAnchor.constraint(greaterThanOrEqualTo: (self.superview ?? self).topAnchor).isActive = true
        overlay.leftAnchor.constraint(greaterThanOrEqualTo: (self.superview ?? self).leftAnchor).isActive = true
        overlay.rightAnchor.constraint(lessThanOrEqualTo: (self.superview ?? self).rightAnchor).isActive = true
        overlays[key.type] = overlay
        
        let keyLabel = UILabel(frame: .zero)
        if case let .input(title) = key.type {
            keyLabel.text = title
        }
        keyLabel.textColor = KeyboardView.theme.textColor
        keyLabel.font = KeyboardView.theme.popupKeyFont
        keyLabel.textAlignment = .center
        keyLabel.translatesAutoresizingMaskIntoConstraints = false
        overlay.contentView.addSubview(keyLabel)
        keyLabel.fillSuperview(overlay.contentView)
        
        self.superview?.setNeedsLayout()
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
        if self.overlays.first?.value.contentView == nil {
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
        if let activeKey = activeKey,
            let longpressValues = (self.longpressController as? LongPressOverlayController)?.longpressValues {
                let count = longpressValues.count
            contentView.widthAnchor.constraint(equalToConstant: count >= LongPressOverlayController.multirowThreshold ? self.longpressKeySize().width * ceil(CGFloat(count)/2.0) + KeyboardView.theme.keyHorizontalMargin : self.longpressKeySize().width * CGFloat(count) + KeyboardView.theme.keyHorizontalMargin).isActive = true
            contentView.heightAnchor.constraint(equalToConstant: count >= LongPressOverlayController.multirowThreshold ? self.longpressKeySize().height * 2 : self.longpressKeySize().height).isActive = true
        } else {
            contentView.heightAnchor.constraint(equalToConstant: self.longpressKeySize().height).isActive = true
        }
        contentView.layoutIfNeeded()
    }
    
    func longpressDidCancel() {
        self.longpressController = nil
        self.collectionView.alpha = 1.0
    }
    
    func longpress(didSelectKey key: KeyDefinition) {
        delegate?.didTriggerKey(key)
        self.longpressController = nil
    }
    
    func longpressFrameOfReference() -> CGRect {
        return self.bounds
    }

    func longpressKeySize() -> CGSize {
        return CGSize(width: (self.bounds.size.width / CGFloat(currentPage.first?.count ?? 10)), height: (self.bounds.size.height / CGFloat(currentPage.count)) - KeyboardView.theme.popupCornerRadius * 2)
    }
    
    func longpress(movedCursor: Int) {
        delegate?.didMoveCursor(movedCursor)
    }

    
    // MARK: - Input handling
    // MARK: -
    
    struct KeyTriggerTiming {
        let time: TimeInterval
        let key: KeyDefinition
        
        static let doubleTapTime: TimeInterval = 0.4
        //static let longpressTime: TimeInterval = 0.9
    }
    
    var keyTriggerTiming: KeyTriggerTiming? = nil
    var keyRepeatTimer: Timer? = nil
    
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
    
    var activeKey: ActiveKey? = nil {
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

                keyRepeatTimer = Timer.scheduledTimer(timeInterval: KeyboardView.keyRepeatTimeInterval,
                                                      target: self,
                                                      selector: #selector(KeyboardView.keyRepeatTimerDidTrigger),
                                                      userInfo: nil, repeats: true)
            }
        }
        didSet {
            // Should show overlay?
            if let activeKey = activeKey,
                let cell = collectionView.cellForItem(at: activeKey.indexPath) as? KeyCell,
                activeKey.indexPath != oldValue?.indexPath {
                cell.keyView?.active = true
                if case .input(_) = activeKey.key.type, !swipeDownKeysEnabled {
                    showOverlay(forKeyAtIndexPath: activeKey.indexPath)
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
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

                // Doubletap
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
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Forward to longpress controller?
        if let longpressController = self.longpressController, let touch = touches.first {
            longpressController.touchesMoved(touch.location(in: collectionView))
            return
        }
        
        // Swipe key handling
        if self.swipeDownKeysEnabled {
            
            if let activeKey = activeKey,
                let cell = collectionView.cellForItem(at: activeKey.indexPath) as? KeyCell,
                let swipeKeyView = cell.keyView, swipeKeyView.isSwipeKey,
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
            }
            
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
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.longpressController = nil
        activeKey = nil
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
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
                    let alternateKey = self.validAlternateKey(forIndexPath: activeKey.indexPath),
                    swipeKeyView.isSwipeKey,
                    swipeKeyView.percentageAlternative > 0.5 {
                    
                    delegate?.didTriggerKey(alternateKey)
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
    
    @objc func touchesFoundLongpress(_ longpressGestureRecognizer: UILongPressGestureRecognizer) {
        if let indexPath = collectionView.indexPathForItem(at: longpressGestureRecognizer.location(in: collectionView)), longpressController == nil {

            let key = currentPage[indexPath.section][indexPath.row]
            switch (key.type) {
            case let .input(string):
                if let longpressValues = self.definition.longPress[string]?.compactMap({ KeyDefinition(input: $0) }),
                    longpressGestureRecognizer.state == .began {
                    
                    let longpressController = LongPressOverlayController(key: key, longpressValues: longpressValues)
                    longpressController.delegate = self
                    
                    self.longpressController = longpressController
                    
                    longpressController.touchesBegan(longpressGestureRecognizer.location(in: collectionView))
                }
            case .keyboardMode:
                if longpressGestureRecognizer.state == .began {
                    
                    let longpressController = LongPressOverlayController(key: key, longpressValues: [
                        KeyDefinition(type: .sideKeyboardLeft),
                        KeyDefinition(type: .splitKeyboard),
                        KeyDefinition(type: .sideKeyboardRight)
                        ])
                    longpressController.delegate = self
                    
                    self.longpressController = longpressController
                    
                    longpressController.touchesBegan(longpressGestureRecognizer.location(in: collectionView))
                }

            case .spacebar:
                if longpressGestureRecognizer.state == .began {
                    let longpressController = LongPressCursorMovementController()
                    longpressController.delegate = self
                    self.longpressController = longpressController
                    self.collectionView.alpha = 0.4
                }
            case .backspace:
                // Cancel, the repeat trigger timing deals with this
                break
            default:
                self.delegate?.didTriggerHoldKey(key)
            }
        }
    }
    
    @objc func keyRepeatTimerDidTrigger() {
        if let activeKey = activeKey, activeKey.key.type.supportsRepeatTrigger {
            delegate?.didTriggerKey(activeKey.key)
        }
    }
    
    // MARK: - CollectionView
    // MARK: -
    
    private var rowNumberOfUnits: [CGFloat]!
    
    private func calculateRows() {
        var mutableWidths = [CGFloat]()
        
        for row in currentPage {
            let numberOfUnits = row.reduce(0.0, { (sum, key) -> CGFloat in
                return sum + key.size.width
            })
            mutableWidths.append(numberOfUnits)
        }
        
        rowNumberOfUnits = mutableWidths
        
        collectionView.reloadData()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return currentPage.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentPage[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! KeyCell
        let key = currentPage[indexPath.section][indexPath.row]

        if key.type == .keyboard {
            keyboardButtonFrame = cell.frame
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! KeyCell
        let key = currentPage[indexPath.section][indexPath.row]
        
        if let alternateKey = self.validAlternateKey(forIndexPath: indexPath) {
            cell.setKey(key: key, alternateKey: alternateKey)

            if let swipeKeyView = cell.keyView, swipeKeyView.isSwipeKey {
                swipeKeyView.percentageAlternative = 0.0
            }
        } else if swipeDownKeysEnabled {
            cell.setKey(key: key, alternateKey: KeyDefinition(type: .spacer))
        } else {
            cell.setKey(key: key)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let key = currentPage[indexPath.section][indexPath.row]
        
        // Using self.bounds here, because self.collectionView.frame isnt correctly sized in iOS 10
        return CGSize(width: key.size.width * ((self.bounds.size.width - 1) / rowNumberOfUnits[indexPath.section]), height: self.bounds.size.height / CGFloat(currentPage.count))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func validAlternateKey(forIndexPath indexPath: IndexPath) -> KeyDefinition? {
        let key = currentPage[indexPath.section][indexPath.row]
        let alternatePage = self.keyDefinitionsForPage(self.page.alternatePage())
        
        if (swipeDownKeysEnabled && alternatePage.count > indexPath.section && alternatePage[indexPath.section].count > indexPath.row) {
            let alternateKey = alternatePage[indexPath.section][indexPath.row]
            
            if case .input(_) = key.type, case .input(_) = alternateKey.type {
                return alternateKey
            }
        }
        return nil
    }
    
    class KeyCell: UICollectionViewCell {
        var keyView: KeyView?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
        }
        
        func setKey(key: KeyDefinition, alternateKey: KeyDefinition? = nil) {
            let _ = self.contentView.subviews.forEach { (view) in
                view.removeFromSuperview()
            }
            self.keyView = nil
            
            if case .spacer = key.type {
                let emptyview = UIView(frame: .zero)
                emptyview.translatesAutoresizingMaskIntoConstraints = false
                emptyview.backgroundColor = .clear
                contentView.addSubview(emptyview)
                emptyview.fillSuperview(contentView)
            } else if let alternateKey = alternateKey, case .input = key.type, case .input = alternateKey.type, alternateKey.type != key.type {
                keyView = KeyView(key: key, alternateKey: alternateKey)
                keyView!.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview(keyView!)
                keyView!.fillSuperview(contentView)
            } else {
                if let _ = alternateKey {
                    keyView = KeyView(key: key, alternateKey: KeyDefinition(type: .spacer))
                } else {
                    keyView = KeyView(key: key)
                }
                keyView!.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview(keyView!)
                keyView!.fillSuperview(contentView)
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

class KeyView: UIView {
    private var key: KeyDefinition
    private var alternateKey: KeyDefinition?
    
    var isSwipeKey: Bool {
        if let alternateKey = self.alternateKey, let _ = self.alternateLabel, case .input(_) = alternateKey.type {
            return true
        } else {
            return false
        }
    }
    
    var label: UILabel?
    var alternateLabel: UILabel?
    
    var swipeLayoutConstraint: NSLayoutConstraint?
    
    var imageView: UIImageView?
    
    var active: Bool = false {
        didSet {
            if let contentView = self.contentView {
                
                let activeColor = key.type.isSpecialKeyStyle ? KeyboardView.theme.regularKeyColor : KeyboardView.theme.specialKeyColor
                let regularColor = key.type.isSpecialKeyStyle ? KeyboardView.theme.specialKeyColor : KeyboardView.theme.regularKeyColor
                
                contentView.backgroundColor = active ? activeColor : regularColor
            }
            if active == false {
                percentageAlternative = 0.0
            }
        }
    }
    
    var percentageAlternative: CGFloat = 0.0 {
        didSet {
            let minValue = self.frame.height / 3.0
            let maxValue = (self.frame.height / 3.0) * 2.0
            
            self.swipeLayoutConstraint?.constant = minValue + (maxValue - minValue) * percentageAlternative
            
            if isSwipeKey {
                self.alternateLabel?.textColor = UIColor.interpolate(from: KeyboardView.theme.inactiveTextColor, to: KeyboardView.theme.textColor, with: percentageAlternative)
                self.label?.textColor = UIColor.interpolate(from: KeyboardView.theme.textColor, to: UIColor.clear, with: percentageAlternative)
                
                let fontSizeDelta = KeyboardView.theme.keyFont.pointSize - KeyboardView.theme.alternateKeyFontSize
                self.alternateLabel?.font = KeyboardView.theme.keyFont.withSize(KeyboardView.theme.alternateKeyFontSize + fontSizeDelta * percentageAlternative)
                self.label?.font = KeyboardView.theme.keyFont.withSize(KeyboardView.theme.keyFont.pointSize - fontSizeDelta * percentageAlternative)
            }
        }
    }
    
    var contentView: UIView!

    init(key: KeyDefinition, alternateKey: KeyDefinition? = nil) {
        self.key = key
        self.alternateKey = alternateKey
        super.init(frame: .zero)
        
        // HACK: UIColor.clear here breaks indexPathForItemAtPoint:
        self.backgroundColor = UIColor.green.withAlphaComponent(0.01)
        
        // If the alternate key is not an input key, ignore it
        if let alternateKey = self.alternateKey, case .input(_) = alternateKey.type, case .input(_) = key.type {
            // Continue
        } else if let alternateKey = self.alternateKey, case .spacer = alternateKey.type, case .input(_) = key.type {
            // Continue
        } else {
            self.alternateKey = nil
        }
        
        switch key.type {
        case KeyType.input(let string), KeyType.spacebar(let string), KeyType.returnkey(let string):
            self.label = UILabel()
            if let _ = self.alternateKey {
                self.alternateLabel = UILabel(frame: .zero)
            }
            
            if let label = self.label {
                let labelHoldingView = UIView(frame: .zero)
                labelHoldingView.translatesAutoresizingMaskIntoConstraints = false
                labelHoldingView.backgroundColor = .clear
                
                label.textColor = KeyboardView.theme.textColor
                if case .input = key.type {
                    label.font = KeyboardView.theme.keyFont
                } else {
                    label.font = KeyboardView.theme.keyFont.withSize(KeyboardView.theme.alternateKeyFontSize)
                }
                label.text = string
                label.adjustsFontSizeToFitWidth = true
                label.numberOfLines = 0
                label.minimumScaleFactor = 0.4
                label.textAlignment = .center
                label.backgroundColor = .clear
                label.clipsToBounds = false
                label.translatesAutoresizingMaskIntoConstraints = false
                label.setContentHuggingPriority(.defaultLow, for: .horizontal)
                label.setContentHuggingPriority(.defaultLow, for: .vertical)
                
                if let alternateKey = self.alternateKey, let alternateLabel = self.alternateLabel, case .input(let alternateString) = alternateKey.type {
                    alternateLabel.textColor = KeyboardView.theme.inactiveTextColor
                    alternateLabel.font = KeyboardView.theme.keyFont
                    alternateLabel.text = alternateString
                    alternateLabel.adjustsFontSizeToFitWidth = true
                    alternateLabel.textAlignment = .center
                    alternateLabel.backgroundColor = .clear
                    alternateLabel.clipsToBounds = false
                    alternateLabel.translatesAutoresizingMaskIntoConstraints = false
                    alternateLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
                    alternateLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
                    
                    labelHoldingView.addSubview(alternateLabel)
                }

                
                labelHoldingView.addSubview(label)
                self.addSubview(labelHoldingView)
                label.centerXAnchor.constraint(equalTo: labelHoldingView.centerXAnchor).isActive = true
                label.widthAnchor.constraint(equalTo: label.heightAnchor).isActive = true
                
                if let alternateKey = self.alternateKey, let alternateLabel = self.alternateLabel, case .input(_) = alternateKey.type {
                    swipeLayoutConstraint = label.topAnchor.constraint(equalTo: labelHoldingView.topAnchor, constant: 24)
                    swipeLayoutConstraint?.isActive = true
                    
                    label.bottomAnchor.constraint(equalTo: labelHoldingView.bottomAnchor, constant: 0).isActive = true
                    alternateLabel.centerXAnchor.constraint(equalTo: labelHoldingView.centerXAnchor).isActive = true
                    alternateLabel.widthAnchor.constraint(equalTo: alternateLabel.heightAnchor).isActive = true
                    alternateLabel.topAnchor.constraint(equalTo: labelHoldingView.topAnchor, constant: 8).isActive = true
                    alternateLabel.bottomAnchor.constraint(equalTo: label.topAnchor).isActive = true
                } else if let alternateKey = self.alternateKey, case .spacer = alternateKey.type {
                    swipeLayoutConstraint = label.topAnchor.constraint(equalTo: labelHoldingView.topAnchor, constant: 24)
                    swipeLayoutConstraint?.isActive = true
                    
                    label.bottomAnchor.constraint(equalTo: labelHoldingView.bottomAnchor, constant: 0).isActive = true
                } else {
                    label.centerYAnchor.constraint(equalTo: labelHoldingView.centerYAnchor, constant: 0).isActive = true
                    label.widthAnchor.constraint(lessThanOrEqualTo: labelHoldingView.widthAnchor, multiplier: 1.0).isActive = true
                    swipeLayoutConstraint = nil
                }
                
                contentView = labelHoldingView
            }
        default:
            self.imageView = UIImageView()
            if let imageView = self.imageView {

                self.imageView?.translatesAutoresizingMaskIntoConstraints = false
                
                self.addSubview(imageView)
                
                contentView = imageView
            }
        }
        
        self.layer.shadowColor = KeyboardView.theme.keyShadowColor.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = 0.0

        contentView.fillSuperview(self, margins: UIEdgeInsets(top: KeyboardView.theme.keyVerticalMargin,
                                                              left: KeyboardView.theme.keyHorizontalMargin,
                                                              bottom: KeyboardView.theme.keyVerticalMargin,
                                                              right: KeyboardView.theme.keyHorizontalMargin))

        contentView.backgroundColor = key.type.isSpecialKeyStyle ? KeyboardView.theme.specialKeyColor : KeyboardView.theme.regularKeyColor

    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateSubviews()
    }
    
    func updateSubviews() {
        
        let percentageAlternative = self.percentageAlternative
        self.percentageAlternative = percentageAlternative
        
        if let subview = contentView {
            subview.layer.borderWidth = 1.0
            subview.layer.borderColor = (key.type.isSpecialKeyStyle ? KeyboardView.theme.specialKeyBorderColor : KeyboardView.theme.borderColor).cgColor
            subview.layer.cornerRadius = KeyboardView.theme.keyCornerRadius
            subview.clipsToBounds = true
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
