import UIKit

final class KeyboardLocalesViewController: BaseSettingsViewController, SettingsController {

    override func rows() -> [Row] {
        var rows: [Row] = []

        let enabledLocales = KeyboardLocale.enabledLocales

        let localesWithDictionaryContent = KeyboardLocale.allLocales.filter {
            UserDictionary.hasContentFor(locale: $0)
        }

        // Convert to set to remove duplicates
        let enabledOrHasDictionaryContent = Array(Set(enabledLocales + localesWithDictionaryContent))

        let sortedLocales = enabledOrHasDictionaryContent.sorted {
            $0.languageName < $1.languageName
        }

        for locale in sortedLocales {
            let row = Row(title: locale.languageName) { () -> UIViewController in
                UserDictionaryViewController(keyboardLocale: locale)
            }
            rows.append(row)
        }

        return rows
    }

}
