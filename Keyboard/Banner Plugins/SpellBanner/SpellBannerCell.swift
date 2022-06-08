import UIKit

final class SpellBannerCell: UICollectionViewCell {
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

    func set(item: SpellBannerItem?) {
        guard let item = item else {
            titleLabel.attributedText = NSAttributedString(string: "")
            return
        }
        switch item.title {
        case .humanInput(let x, let isCorrect):
            if isCorrect {
                titleLabel.attributedText = "\"\(x)\"".bolden(substring: x)
            } else {
                titleLabel.attributedText = NSAttributedString(string: "\"\(x)\"")
            }
        case .normal(let x):
            titleLabel.attributedText = NSAttributedString(string: x)
        case .correction(let x):
            titleLabel.attributedText = x.bolden(substring: x)
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
