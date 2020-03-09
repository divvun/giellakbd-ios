import UIKit

class KeyboardLocalesViewController: SettingsViewController {

    override var rows: [Row] {
        var rows: [Row] = []

        for locale in KeyboardLocale.allLocales {
            let row = Row(title: locale.languageName) { () -> UIViewController in
                UserDictionaryViewController(keyboardLocale: locale)
            }
            rows.append(row)
        }

        return rows
    }

}
