import Foundation

private let defaults: UserDefaults = {
    let x = UserDefaults(suiteName: KeyboardSettings.groupId)!
    x.registerDefaultsFromSettingsBundle()
    return x
}()

class KeyboardSettings {
    static var groupId: String = {
        return "group.\(Bundle.top.bundleIdentifier!)"
    }()

    static var currentKeyboard: KeyboardDefinition {
        get {
            guard let data = defaults.data(forKey: "currentKeyboard") else {
                print("No data")
                return KeyboardDefinition.definitions[0]
            }
            
            do {
                return try JSONDecoder().decode(KeyboardDefinition.self, from: data)
            } catch {
                print(String(describing: error))
                return KeyboardDefinition.definitions[0]
            }
        }
        set {
            let data: Data
            do {
                data = try JSONEncoder().encode(newValue)
            } catch {
                fatalError(String(describing: error))
            }
            defaults.set(data, forKey: "currentKeyboard")
        }
    }
    static var languageCode: String {
        get { return defaults.string(forKey: "language") ?? Locale.current.languageCode! }
        set { defaults.set(newValue, forKey: "language") }
    }

    static var firstLoad: Bool {
        get { return defaults.object(forKey: "firstLoad") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "firstLoad") }
    }
    
    static var isKeySoundEnabled: Bool {
        get { return defaults.bool(forKey: "isKeySoundEnabled") }
        set { defaults.set(newValue, forKey: "isKeySoundEnabled") }
    }
}

extension Bundle {
    static var top: Bundle {
        if Bundle.main.bundleURL.pathExtension == "appex" {
            let url = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
            if let other = Bundle(url: url) {
                return other
            }
        }

        return Bundle.main
    }
}

extension UserDefaults {
    func registerDefaultsFromSettingsBundle() {
        if let settingsURL = Bundle.top.url(forResource: "Root", withExtension: "plist", subdirectory: "Settings.bundle"),
            let settings = NSDictionary(contentsOf: settingsURL),
            let preferences = settings["PreferenceSpecifiers"] as? [NSDictionary] {

            var defaultsToRegister = [String: AnyObject]()
            for prefSpecification in preferences {
                if let key = prefSpecification["Key"] as? String,
                    let value = prefSpecification["DefaultValue"]
                {
                    defaultsToRegister[key] = value as AnyObject
                }
            }

            self.register(defaults: defaultsToRegister)
        } else {
            debugPrint("registerDefaultsFromSettingsBundle: Could not find Settings.bundle")
        }
    }
}
