import Foundation

public struct KeyboardLocale {
    let identifier: String
    let langaugeName: String
}

final class KeyboardLocales {
    static var allLocales: [KeyboardLocale] {
        var locales: [KeyboardLocale] = []
        let appexBundles = Bundle.allBundles.filter({ (bundle) -> Bool in
            bundle.bundleURL.pathExtension == "appex"
        })

        for bundle in appexBundles {
            if let locale = localeFromBundle(bundle) {
                locales.append(locale)
            }
        }
        return locales
    }

    static var current: KeyboardLocale {
        let bundle = Bundle.main
        guard let locale = localeFromBundle(bundle) else {
            fatalError("Couldn't get current keyboard locale")
        }
        return locale
    }
}

private func localeFromBundle(_ bundle: Bundle) -> KeyboardLocale? {
    guard let info = bundle.infoDictionary,
        let languageName = info["CFBundleDisplayName"] as? String,
        let ext = info["NSExtension"] as? [String: Any],
        let attributes = ext["NSExtensionAttributes"] as? [String: Any],
        let languageIdentifier = attributes["PrimaryLanguage"] as? String else {
            return nil
    }
    return KeyboardLocale(identifier: languageIdentifier, langaugeName: languageName)
}
