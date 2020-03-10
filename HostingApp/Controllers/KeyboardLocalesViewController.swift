import UIKit

class KeyboardLocalesViewController: BaseSettingsViewController {

    //swiftlint:disable:next identifier_name
    var _rows: [Row] = {
        var rows: [Row] = []

        for locale in KeyboardLocale.allLocales {
            let row = Row(title: locale.languageName) { () -> UIViewController in
                UserDictionaryViewController(keyboardLocale: locale)
            }
            rows.append(row)
        }

        return rows
    }()

    override var rows: [Row] {
        _rows
    }

}
