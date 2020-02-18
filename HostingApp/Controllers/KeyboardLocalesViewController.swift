import UIKit

class KeyboardLocalesViewController: SettingsViewController {

    override var rows: [Row] {
        var rows: [Row] = []

        for locale in KeyboardLocales.allLocales {
            let row = Row(title: locale.langaugeName) { () -> UIViewController in
                UserDictionaryViewController(keyboardLocale: locale) // TODO: input language code
            }
            rows.append(row)
        }

        return rows
    }

}
