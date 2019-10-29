import UIKit

public struct BannerItem {
    public let title: String
    public let value: Any?
}

public protocol BannerViewDelegate {
    func textInputDidChange(_ banner: BannerView, context: CursorContext)
    func didSelectBannerItem(_ banner: BannerView, item: BannerItem)
}

public class BannerView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    private var theme: ThemeType
    
    class BannerCell: UICollectionViewCell {
        private let titleLabel: UILabel

        private var heightConstraint: NSLayoutConstraint?
        private var widthConstraint: NSLayoutConstraint?

        override init(frame: CGRect) {
            titleLabel = UILabel(frame: frame)
            
            super.init(frame: frame)
        }
        
        func configure(theme: ThemeType) {
            isHidden = false
            contentView.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            contentView.fill(superview: self)
            contentView.addSubview(titleLabel)

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: theme.bannerVerticalMargin).isActive = true
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -theme.bannerVerticalMargin).isActive = true
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
            titleLabel.font = theme.bannerFont
            titleLabel.textAlignment = .center

            backgroundColor = theme.bannerBackgroundColor
            titleLabel.textColor = theme.bannerTextColor

            heightConstraint = contentView.heightAnchor.constraint(equalToConstant: 0)
        }

        override func updateConstraints() {
            // Set width constraint to superview's width.
            heightConstraint?.constant = superview?.bounds.height ?? 0
            heightConstraint?.isActive = true

            super.updateConstraints()
        }

        func set(item: BannerItem) {
            titleLabel.text = item.title
        }

        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    public var delegate: BannerViewDelegate?

    public var items: [BannerItem] = [BannerItem]() {
        didSet {
            collectionView.reloadData()
        }
    }

    private let collectionView: UICollectionView
    private let reuseIdentifier = "bannercell"

    public override func layoutSubviews() {
        // Because just invalidateLayout() seems to keep some weird cache, so we need to reset it fully
        collectionView.collectionViewLayout = createCollectionViewLayout()

        super.layoutSubviews()

        collectionView.collectionViewLayout.invalidateLayout()
    }

    func createCollectionViewLayout() -> UICollectionViewFlowLayout {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.estimatedItemSize = CGSize(width: 1, height: 1)
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumInteritemSpacing = 1
        flowLayout.minimumLineSpacing = 1

        return flowLayout
    }

    init(theme: ThemeType) {
        self.theme = theme
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        super.init(frame: .zero)
        backgroundColor = .clear

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)
        collectionView.fill(superview: self)
        collectionView.register(BannerCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.backgroundColor = theme.bannerSeparatorColor
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = false
        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.collectionViewLayout = createCollectionViewLayout()
    }
    
    func updateTheme(theme: ThemeType) {
        self.theme = theme
        update()
    }

    func update() {
        collectionView.backgroundColor = theme.bannerSeparatorColor
        collectionView.reloadData()
    }

    public func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BannerCell
        cell.configure(theme: theme)
        cell.set(item: items[indexPath.item])

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let title = items[indexPath.item].title
        
        // It is constrained by infinity so it isn't constrained.
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: collectionView.frame.height)
        let boundingBox = title.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: theme.bannerFont], context: nil)

        return CGSize(width: max(frame.width / 3.0, boundingBox.width + theme.bannerHorizontalMargin * 2), height: collectionView.frame.height)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        delegate?.didSelectBannerItem(self, item: items[indexPath.item])
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
