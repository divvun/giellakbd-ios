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
    class BannerCell: UICollectionViewCell {
        let titleLabel: UILabel

        private var heightConstraint: NSLayoutConstraint?
        private var widthConstraint: NSLayoutConstraint?

        override init(frame: CGRect) {
            titleLabel = UILabel(frame: frame)
            
            super.init(frame: frame)
            
            isHidden = false
            contentView.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            contentView.fillSuperview(self)
            contentView.addSubview(titleLabel)

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: KeyboardView.theme.bannerVerticalMargin).isActive = true
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -KeyboardView.theme.bannerVerticalMargin).isActive = true
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
            titleLabel.font = KeyboardView.theme.bannerFont
            titleLabel.textAlignment = .center

            heightConstraint = contentView.heightAnchor.constraint(equalToConstant: 0)
        }

        override func updateConstraints() {
            // Set width constraint to superview's width.
            heightConstraint?.constant = superview?.bounds.height ?? 0
            heightConstraint?.isActive = true

            backgroundColor = KeyboardView.theme.bannerBackgroundColor
            titleLabel.textColor = KeyboardView.theme.bannerTextColor

            super.updateConstraints()
        }

        func setItem(_ item: BannerItem) {
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

    override init(frame: CGRect) {
        collectionView = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewFlowLayout())
        super.init(frame: frame)
        backgroundColor = .clear

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)
        collectionView.fillSuperview(self)
        collectionView.register(BannerCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.backgroundColor = KeyboardView.theme.bannerSeparatorColor
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = false
        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.collectionViewLayout = createCollectionViewLayout()
    }

    func update() {
        collectionView.backgroundColor = KeyboardView.theme.bannerSeparatorColor
        collectionView.reloadData()
    }

    public func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BannerCell
        cell.setItem(items[indexPath.item])

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let title = items[indexPath.item].title
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: collectionView.frame.height)
        let boundingBox = title.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: KeyboardView.theme.bannerFont], context: nil)

        return CGSize(width: max(frame.width / 3.0, boundingBox.width + KeyboardView.theme.bannerHorizontalMargin * 2), height: collectionView.frame.height)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        delegate?.didSelectBannerItem(self, item: items[indexPath.item])
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
