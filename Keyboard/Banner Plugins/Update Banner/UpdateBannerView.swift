import Foundation

final class UpdateBannerView: UIView, BannerView {
    private let label = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .bar)

    var progress: Float {
        get { progressView.progress }
        set { progressView.setProgress(newValue, animated: true) }
    }

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
        setupProgressView()
        setupLabel()
    }

    private func setupProgressView() {
        addSubview(progressView)

        progressView.translatesAutoresizingMaskIntoConstraints = false

        progressView.topAnchor.constraint(equalTo: topAnchor).enable()
        progressView.leadingAnchor.constraint(equalTo: leadingAnchor).enable()
        progressView.trailingAnchor.constraint(equalTo: trailingAnchor).enable()
    }

    private func setupLabel() {
        addSubview(label)

        label.text = "Updating dictionaries..." // testing; delete me
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        label.topAnchor.constraint(equalTo: progressView.topAnchor).enable()
        label.leadingAnchor.constraint(equalTo: leadingAnchor).enable()
        label.trailingAnchor.constraint(equalTo: trailingAnchor).enable()
        label.bottomAnchor.constraint(equalTo: bottomAnchor).enable()
    }

    func updateTheme(_ theme: ThemeType) {

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
