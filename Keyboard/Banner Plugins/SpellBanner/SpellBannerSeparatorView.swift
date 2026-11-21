import UIKit

/// A line between two banner suggestions. Drawn with the theme its `SpellBannerSeparatorAttributes` carry.
final class SpellBannerSeparatorView: UICollectionReusableView {
    private let separatorLine = UIView()
    /// Puts the line where it lines up with the system keyboard's separators, or centres it in the banner.
    private var bottomConstraint: NSLayoutConstraint!
    private var centerConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)

        translatesAutoresizingMaskIntoConstraints = false
        setupSeparatorLine()
    }

    private func setupSeparatorLine() {
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorLine)
        // As tall as the system keyboard's separators where the banner has room, otherwise as tall as the banner.
        separatorLine.leadingAnchor.constraint(equalTo: leadingAnchor).enable()
        separatorLine.trailingAnchor.constraint(equalTo: trailingAnchor).enable()
        separatorLine.topAnchor.constraint(greaterThanOrEqualTo: topAnchor).enable()
        separatorLine.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor).enable()
        separatorLine.heightAnchor.constraint(equalToConstant: SpellBannerCell.separatorHeight).enable(priority: .defaultHigh)
        bottomConstraint = separatorLine.bottomAnchor.constraint(equalTo: bottomAnchor)
        bottomConstraint.priority = .defaultHigh
        centerConstraint = separatorLine.centerYAnchor.constraint(equalTo: centerYAnchor).enable()
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        guard let attributes = layoutAttributes as? SpellBannerSeparatorAttributes else {
            return
        }
        backgroundColor = attributes.backgroundColor
        separatorLine.backgroundColor = attributes.lineColor
        if let bottomInset = attributes.bottomInset {
            centerConstraint.isActive = false
            bottomConstraint.constant = -bottomInset
            bottomConstraint.isActive = true
        } else {
            bottomConstraint.isActive = false
            centerConstraint.isActive = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
