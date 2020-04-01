import Foundation

extension KeyboardLocale {
    static var allLocales: [KeyboardLocale] {
        KeyboardBundle.allBundles.compactMap { localeFromBundle($0) }
    }
}
