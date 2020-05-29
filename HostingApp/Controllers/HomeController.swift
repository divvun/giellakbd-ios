import UIKit
import RxSwift

final class HomeController: ViewController<HomeView>, HideNavBar {
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

        #if ENABLE_USER_DICTIONARY
        #else
        contentView.settingsButton.isHidden = true
        #endif
    }

    func setProgress(value: String) {
        DispatchQueue.main.async {
            self.contentView.mainStack?.isHidden = true
            self.contentView.progressView?.isHidden = false

            self.contentView.progressLabel?.text = value
        }
    }

    func hideProgress() {
        DispatchQueue.main.async {
            self.contentView.progressView?.isHidden = true
            self.contentView.mainStack?.isHidden = false
        }
    }

    private let bag = DisposeBag()

    private var doingPahkat = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if doingPahkat {
            return
        }

        if let pahkat = AppDelegate.instance.pahkat {
            DispatchQueue.global(qos: .userInitiated).async {
                pahkat.checkForSpellerUpdates(logger: { [weak self] message in
                    self?.setProgress(value: message)
                }).subscribe(onSuccess: { [weak self] _ in
                    self?.hideProgress()
                    self?.doingPahkat  = false
                }, onError: { [weak self] error in
                    self?.setProgress(value: "Error: \(error)")
                    self?.doingPahkat = false
                }).disposed(by: self.bag)
            }
        }

        doingPahkat = true
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
