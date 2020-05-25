// Generated. Do not edit.
import Foundation

fileprivate extension UserDefaults {
    var appleLanguages: [String] {
        return self.array(forKey: "AppleLanguages") as? [String] ??
            [Locale.autoupdatingCurrent.languageCode ?? "en"]
    }
}

fileprivate func derivedLocales(_ languageCode: String) -> [String] {
  let x = Locale(identifier: languageCode)
  var opts: [String] = []
  
  if let lang = x.languageCode {
      if let script = x.scriptCode, let region = x.regionCode {
          opts.append("\(lang)-\(script)-\(region)")
      }
      
      if let script = x.scriptCode {
          opts.append("\(lang)-\(script)")
      }
      
      if let region = x.regionCode {
          opts.append("\(lang)-\(region)")
      }
      
      opts.append(lang)
  }
  
  return opts
}

class Strings {
    static var languageCode: String = UserDefaults.standard.appleLanguages[0] {
        didSet {
            if let dir = Bundle.main.path(forResource: languageCode, ofType: "lproj"), let bundle = Bundle(path: dir) {
                self.bundle = bundle
            } else {
                print("No bundle found for \(languageCode)")
                self.bundle = Bundle.main
            }
        }
    }

    static var bundle: Bundle = Bundle.main

    internal static func string(for key: String) -> String {
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    internal static func stringArray(for key: String, length: Int) -> [String] {
        return (0..<length).map {
            bundle.localizedString(forKey: "\(key)_\($0)", value: nil, table: nil)
        }
    }

    /** About */
    static var about: String {
        return string(for: "about")
    }

    /** Add */
    static var add: String {
        return string(for: "add")
    }

    /** Add New Keyboard… */
    static var addNewKeyboard: String {
        return string(for: "addNewKeyboard")
    }

    /** Add Word */
    static var addWord: String {
        return string(for: "addWord")
    }

    /** This word will be suggested in the spelling banner for similar input. */
    static var addWordMessage: String {
        return string(for: "addWordMessage")
    }

    /** Allow Full Access */
    static var allowFullAccess: String {
        return string(for: "allowFullAccess")
    }

    /** Attributions */
    static var attributions: String {
        return string(for: "attributions")
    }

    /** Block */
    static var block: String {
        return string(for: "block")
    }

    /** Blocked */
    static var blocked: String {
        return string(for: "blocked")
    }

    /** Cancel */
    static var cancel: String {
        return string(for: "cancel")
    }

    /** Contexts for "{word}" */
    static func contextsFor(word: String) -> String {
        let format = string(for: "contextsFor")
        return String(format: format, word)
    }

    /** Delete */
    static var delete: String {
        return string(for: "delete")
    }

    /** Detected */
    static var detected: String {
        return string(for: "detected")
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
    static var localeSjd: String {
        return string(for: "localeSjd")
    }

    /** No user-created words yet. */
    static var noUserWords: String {
        return string(for: "noUserWords")
    }

    /** Words that are left uncorrected and are not in the built-in dictionary will appear here. */
    static var noUserWordsDescription: String {
        return string(for: "noUserWordsDescription")
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

    /** Unblock */
    static var unblock: String {
        return string(for: "unblock")
    }

    /** User-Defined */
    static var userDefined: String {
        return string(for: "userDefined")
    }

    /** User Dictionary */
    static var userDictionary: String {
        return string(for: "userDictionary")
    }

    /** When you have finished, return to this app to continue. */
    static var whenYouHaveFinished: String {
        return string(for: "whenYouHaveFinished")
    }

    /** Word */
    static var word: String {
        return string(for: "word")
    }

    private init() {}
}

fileprivate let localeTree = [
    "en": ["en"],
    "nb": ["nb"],
    "se": ["se"]
]
