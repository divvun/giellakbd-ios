import UIKit

class SettingsViewController: BaseSettingsViewController {

    override var rows: [Row] {
        let destinationViewController: ViewControllerMaker
        let locales = KeyboardLocale.allLocales
        if locales.count == 1 {
            destinationViewController = {
                UserDictionaryViewController(keyboardLocale: locales.first!)
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
