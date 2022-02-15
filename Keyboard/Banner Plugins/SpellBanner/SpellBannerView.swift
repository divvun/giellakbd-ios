import UIKit
import DivvunSpell

public struct SpellBannerItem {
    public let title: NSAttributedString
    public let value: NSAttributedString
}

public protocol SpellBannerViewDelegate: class {
    func didSelectBannerItem(_ banner: SpellBannerView, item: SpellBannerItem)
}

public final class SpellBannerView: UIView, BannerView {
    weak public var delegate: SpellBannerViewDelegate?

    private var theme: ThemeType
    private let numberOfSuggestions = 3
    private var items: [SpellBannerItem?] = [SpellBannerItem]()

    private var collectionView: UICollectionView!
    private let reuseIdentifier = "bannercell"

    public func setBannerItems(_ items: [SpellBannerItem]) {
        if items.count >= numberOfSuggestions {
            self.items = Array(items.prefix(numberOfSuggestions))
        } else {
            self.items = [SpellBannerItem?].init(repeating: nil, count: numberOfSuggestions)
            self.items.replaceSubrange(0..<items.count, with: items)
        }
        collectionView.reloadData()
    }

    public func clearSuggestions() {
        setBannerItems([])
    }

    public override func layoutSubviews() {
        // Because just invalidateLayout() seems to keep some weird cache, so we need to reset it fully
        collectionView.collectionViewLayout = makeCollectionViewLayout()
        super.layoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func makeCollectionViewLayout() -> UICollectionViewFlowLayout {
        let flowLayout = SpellBannerFlowLayout()
        flowLayout.estimatedItemSize = CGSize(width: 1, height: 1)
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumInteritemSpacing = 1
        flowLayout.minimumLineSpacing = 1

        return flowLayout
    }

    init(theme: ThemeType) {
        self.theme = theme
        super.init(frame: .zero)
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
        collectionView = makeCollectionView()
    }

    private func makeCollectionView() -> UICollectionView {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeCollectionViewLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)
        collectionView.fill(superview: self)
        collectionView.register(SpellBannerCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.backgroundColor = theme.bannerBackgroundColor
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = false
        collectionView.delegate = self
        collectionView.dataSource = self

        return collectionView
    }

    func updateTheme(_ theme: ThemeType) {
        collectionView.removeFromSuperview()
        collectionView = makeCollectionView()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SpellBannerView: UICollectionViewDataSource {
    public func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                            for: indexPath) as? SpellBannerCell else {
                                                                fatalError("Unable to cast to BannerCell")
        }
        cell.configure(theme: theme)
        cell.set(item: items[indexPath.item])

        return cell
    }
}

extension SpellBannerView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        guard let item = items[indexPath.item] else {
            return
        }
        delegate?.didSelectBannerItem(self, item: item)
    }
}

extension SpellBannerView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               layout _: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        let title = items[indexPath.item]?.title ?? NSAttributedString(string: "")

        // It is constrained by infinity so it isn't constrained.
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: collectionView.frame.height)
        let boundingBox = title.boundingRect(with: constraintRect,
                                             options: .usesLineFragmentOrigin,
//                                             attributes: [NSAttributedString.Key.font: theme.bannerFont],
                                             context: nil)

        return CGSize(width: max(frame.width / 3.0,
                                 boundingBox.width + theme.bannerHorizontalMargin * 2),
                      height: collectionView.frame.height)
    }
}
