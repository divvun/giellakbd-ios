import UIKit

final class SettingsViewController: BaseSettingsViewController, SettingsController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.settings
    }

    override func rows() -> [Row] {
        let destinationViewController: ViewControllerMaker
        let locales = KeyboardLocale.allLocales

        if let locale = locales.first {
            destinationViewController = {
                UserDictionaryViewController(keyboardLocale: locale)
            }
        } else {
            destinationViewController = {
                KeyboardLocalesViewController()
            }
        }

        return [
            Row(title: Strings.userDictionary, destinationViewController: destinationViewController)
        ]
    }

}
