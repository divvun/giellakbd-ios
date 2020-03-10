import Foundation

public struct KeyboardLocale {
    let identifier: String
    let languageName: String

    static var current: KeyboardLocale {
        let bundle = Bundle.main
        guard let locale = localeFromBundle(bundle) else {
            fatalError("Couldn't get current keyboard locale")
        }
        return locale
    }

    static func localeFromBundle(_ bundle: Bundle) -> KeyboardLocale? {
        guard let info = bundle.infoDictionary,
            let languageName = info["CFBundleDisplayName"] as? String,
            let ext = info["NSExtension"] as? [String: Any],
            let attributes = ext["NSExtensionAttributes"] as? [String: Any],
            let languageIdentifier = attributes["PrimaryLanguage"] as? String else {
                return nil
        }
        return KeyboardLocale(identifier: languageIdentifier, languageName: languageName)
    }
}
