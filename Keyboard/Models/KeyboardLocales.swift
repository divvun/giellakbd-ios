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
            guard let info = bundle.infoDictionary,
                let languageName = info["CFBundleDisplayName"] as? String,
                let ext = info["NSExtension"] as? [String: Any],
                let attributes = ext["NSExtensionAttributes"] as? [String: Any],
                let languageIdentifier = attributes["PrimaryLanguage"] as? String else {
                continue
            }
            let locale = KeyboardLocale(identifier: languageIdentifier, langaugeName: languageName)
            locales.append(locale)
        }
        return locales
    }
}
