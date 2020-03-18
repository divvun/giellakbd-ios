import UIKit

class DivvunSpellBannerCell: UICollectionViewCell {
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

        titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: theme.bannerVerticalMargin).enable()
        titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                           constant: -theme.bannerVerticalMargin).enable()
        titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).enable()
        titleLabel.font = theme.bannerFont
        titleLabel.textAlignment = .center

        backgroundColor = UIColor.white.withAlphaComponent(0.001)
        titleLabel.textColor = theme.bannerTextColor

        heightConstraint = contentView.heightAnchor.constraint(equalToConstant: 0)
    }

    override func updateConstraints() {
        // Set width constraint to superview's width.
        heightConstraint?.constant = superview?.bounds.height ?? 0
        heightConstraint?.isActive = true

        super.updateConstraints()
    }

    func set(item: BannerItem?) {
        guard let item = item else {
            titleLabel.text = ""
            return
        }
        titleLabel.text = item.title
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
