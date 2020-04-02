import Foundation

extension KeyboardLocale {
    static var allLocales: [KeyboardLocale] {
        plugInBundles.compactMap { localeFromBundle($0) }
    }

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
}
