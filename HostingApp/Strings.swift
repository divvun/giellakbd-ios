import Foundation

class Strings {
    static var languageCode: String? {
        didSet {
            if let dir = Bundle.main.path(forResource: languageCode, ofType: "lproj"), let bundle = Bundle(path: dir) {
                self.bundle = bundle
            } else if let dir = Bundle.main.path(forResource: "Base", ofType: "lproj"), let bundle = Bundle(path: dir) {
                self.bundle = bundle
            } else {
                bundle = Bundle.main
            }
        }
    }

    static var bundle: Bundle = Bundle.main

    fileprivate static func string(for key: String) -> String {
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    fileprivate static func stringArray(for key: String, length: Int) -> [String] {
        return (0 ..< length).map {
            bundle.localizedString(forKey: "\(key)_\($0)", value: nil, table: nil)
        }
    }

    /** About */
    static var about: String {
        return string(for: "about")
    }

    /** Add New Keyboard… */
    static var addNewKeyboard: String {
        return string(for: "addNewKeyboard")
    }

    /** Allow Full Access */
    static var allowFullAccess: String {
        return string(for: "allowFullAccess")
    }

    /** Attributions */
    static var attributions: String {
        return string(for: "attributions")
    }

    /** If you wish to enable key tap sounds, you must then tap {keyboard} and toggle {allowFullAccess}. */
    static func enableTapSoundsPlain(keyboard: String, allowFullAccess: String) -> String {
        let format = string(for: "enableTapSoundsPlain")
        return String(format: format, keyboard, allowFullAccess)
    }

    /** General */
    static var general: String {
        return string(for: "general")
    }

    /** Keyboard */
    static var keyboard: String {
        return string(for: "keyboard")
    }

    /** Keyboards */
    static var keyboards: String {
        return string(for: "keyboards")
    }

    /** Language */
    static var language: String {
        return string(for: "language")
    }

    /** Layouts */
    static var layouts: String {
        return string(for: "layouts")
    }

    /** Kildin Sami */
    //swiftlint:disable:next identifier_name
    static var locale_sjd: String {
        return string(for: "locale_sjd")
    }

    /** Open the {item} app */
    static func openAppPlain(item: String) -> String {
        let format = string(for: "openAppPlain")
        return String(format: format, item)
    }

    /** Open Settings */
    static var openSettings: String {
        return string(for: "openSettings")
    }

    /** Save */
    static var save: String {
        return string(for: "save")
    }

    /** Set Up {keyboard} */
    static func setUp(keyboard: String) -> String {
        let format = string(for: "setUp")
        return String(format: format, keyboard)
    }

    /** Setting Up */
    static var settingUp: String {
        return string(for: "settingUp")
    }

    /** Settings */
    static var settings: String {
        return string(for: "settings")
    }

    /** Skip */
    static var skip: String {
        return string(for: "skip")
    }

    /** Tap {item} */
    static func tapPlain(item: String) -> String {
        let format = string(for: "tapPlain")
        return String(format: format, item)
    }

    /** When you have finished, return to this app to continue. */
    static var whenYouHaveFinished: String {
        return string(for: "whenYouHaveFinished")
    }

    private init() {}
}
