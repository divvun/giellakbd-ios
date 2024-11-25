import Foundation
import UIKit

extension UIDevice {
    public var systemMajorVersion: Int {
        let systemVersion = UIDevice.current.systemVersion
        guard let majorVersionSubstring = systemVersion.split(separator: ".").first,
            let majorVersion = Int(majorVersionSubstring) else {
            return -1
        }
        return majorVersion
    }
}

extension UIUserInterfaceStyle {
    public var debugDescription: String {
        switch self {
        case .dark:
            return "UIUserInterfaceStyle.dark"
        case .light:
            return "UIUserInterfaceStyle.light"
        case .unspecified:
            return "UIUserInterfaceStyle.unspecified"
        @unknown default:
            fatalError("Could not debug print unknown UIUserInterfaceStyle (\(self.rawValue))")
        }
    }
}

extension UIUserInterfaceIdiom {
    public var debugDescription: String {
        switch self {
        case .phone:
            return "UIUserInterfaceIdiom.phone"
        case .unspecified:
            return "UIUserInterfaceIdiom.unspecified"
        case .pad:
            return "UIUserInterfaceIdiom.pad"
        case .tv:
            return "UIUserInterfaceIdiom.tv"
        case .carPlay:
            return "UIUserInterfaceIdiom.carPlay"
        @unknown default:
            return "UIUserInterfaceIdiom.<unknown>"
        }
    }
}

extension UIUserInterfaceSizeClass {
    public var debugDescription: String {
        switch self {
        case .compact:
            return "UIUserInterfaceSizeClass.compact"
        case .regular:
            return "UIUserInterfaceSizeClass.regular"
        case .unspecified:
            return "UIUserInterfaceSizeClass.unspecified"
        @unknown default:
            return "UIUserInterfaceSizeClass.<unknown>"
        }
    }
}

extension UIKeyboardAppearance {
    public var debugDescription: String {
        switch self {
        case .dark:
            return "UIKeyboardAppearance.dark"
        case .light:
            return "UIKeyboardAppearance.light"
        case .default:
            return "UIKeyboardAppearance.default"
        @unknown default:
            fatalError("Could not debug print unknown UIKeyboardAppearance (\(self.rawValue))")
        }
    }
}

extension String {
    func bolden(substring: String, size: CGFloat = UIFont.labelFontSize, caseInsensitive: Bool = false) -> NSAttributedString {
        let nsstring = self as NSString
        let attr = NSMutableAttributedString(string: self)

        let boldRange: NSRange
        if caseInsensitive {
            boldRange = (nsstring.lowercased as NSString).range(of: substring.lowercased())
        } else {
            boldRange = nsstring.range(of: substring)
        }

        attr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: size), range: nsstring.range(of: self))
        attr.addAttribute(NSAttributedString.Key.font,
                          value: UIFont.systemFont(ofSize: size,
                                                   weight: UIFont.Weight(rawValue: 0.3)),
                          range: boldRange)

        return attr
    }

    subscript(index: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: index)]
    }

    public func levenshtein(_ other: String) -> Int {
        let sCount = self.count
        let oCount = other.count

        guard sCount != 0 else {
            return oCount
        }

        guard oCount != 0 else {
            return sCount
        }

        let line: [Int]  = Array(repeating: 0, count: oCount + 1)
        var mat: [[Int]] = Array(repeating: line, count: sCount + 1)

        for i in 0...sCount {
            mat[i][0] = i
        }

        for j in 0...oCount {
            mat[0][j] = j
        }

        for j in 1...oCount {
            for i in 1...sCount {
                if self[i - 1] == other[j - 1] {
                    mat[i][j] = mat[i - 1][j - 1]       // no operation
                } else {
                    let del = mat[i - 1][j] + 1         // deletion
                    let ins = mat[i][j - 1] + 1         // insertion
                    let sub = mat[i - 1][j - 1] + 1     // substitution
                    mat[i][j] = min(min(del, ins), sub)
                }
            }
        }

        return mat[sCount][oCount]
    }
}

extension Substring {
    func lastIndex(after character: Character) -> String.Index? {
        guard let index = self.lastIndex(of: character) else { return nil }
        if index == endIndex { return nil }
        return self.index(after: index)
    }
}

extension UIColor {
    //swiftlint:disable:next identifier_name
    convenience init(r: Int, g: Int, b: Int, a: Double = 1) {
        self.init(red: CGFloat(r) / CGFloat(255),
                  green: CGFloat(g) / CGFloat(255),
                  blue: CGFloat(b) / CGFloat(255),
                  alpha: CGFloat(a))
    }
}

extension UIView {
    func fill(superview other: UIView, margins: UIEdgeInsets = .zero) {
        leftAnchor.constraint(equalTo: other.leftAnchor, constant: margins.left).isActive = true
        rightAnchor.constraint(equalTo: other.rightAnchor, constant: -margins.right).isActive = true
        topAnchor.constraint(equalTo: other.topAnchor, constant: margins.top).isActive = true
        bottomAnchor.constraint(equalTo: other.bottomAnchor, constant: -margins.bottom).isActive = true
    }

