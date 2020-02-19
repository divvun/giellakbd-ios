import UIKit

class KeyboardLocalesViewController: SettingsViewController {

    override var rows: [Row] {
        var rows: [Row] = []

        for locale in KeyboardLocales.allLocales {
            let row = Row(title: locale.langaugeName) { () -> UIViewController in
                UserDictionaryViewController(keyboardLocale: locale)
            }
            rows.append(row)
        }

        return rows
    }

}
