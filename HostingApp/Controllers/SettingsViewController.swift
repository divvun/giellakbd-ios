import UIKit

final class SettingsViewController: BaseSettingsViewController, SettingsController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.settings
    }

    override func rows() -> [Row] {
        let destinationViewController: ViewControllerMaker
        let locales = KeyboardLocale.allLocales

        if locales.isEmpty {
            destinationViewController = { () in
                return UIViewController()
            }
        } else if locales.count == 1, let locale = locales.first {
            destinationViewController = { () in
                return UserDictionaryViewController(keyboardLocale: locale)
            }
        } else {
            destinationViewController = { () in
                return KeyboardLocalesViewController()
            }
        }

        return [
            Row(title: Strings.userDictionary, destinationViewController: destinationViewController)
        ]
    }

}
