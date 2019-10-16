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

    static let multirowThreshold = 4

    private let deadZone: CGFloat = 20.0

    let key: KeyDefinition
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

    init(key: KeyDefinition, longpressValues: [KeyDefinition]) {
        self.key = key
        self.longpressValues = longpressValues
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

    private func pointUpdated(_ point: CGPoint) {
        let cellSize = delegate?.longpressKeySize() ?? CGSize(width: 20, height: 30.0)
        let bigFrame = delegate!.longpressFrameOfReference()
        var superView: UIView? = collectionView

        repeat {
            superView = superView?.superview
        } while superView?.bounds != bigFrame && superView != nil

        guard let wholeView = superView else { return }
        guard let collectionView = self.collectionView else { return }

        let frame = wholeView.convert(collectionView.frame, from: collectionView.superview)

        // TODO: Logic for multiline popups
        if let indexPath = collectionView.indexPathForItem(at: CGPoint(x: min(max(point.x - frame.minX, collectionView.bounds.minX + cellSize.width / 2.0), collectionView.bounds.maxX - cellSize.width / 2.0),
                                                                       y: min(max(point.y - (UIDevice.current.kind == .iPad ? -cellSize.width / 2.0 : (baselinePoint?.y ?? 0)),
                                                                                  collectionView.bounds.minY + cellSize.height / 2.0), collectionView.bounds.maxY - cellSize.height / 2.0))) {
            selectedKey = longpressValues[indexPath.row + Int(ceil(Double(longpressValues.count) / 2.0)) * indexPath.section]
        } else {
            selectedKey = nil

            // TODO: Logic for canceling it
            if false {
                delegate?.longpressDidCancel()
            }
        }
    }

    func numberOfSections(in _: UICollectionView) -> Int {
        return longpressValues.count >= LongPressOverlayController.multirowThreshold ? 2 : 1
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if longpressValues.count >= LongPressOverlayController.multirowThreshold {
            return section == 0 ? Int(ceil(Double(longpressValues.count) / 2.0)) : Int(floor(Double(longpressValues.count) / 2.0))
        }
        return longpressValues.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! LongpressKeyCell
        let key = longpressValues[indexPath.row + Int(ceil(Double(longpressValues.count) / 2.0)) * indexPath.section]

        if case let .input(string) = key.type {
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

        cell.isSelectedKey = key.type == selectedKey?.type

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
        let cellSize = delegate?.longpressKeySize() ?? CGSize(width: 20, height: 30.0)
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
        var isSelectedKey: Bool = false {
            didSet {
                label.textColor = isSelectedKey ? KeyboardView.theme.activeTextColor : KeyboardView.theme.textColor
                label.backgroundColor = isSelectedKey ? KeyboardView.theme.activeColor : KeyboardView.theme.popupColor
            }
        }

        override init(frame: CGRect) {
            label = UILabel(frame: frame)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.layer.cornerRadius = KeyboardView.theme.keyCornerRadius
            label.clipsToBounds = true
            
            imageView = UIImageView()
            imageView.tintColor = KeyboardView.theme.textColor
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFit
            
            super.init(frame: frame)
            addSubview(label)
            addSubview(imageView)
            imageView.fillSuperview(self)
            label.fillSuperview(self)
        }

        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
