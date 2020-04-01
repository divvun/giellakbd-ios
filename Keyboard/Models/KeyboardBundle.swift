import Foundation

final class KeyboardBundle {
    static var allBundles: [Bundle] = {
        do {
            guard let pluginsPath = Bundle.main.resourceURL?.appendingPathComponent("PlugIns") else {
                return []
            }
            print("pluginsPath: \(pluginsPath)")
            return try FileManager.default.contentsOfDirectory(at: pluginsPath, includingPropertiesForKeys: .none, options: [])
                .compactMap {
                    Bundle(url: $0)
            }
        } catch {
            fatalError("Error getting plugin bundles: \(error)")
        }
    }()
}
