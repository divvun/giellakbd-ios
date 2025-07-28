import UIKit
import RxSwift

final class HomeController: ViewController<HomeView>, HideNavBar {
    @objc private func openLanguages() {
        navigationController?.pushViewController(LanguagesController(), animated: true)
    }

    @objc private func openInstructions() {
        navigationController?.pushViewController(InstructionsController(), animated: true)
    }

    @objc private func openKeyboardSettings() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }

    @objc private func openAbout() {
        navigationController?.pushViewController(AboutController(), animated: true)
    }

    @objc private func openTesting() {
        navigationController?.pushViewController(TestingController(), animated: true)
    }

    @objc private func openSettings() {
        let destination: UIViewController
        let locales = KeyboardLocale.allLocales

        if locales.count == 1, let locale = locales.first {
            destination = UserDictionaryViewController(keyboardLocale: locale)
        } else {
            destination = KeyboardLocalesViewController()
        }

        navigationController?.pushViewController(destination, animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        contentView.awakeFromNib()
        refreshUI()
    }

    private let bag = DisposeBag()
    private var doingPahkat = false

    @objc private func refreshUI() {
        DispatchQueue.main.async {
            self.contentView.configStack?.isHidden = AppDelegate.instance.isKeyboardEnabled

            if self.doingPahkat {
                return
            }

            if let pahkat = AppDelegate.instance.pahkat {
                DispatchQueue.global(qos: .userInitiated).async {
                    pahkat.checkForSpellerUpdates(logger: { [weak self] message in
                        print(message)
                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150), execute: { [weak self] in
                            if let self = self, self.doingPahkat {
                                self.setProgress(value: message)
                            }
                        })
                    }).subscribe(onSuccess: { [weak self] _ in
                        self?.hideProgress()
                    }, onError: { [weak self] error in
                        self?.setProgress(value: "Error: \(String(describing: error))")
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: { [weak self] in
                            self?.hideProgress()
                        })
                    }).disposed(by: self.bag)
                }
            }

            self.doingPahkat = true
        }
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
        contentView.keyboardSettingsButton.addTarget(self, action: #selector(openKeyboardSettings), for: [.touchUpInside])
        contentView.aboutButton.addTarget(self, action: #selector(openAbout), for: [.touchUpInside])
        contentView.testingButton.addTarget(self, action: #selector(openTesting), for: [.touchUpInside])
        contentView.personalDictionary.addTarget(self, action: #selector(openSettings), for: [.touchUpInside])

        // Currently settings only has user dictionary, hide if not enabled
        if !FeatureFlag.userDictionary {
            contentView.personalDictionary.isHidden = true
        }

        // Settings button must not show with no keyboards enabled
        if KeyboardLocale.enabledLocales.isEmpty {
            contentView.personalDictionary.isHidden = true
        }
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
            self.doingPahkat = false
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