    func centerIn(superview other: UIView) {
        centerXAnchor.constraint(equalTo: other.centerXAnchor).isActive = true
        centerYAnchor.constraint(equalTo: other.centerYAnchor).isActive = true
    }

    var isLogicallyIPad: Bool {
        return traitsAreLogicallyIPad(traitCollection: self.traitCollection)
    }
}

public extension UIColor {
    // FIXME: is there a cleaner way to do this?
    // swiftlint:disable:next large_tuple
    private var components: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let components = cgColor.components!

        switch components.count == 2 {
        case true: return (r: components[0], g: components[0], b: components[0], a: components[1])
        case false: return (r: components[0], g: components[1], b: components[2], a: components[3])
        }
    }

    static func interpolate(from fromColor: UIColor, to toColor: UIColor, with progress: CGFloat) -> UIColor {
        let fromComponents = fromColor.components
        let toComponents = toColor.components

        //swiftlint:disable identifier_name
        let r = (1 - progress) * fromComponents.r + progress * toComponents.r
        let g = (1 - progress) * fromComponents.g + progress * toComponents.g
        let b = (1 - progress) * fromComponents.b + progress * toComponents.b
        let a = (1 - progress) * fromComponents.a + progress * toComponents.a
        //swiftlint:enable identifier_name

        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

extension NSLayoutConstraint {
    @discardableResult
    func enable(priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        if let priority = priority {
            self.priority = priority
        }
        self.isActive = true
        return self
    }
}

extension UIScreen {
    var isDeviceLandscape: Bool {
        let size = self.bounds.size
        return size.width > size.height
    }
}

let str1 = "containing"
let str2 = "Bundle"

extension Bundle {
    static var allKeyboardBundles: [Bundle] {
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
    }

    // Returns the keyboard bundles for keyboards the user has enabled in iOS Keyboard Settings
    static var enabledKeyboardBundles: [Bundle] {
        let enabledLanguages = enabledGiellaKeyboardLanguages
        return allKeyboardBundles.filter { enabledLanguages.contains($0.primaryLanguage ?? "") }
    }

    var spellerPackageKey: URL? {
        guard let info = infoDictionary, let packageKey = info["DivvunSpellerPackageKey"] as? String else {
            return nil
        }
        return packageKey.isEmpty ? nil : URL(string: packageKey)
    }
    
    var spellerPath: String? {
        guard let info = infoDictionary, let spellerPath = info["DivvunSpellerPath"] as? String else {
            return nil
        }
        return spellerPath.isEmpty ? nil : spellerPath
    }

    var primaryLanguage: String? {
        guard let extensionInfo = infoDictionary!["NSExtension"] as? [String: AnyObject],
            let attrs = extensionInfo["NSExtensionAttributes"] as? [String: AnyObject],
            let lang = attrs["PrimaryLanguage"] as? String else {
                return nil
        }
        return lang
    }

    var urlScheme: String? {
        guard let schemes = infoDictionary!["LSApplicationQueriesSchemes"] as? [String],
            let urlScheme = schemes.first else {
                return nil
        }
        return urlScheme
    }

    //swiftlint:disable identifier_name
    private static var enabledGiellaInputModes: [UITextInputMode] {
        UITextInputMode.activeInputModes.compactMap {
            let s = str1 + str2
            let v = $0.perform(Selector(s))
            if let x = v?.takeUnretainedValue() as? Bundle,
                let bunId = x.bundleIdentifier,
                let mainId = Bundle.main.bundleIdentifier {
                if bunId.contains(mainId) {
                    return $0
                }
            }
            return nil
        }
    }
    //swiftlint:enable identifier_name

    private static var enabledGiellaKeyboardLanguages: [String] {
        return enabledGiellaInputModes.compactMap { $0.primaryLanguage }
    }
}

func isBeingRunFromTests() -> Bool {
    return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
}

func traitsAreLogicallyIPad(traitCollection: UITraitCollection) -> Bool {
    return UIDevice.current.dc.deviceFamily == .iPad
        && traitCollection.userInterfaceIdiom == .pad
        && traitCollection.horizontalSizeClass == .regular
}

class URLOpener {
    // App extensions don't have access to UIApplication.shared. Do an ugly song and dance to work around this.
    @discardableResult
    @objc func aggresivelyOpenURL(_ url: URL, responder: UIResponder?) -> Bool {
        var responder = responder
        while responder != nil {
            if let application = responder as? UIApplication {
                return application.perform(#selector(openURL(_:)), with: url) != nil
            }
            responder = responder?.next
        }
        return false
    }

    @objc private func openURL(_ url: URL) {
        // Shamefully appease compiler for above function
    }
}
