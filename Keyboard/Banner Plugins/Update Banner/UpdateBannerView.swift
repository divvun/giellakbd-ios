import Foundation

final class UpdateBannerView: UIView, BannerView {
    private let stackView = UIStackView()
    private let label = UILabel()
    private let activityIndicator = UIActivityIndicatorView()

    var text: String? {
        get { label.text }
        set { label.text = newValue }
    }

    init(theme: ThemeType) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupView()
    }

    private func setupView() {
        setupStackView()
        setupLabel()
        setupActivityIndicator()
    }

    private func setupStackView() {
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.centerXAnchor.constraint(equalTo: centerXAnchor).enable()
        stackView.centerYAnchor.constraint(equalTo: centerYAnchor).enable()
    }

    private func setupLabel() {
        stackView.addArrangedSubview(label)
        label.text = "Updating dictionaries"
    }

    private func setupActivityIndicator() {
        stackView.addArrangedSubview(activityIndicator)
        activityIndicator.startAnimating()
    }

    func updateTheme(_ theme: ThemeType) {

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
