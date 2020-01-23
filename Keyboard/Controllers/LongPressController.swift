import UIKit

protocol LongPressOverlayDelegate {
    func longpress(didCreateOverlayContentView contentView: UIView)
    func longpressDidCancel()
    func longpress(didSelectKey key: KeyDefinition)

    func longpressFrameOfReference() -> CGRect
    func longpressKeySize() -> CGSize
}

protocol LongPressCursorMovementDelegate {
    func longpress(movedCursor: Int)
    func longpressDidCancel()
}

protocol LongPressBehaviorProvider {
    func touchesBegan(_ point: CGPoint)
    func touchesMoved(_ point: CGPoint)
    func touchesEnded(_ point: CGPoint)
}

class LongPressCursorMovementController: NSObject, LongPressBehaviorProvider {
    public var delegate: LongPressCursorMovementDelegate?

    private var baselinePoint: CGPoint?
    let delta: CGFloat = 20.0

    public func touchesBegan(_ point: CGPoint) {
        if baselinePoint == nil {
            baselinePoint = point
        }
        pointUpdated(point)
    }

    public func touchesMoved(_ point: CGPoint) {
        if baselinePoint == nil {
            baselinePoint = point
        }
        pointUpdated(point)
    }

    public func touchesEnded(_ point: CGPoint) {
        pointUpdated(point)
        delegate?.longpressDidCancel()
    }

    private func pointUpdated(_ point: CGPoint) {
        guard let baselinePoint = baselinePoint else { return }

        let diff = point.x - baselinePoint.x
        if abs(diff) > delta {
            let cursorMovement = Int((diff / delta).rounded(.towardZero))
            delegate?.longpress(movedCursor: cursorMovement)
            self.baselinePoint = CGPoint(x: baselinePoint.x + (delta * CGFloat(cursorMovement)), y: baselinePoint.y)
        }
    }
}

