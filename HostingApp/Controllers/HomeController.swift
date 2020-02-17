import UIKit

class HomeController: ViewController<HomeView>, HideNavBar {
    @objc private func openLanguages() {
        navigationController?.pushViewController(LanguagesController(), animated: true)
    }

    @objc private func openInstructions() {
        navigationController?.pushViewController(InstructionsController(), animated: true)
    }

    @objc private func openAbout() {
        navigationController?.pushViewController(AboutController(), animated: true)
    }

    @objc private func openTesting() {
        navigationController?.pushViewController(TestingController(), animated: true)
    }

    @objc private func openSettings() {
        navigationController?.pushViewController(SettingsViewController(), animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        refreshUI()
        contentView.awakeFromNib()
    }

    @objc private func refreshUI() {
        contentView.configStack?.isHidden = AppDelegate.instance.isKeyboardEnabled
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Strings.localizedName

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshUI),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)

        contentView.langButton.addTarget(self, action: #selector(openLanguages), for: [.touchUpInside])
        contentView.langButton2.addTarget(self, action: #selector(openLanguages), for: [.touchUpInside])
        contentView.helpButton.addTarget(self, action: #selector(openInstructions), for: [.touchUpInside])
        contentView.aboutButton.addTarget(self, action: #selector(openAbout), for: [.touchUpInside])
        contentView.testingButton.addTarget(self, action: #selector(openTesting), for: [.touchUpInside])
        contentView.settingsButton.addTarget(self, action: #selector(openSettings), for: [.touchUpInside])
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
