import UIKit

final class SpellBannerSeparatorView: UICollectionReusableView {
    // This is dirty. Ideally we'd get this from the theme already created and being passed around,
    // but since this view is initialized by the system, there seemed no elegant way to do that.
    private(set) lazy var theme: Theme = {
        Theme.current(for: self.traitCollection, device: DeviceContext.current(in: self))
    }()

    private let separatorLine = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = theme.bannerBackgroundColor

        setupSeparatorLine()
    }

    private func setupSeparatorLine() {
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorLine)
        // As tall as the system keyboard's separators where the banner has room, otherwise as tall as the banner.
        separatorLine.leadingAnchor.constraint(equalTo: leadingAnchor).enable()
        separatorLine.trailingAnchor.constraint(equalTo: trailingAnchor).enable()
        if let bottomInset = theme.bannerSeparatorBottomInset {
            separatorLine.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -bottomInset).enable(priority: .defaultHigh)
            separatorLine.topAnchor.constraint(greaterThanOrEqualTo: topAnchor).enable()
        } else {
            separatorLine.centerYAnchor.constraint(equalTo: centerYAnchor).enable()
        }
        separatorLine.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor).enable()
        separatorLine.heightAnchor.constraint(equalToConstant: SpellBannerCell.separatorHeight).enable(priority: .defaultHigh)
        separatorLine.backgroundColor = theme.bannerSeparatorColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
