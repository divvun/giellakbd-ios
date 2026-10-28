import Sentry
import UIKit

final class TestingController: ViewController<TestingView> {
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Testing"
        addSentryCrashButton()
    }

    /// Adds a button that deliberately crashes the app so crash reporting can be verified end to end in Sentry.
    private func addSentryCrashButton() {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Crash App (Sentry Test)"
        configuration.baseBackgroundColor = .systemRed

        let button = UIButton(configuration: configuration, primaryAction: UIAction { [weak self] _ in
            self?.confirmSentryCrash()
        })
        button.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(button)

        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -32)
        ])
    }

    private func confirmSentryCrash() {
        let message = SentrySDK.isEnabled
            ? "The app will crash immediately. Sentry sends the crash report the next time you open the app."
            : "Sentry is not running because this build has no DSN, so this crash will not be reported."

        let alert = UIAlertController(title: "Crash the app?", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Crash", style: .destructive) { _ in
            SentrySDK.crash()
        })
        present(alert, animated: true)
    }
}
