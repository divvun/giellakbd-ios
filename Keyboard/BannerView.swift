//
//  BannerView.swift
//  RewriteKeyboard
//
//  Created by Ville Petersson on 2019-07-29.
//  Copyright © 2019 The Techno Creatives AB. All rights reserved.
//

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
            self.titleLabel = UILabel(frame: frame)
            super.init(frame: frame)

            self.contentView.translatesAutoresizingMaskIntoConstraints = false
            self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
            self.contentView.fillSuperview(self)
            self.contentView.addSubview(self.titleLabel)

            self.titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: KeyboardView.theme.bannerVerticalMargin).isActive = true
            self.titleLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -KeyboardView.theme.bannerVerticalMargin).isActive = true
            self.titleLabel.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
            self.titleLabel.font = KeyboardView.theme.bannerFont
            self.titleLabel.textAlignment = .center

            heightConstraint = contentView.heightAnchor.constraint(equalToConstant: 0)
        }

        override func updateConstraints() {
            // Set width constraint to superview's width.
            heightConstraint?.constant = superview?.bounds.height ?? 0
            heightConstraint?.isActive = true

            self.backgroundColor = KeyboardView.theme.bannerBackgroundColor
            self.titleLabel.textColor = KeyboardView.theme.bannerTextColor

            super.updateConstraints()
        }

        func setItem(_ item: BannerItem) {
            self.titleLabel.text = item.title
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    public var delegate: BannerViewDelegate?

    public var items: [BannerItem] = [BannerItem]() {
        didSet {
            self.collectionView.reloadData()
        }
    }

    private let collectionView: UICollectionView
    private let reuseIdentifier = "bannercell"

    override public func layoutSubviews() {
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
        self.collectionView = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewFlowLayout())
        super.init(frame: frame)
        self.backgroundColor = .clear

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.collectionView)
        self.collectionView.fillSuperview(self)
        self.collectionView.register(BannerCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView.backgroundColor = KeyboardView.theme.bannerSeparatorColor
        self.collectionView.showsHorizontalScrollIndicator = false
        self.collectionView.bounces = false
        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        self.collectionView.collectionViewLayout = createCollectionViewLayout()
    }

    func update() {
        self.collectionView.backgroundColor = KeyboardView.theme.bannerSeparatorColor
        self.collectionView.reloadData()
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BannerCell
        cell.setItem(items[indexPath.item])

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let title = items[indexPath.item].title
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: collectionView.frame.height)
        let boundingBox = title.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: KeyboardView.theme.bannerFont], context: nil)

        return CGSize(width: max(self.frame.width/3.0, boundingBox.width + KeyboardView.theme.bannerHorizontalMargin * 2), height: collectionView.frame.height)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        self.delegate?.didSelectBannerItem(self, item: items[indexPath.item])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
