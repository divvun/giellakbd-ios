import UIKit

class InstructionsController: ViewController<InstructionsView> {
    @objc private func openLanguages() {
        navigationController?.pushViewController(LanguagesController(), animated: true)
    }

    @objc private func applicationDidBecomeActive() {
        checkCurrentStep()
    }

    @objc private func onSkipTapped() {
        navigationController?.popViewController(animated: true)
    }

    private let prefsUrlIOS10 = "QXBwLVByZWZzOnJvb3Q9R2VuZXJhbCZwYXRoPUtleWJvYXJkL0tFWUJPQVJEUwo="
    private let prefsUrlIOS9 = "cHJlZnM6cm9vdD1HZW5lcmFsJnBhdGg9S2V5Ym9hcmQvS0VZQk9BUkRTCg=="

    @objc private func onSettingsTapped() {
        let application = UIApplication.shared

        if #available(iOS 11.0, *) {
            application.openURL(URL(string: UIApplication.openSettingsURLString)!)
        } else if #available(iOS 10.0, *) {
            let url = String(data: Data(base64Encoded: prefsUrlIOS10)!, encoding: .utf8)!
            application.openURL(URL(string: url.trimmingCharacters(in: .whitespacesAndNewlines))!)
        } else {
            let url = String(data: Data(base64Encoded: prefsUrlIOS9)!, encoding: .utf8)!
            application.openURL(URL(string: url.trimmingCharacters(in: .whitespacesAndNewlines))!)
        }
    }

    func checkCurrentStep() {
        if AppDelegate.instance.isKeyboardEnabled {
            onSkipTapped()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        contentView.bgImage.isHidden = false

        title = Strings.settingUp
        contentView.awakeFromNib()
        checkCurrentStep()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Stops ugly transition
        contentView.bgImage.isHidden = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        contentView.settingsButton.addTarget(self, action: #selector(onSettingsTapped), for: .touchUpInside)

        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "language")!.with(width: 24, height: 24),
            style: .plain,
            target: self,
            action: #selector(openLanguages)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.skip, style: .plain, target: self, action: #selector(onSkipTapped))
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
