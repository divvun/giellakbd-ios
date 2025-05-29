import Foundation

final class SpellerAvailableBannerView: UIView, BannerView {
    private let openButton = UIButton()
    private let label = UILabel()
    private let activityIndicator = UIActivityIndicatorView()

    init(theme: ThemeType) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupView()
    }

    private func setupView() {
        setupLabel()
        setupButton()
    }

    private func setupLabel() {
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = NSLocalizedString("Speller available. Tap to install.", comment: "")
        label.textAlignment = .center
        label.fill(superview: self)
    }

    private func setupButton() {
        addSubview(openButton)
        openButton.translatesAutoresizingMaskIntoConstraints = false
        openButton.fill(superview: self)
        openButton.addTarget(self, action: #selector(openHostingApp), for: .touchUpInside)
    }

    @objc func openHostingApp() {
        guard let urlScheme = Bundle.main.urlScheme else {
            return
        }
        let url = URL(string: "\(urlScheme)://openFromBanner")!
        URLOpener().aggresivelyOpenURL(url, responder: self)
    }

    func updateTheme(_ theme: ThemeType) {

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
