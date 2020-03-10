import UIKit

class SettingsViewController: BaseSettingsViewController {

    //swiftlint:disable:next identifier_name
    let _rows: [Row] = {
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
    }()

    override var rows: [Row] {
         _rows
    }

}
