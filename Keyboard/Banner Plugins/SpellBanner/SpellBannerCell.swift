import UIKit

final class SpellBannerCell: UICollectionViewCell {
    private let titleLabel = UILabel()

    private var topConstraint: NSLayoutConstraint!
    private var bottomConstraint: NSLayoutConstraint!
    private var heightConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        topConstraint = titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor)
        bottomConstraint = titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        heightConstraint = contentView.heightAnchor.constraint(equalToConstant: 0)

        // Build the view hierarchy and constraints once. `configure(theme:)` runs on every reload,
        // so anything it adds would pile up for as long as the keyboard is open.
        contentView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.fill(superview: self)
        contentView.addSubview(titleLabel)

        topConstraint.isActive = true
        bottomConstraint.isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).enable()
        titleLabel.textAlignment = .center

        backgroundColor = UIColor.white.withAlphaComponent(0.001)
    }

    func configure(theme: Theme) {
        isHidden = false
        topConstraint.constant = theme.bannerVerticalMargin
        bottomConstraint.constant = -theme.bannerVerticalMargin
        titleLabel.font = theme.bannerFont
        titleLabel.textColor = theme.bannerTextColor
    }

    override func updateConstraints() {
        // Set width constraint to superview's width.
        heightConstraint.constant = superview?.bounds.height ?? 0
        heightConstraint.isActive = true

        super.updateConstraints()
    }

    func set(item: SpellBannerItem?) {
        titleLabel.attributedText = Self.title(for: item)
    }

    /// The text shown for an item. Parts without a font of their own use the banner font.
    static func title(for item: SpellBannerItem?) -> NSAttributedString {
        guard let item = item else {
            return NSAttributedString(string: "")
        }
        switch item.title {
        case .humanInput(let x, let isCorrect):
            if isCorrect {
                return "\"\(x)\"".bolden(substring: x)
            } else {
                return NSAttributedString(string: "\"\(x)\"")
            }
        case .normal(let x):
            return NSAttributedString(string: x)
        case .correction(let x):
            return x.bolden(substring: x)
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
