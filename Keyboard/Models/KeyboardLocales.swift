import Foundation

public struct KeyboardLocale {
    let identifier: String
    let langaugeName: String
}

final class KeyboardLocales {
    private static var plugInBundles: [Bundle] = {
        do {
            guard let pluginsPath = Bundle.main.resourceURL?.appendingPathComponent("PlugIns") else {
                return []
            }
            return try FileManager.default.contentsOfDirectory(at: pluginsPath, includingPropertiesForKeys: .none, options: [])
                .compactMap {
                    Bundle(url: $0)
                }
        } catch {
            fatalError("Error getting plugin bundles: \(error)")
        }
    }()

    static var allLocales: [KeyboardLocale] {
        plugInBundles.compactMap { localeFromBundle($0) }
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
