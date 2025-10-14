import UIKit

final class SpellBannerSeparatorView: UICollectionReusableView {
    // This is dirty. Ideally we'd get this from the theme already created and being passed around,
    // but since this view is initialized by the system, there seemed no elegant way to do that.
    private lazy var deviceContext: DeviceContext = { DeviceContext.current() }()
    private lazy var baseTheme: Theme = { Theme.create(for: self.deviceContext) }()
    private(set) lazy var theme: ThemeType = {
        baseTheme.select(traits: self.traitCollection)
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
        let paddingY: CGFloat = 12
        separatorLine.fill(superview: self, margins: UIEdgeInsets(top: paddingY, left: 0, bottom: paddingY, right: 0))
        separatorLine.backgroundColor = theme.bannerSeparatorColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