class LongPressOverlayController: NSObject, LongPressBehaviorProvider, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    class LongpressCollectionView: UICollectionView {}

    private let deadZone: CGFloat = 20.0

    private let key: KeyDefinition
    private let theme: ThemeType
    let longpressValues: [KeyDefinition]

    private var baselinePoint: CGPoint?
    private var collectionView: UICollectionView?

    private let reuseIdentifier = "longpressCell"

    private var selectedKey: KeyDefinition? {
        didSet {
            if selectedKey?.type != oldValue?.type {
                collectionView?.reloadData()
            }
        }
    }

    var delegate: LongPressOverlayDelegate?
    private let labelFont: UIFont

    init(key: KeyDefinition, page: KeyboardPage, theme: ThemeType, longpressValues: [KeyDefinition]) {
        self.key = key
        self.theme = theme
        self.longpressValues = longpressValues
        switch page {
        case .normal:
            labelFont = theme.popupLongpressLowerKeyFont
        default:
            labelFont = theme.popupLongpressCapitalKeyFont
        }
    }

    private func setup() {
        collectionView = LongpressCollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView?.register(LongpressKeyCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView?.translatesAutoresizingMaskIntoConstraints = false
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = .clear

        if let delegate = self.delegate {
            delegate.longpress(didCreateOverlayContentView: collectionView!)
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func touchesBegan(_ point: CGPoint) {
        if baselinePoint == nil {
            baselinePoint = point
            setup()
        }
        pointUpdated(point)
    }

    public func touchesMoved(_ point: CGPoint) {
        if baselinePoint == nil {
            baselinePoint = point
            setup()
        }
        pointUpdated(point)
    }

    public func touchesEnded(_ point: CGPoint) {
        pointUpdated(point)

        if let selectedKey = self.selectedKey {
            delegate?.longpress(didSelectKey: selectedKey)
        } else {
            delegate?.longpressDidCancel()
        }
    }

    private var isLogicallyIPad: Bool {
        return UIDevice.current.dc.deviceFamily == .iPad &&
            self.collectionView?.traitCollection.userInterfaceIdiom == .pad
    }

    private func longPressTouchPoint(at point: CGPoint, cellSize: CGSize, view collectionView: UICollectionView, parentView: UIView) -> CGPoint {
        // Calculate the long press finger position relative to the long press popup
        // This function returns a point that remains inside the popover. This way a long press key can remain selected even if the
        // user drags past the popover

        // This function returns a point that lies within the collection view's bounds.
        // It is used for keeping a letter selected in the popup even after a user's touch point falls outside of the collectionView.
        func pointInCollectionView(with point: CGPoint) -> CGPoint {
            let bounds = collectionView.bounds
            let halfWidth = cellSize.width / 2.0
            let halfHeight = cellSize.height / 2.0
            let heightOffset: CGFloat = isLogicallyIPad ? 0 : -halfHeight

            var x = point.x
            let minX = bounds.minX
            let maxX = bounds.maxX

            if x <= minX {
                x = minX + halfWidth
            } else if x >= maxX {
                x = maxX - halfWidth
            }

            var y = point.y + heightOffset
            let minY = collectionView.bounds.minY
            let maxY = collectionView.bounds.maxY

            if y <= minY {
                y = minY + halfHeight
            } else if y >= maxY {
                y = maxY - halfHeight
            }

            return CGPoint(x: x, y: y)
        }

        // Define a box in which touches to cause selection in the long press popup. Touches outside of this box will deselect keys in the popup.
        let selectionBox: CGRect = collectionView.frame.insetBy(dx: -cellSize.width, dy: -cellSize.height)

        let convertedPoint = parentView.convert(point, to: collectionView)
        if selectionBox.contains(convertedPoint) {
            // The touch was inside the selection box. Convert it to a point inside the collection view so a key is selected.
            return pointInCollectionView(with: convertedPoint)
        }

        // The point is outside the selection allowance box. Return what we got.
        return point
    }

    private func pointUpdated(_ point: CGPoint) {
        let cellSize = delegate?.longpressKeySize() ?? CGSize(width: 20, height: 30.0)
        let bigFrame = delegate!.longpressFrameOfReference()
        var superView: UIView? = collectionView

        repeat {
            superView = superView?.superview
        } while superView?.bounds != bigFrame && superView != nil

        guard let wholeView = superView else { return }
        guard let collectionView = self.collectionView else { return }

        let point = longPressTouchPoint(at: point, cellSize: cellSize, view: collectionView, parentView: wholeView)

        // TODO: Logic for multiline popups
        if let indexPath = collectionView.indexPathForItem(at: point) {
            selectedKey = longpressValues[indexPath.row + Int(ceil(Double(longpressValues.count) / 2.0)) * indexPath.section]
        } else {
            selectedKey = nil

            // TODO: Logic for canceling it
//            if false {
//                delegate?.longpressDidCancel()
//            }
        }
    }

    func numberOfSections(in _: UICollectionView) -> Int {
        return longpressValues.count > theme.popupLongpressKeysPerRow ? 2 : 1
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if longpressValues.count > theme.popupLongpressKeysPerRow {
            return section == 0 ? Int(ceil(Double(longpressValues.count) / 2.0)) : Int(floor(Double(longpressValues.count) / 2.0))
        }
        return longpressValues.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? LongpressKeyCell else {
            fatalError("Unable to cast to LongpressKeyCell")
        }
        cell.configure(theme: theme)
        let key = longpressValues[indexPath.row + Int(ceil(Double(longpressValues.count) / 2.0)) * indexPath.section]

        cell.label.font = labelFont

        if case let .input(string, _) = key.type {
            cell.label.text = string
            cell.imageView.image = nil
        } else if case .splitKeyboard = key.type {
            cell.label.text = nil
            cell.imageView.image = #imageLiteral(resourceName: "language")
        } else if case .sideKeyboardLeft = key.type {
            cell.label.text = nil
            cell.imageView.image = #imageLiteral(resourceName: "tap")
        } else if case .sideKeyboardRight = key.type {
            cell.label.text = nil
            cell.imageView.image = #imageLiteral(resourceName: "gear")
        } else {
            print("ERROR: Invalid key type in longpress")
        }

        if key.type == selectedKey?.type {
            cell.select(theme: theme)
        } else {
            cell.deselect(theme: theme)
        }

        return cell
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        return delegate?.longpressKeySize() ?? CGSize(width: 20, height: 30.0)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumInteritemSpacingForSectionAt _: Int) -> CGFloat {
        return 0
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumLineSpacingForSectionAt _: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, insetForSectionAt _: Int) -> UIEdgeInsets {
        let cellSize = delegate?.longpressKeySize() ?? CGSize(width: 20.0, height: 30.0)
        let cellWidth = cellSize.width
        let numberOfCells = CGFloat(longpressValues.count)

        guard numberOfCells <= 1 else { return .zero }

        // Center single cells
        let edgeInsets = (collectionView.frame.size.width - (numberOfCells * cellWidth)) / (numberOfCells + 1)
        return UIEdgeInsets(top: 0, left: edgeInsets, bottom: 0, right: edgeInsets)
    }

    class LongpressKeyCell: UICollectionViewCell {
        let label: UILabel
        let imageView: UIImageView

        private(set) var isSelectedKey: Bool = false
//            didSet {
//                label.textColor = isSelectedKey ? theme.activeTextColor : theme.textColor
//                label.backgroundColor = isSelectedKey ? theme.activeColor : theme.popupColor
//            }
//        }

        func select(theme: ThemeType) {
            label.textColor = theme.activeTextColor
            label.backgroundColor = theme.activeColor
            isSelectedKey = true
        }

        func deselect(theme: ThemeType) {
            label.textColor = theme.textColor
            label.backgroundColor = theme.popupColor
            isSelectedKey = false
        }

        override init(frame: CGRect) {
            label = UILabel(frame: frame)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.clipsToBounds = true

            imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFit

            super.init(frame: frame)

            addSubview(label)
            addSubview(imageView)
            imageView.fill(superview: self)
            label.fill(superview: self)
        }

        func configure(theme: ThemeType) {
            label.layer.cornerRadius = theme.keyCornerRadius
            imageView.tintColor = theme.textColor
        }

        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
