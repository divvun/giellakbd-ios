import Foundation

extension KeyboardLocale {
    static var allLocales: [KeyboardLocale] = {
        Bundle.allKeyboardBundles.compactMap { localeFromBundle($0) }
    }()

    // Don't make this lazy!
    static var enabledLocales: [KeyboardLocale] {
        Bundle.enabledKeyboardBundles.compactMap{ localeFromBundle($0) }
    }
}
