import UIKit

final class InstructionsController: ViewController<InstructionsView> {
    @objc private func openLanguages() {
        navigationController?.pushViewController(LanguagesController(), animated: true)
    }

    @objc private func applicationDidBecomeActive() {
        checkCurrentStep()
    }

    @objc private func onSkipTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func onSettingsTapped() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
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

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "language")!.with(width: 24, height: 24),
            style: .plain,
            target: self,
            action: #selector(openLanguages)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.skip,
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(onSkipTapped))
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
