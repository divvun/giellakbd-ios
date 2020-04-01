import Foundation

extension KeyboardLocale {
    static var allLocales: [KeyboardLocale] {
        Bundle.allKeyboardBundles.compactMap { localeFromBundle($0) }
    }
}
