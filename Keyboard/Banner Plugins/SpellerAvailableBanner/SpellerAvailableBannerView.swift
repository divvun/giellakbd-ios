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
        // TODO: localise!!
        label.text = "Speller available. Tap to install."
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
        openURL(URL(string: "\(urlScheme)://openFromBanner")!)
    }

    @discardableResult
    @objc func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                return application.perform(#selector(openURL(_:)), with: url) != nil
            }
            responder = responder?.next
        }
        return false
    }

    func updateTheme(_ theme: ThemeType) {

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
