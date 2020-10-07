import Foundation

extension KeyboardLocale {
    static var allLocales: [KeyboardLocale] {
        Bundle.allKeyboardBundles.compactMap { localeFromBundle($0) }
    }

    static var enabledLocales: [KeyboardLocale] {
        Bundle.enabledKeyboardBundles.compactMap{ localeFromBundle($0) }
    }
}
