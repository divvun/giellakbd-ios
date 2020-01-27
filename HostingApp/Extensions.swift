import UIKit

protocol Nibbable {}
protocol HideNavBar {}

extension Nibbable where Self: UIView {
    static var nibName: String {
        return String(describing: self)
    }

    static func loadFromNib() -> Self {
        let bundle = Bundle(for: Self.self)

        guard let views = bundle.loadNibNamed(nibName, owner: Self.self, options: nil),
            let view = views.first as? Self else {
                fatalError("Nib could not be loaded for nibName: \(nibName);"
                    + "check that the XIB owner has been set to the given view: \(self)")
        }

        return view
    }
}

class ViewController<T: UIView>: UIViewController where T: Nibbable {
    let contentView = T.loadFromNib()

    override func loadView() {
        view = contentView
    }

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIImage {
    func with(width: Int, height: Int) -> UIImage {
        let size = CGSize(width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        draw(in: CGRect(origin: .zero, size: size))

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()

        return scaledImage
    }
}

extension Strings {
    static var localizedName: String {
        let infoDict = Strings.bundle.localizedInfoDictionary ?? Strings.bundle.infoDictionary

        if let name = infoDict?["CFBundleDisplayName"] as? String {
            return name
        }

        return keyboard
    }

    static var enableTapSounds: NSAttributedString {
        let plain = Strings.enableTapSoundsPlain(keyboard: Strings.localizedName, allowFullAccess: Strings.allowFullAccess)
        let nsplain = plain as NSString
        let size = CGFloat(12)

        let attr = NSMutableAttributedString(string: plain)

        attr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: size), range: nsplain.range(of: plain))
        attr.addAttribute(NSAttributedString.Key.font,
                          value: UIFont.systemFont(ofSize: size,
                                                   weight: UIFont.Weight(rawValue: 0.3)),
                          range: nsplain.range(of: Strings.localizedName))
        attr.addAttribute(NSAttributedString.Key.font,
                          value: UIFont.systemFont(ofSize: size,
                                                   weight: UIFont.Weight(rawValue: 0.3)),
                          range: nsplain.range(of: Strings.allowFullAccess))

        return attr
    }

    private static func bolden(string: String, item: String, size: CGFloat) -> NSAttributedString {
        let nsstring = string as NSString
        let attr = NSMutableAttributedString(string: string)

        attr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: size), range: nsstring.range(of: string))
        attr.addAttribute(NSAttributedString.Key.font,
                          value: UIFont.systemFont(ofSize: size,
                                                   weight: UIFont.Weight(rawValue: 0.3)),
                          range: nsstring.range(of: item))

        return attr
    }

    static func creditWithUrls() -> NSAttributedString {
        let string: NSString = "SimpleButton © Andreas Tinoco Lobo\nTap icon © Icons8\nLanguage icon © Icons8"

        let simpleUrl = "https://github.com/aloco/SimpleButton"
        let languageUrl = "https://icons8.com/icon/25628/language"
        let tapUrl = "https://icons8.com/icon/8099/tap-filled"

        let attrString = NSMutableAttributedString(string: string as String)

        let range1 = string.range(of: "SimpleButton")
        let range2 = string.range(of: "Tap icon")
        let range3 = string.range(of: "Language icon")

        attrString.addAttribute(NSAttributedString.Key.link, value: simpleUrl, range: range1)
        attrString.addAttribute(NSAttributedString.Key.link, value: tapUrl, range: range2)
        attrString.addAttribute(NSAttributedString.Key.link, value: languageUrl, range: range3)
        attrString.addAttribute(NSAttributedString.Key.font,
                                value: UIFont.systemFont(ofSize: 15),
                                range: string.range(of: string as String))

        return attrString
    }

    static func openApp(item: String, size: CGFloat = 15) -> NSAttributedString {
        let plain = Strings.openAppPlain(item: item)
        return bolden(string: plain, item: item, size: size)
    }

    static func tap(item: String, size: CGFloat = 15) -> NSAttributedString {
        let plain = Strings.tapPlain(item: item)
        return bolden(string: plain, item: item, size: size)
    }

    static var supportedLocales: [Locale] = {
        Bundle.main.localizations
            .filter { loc in
                guard let bp = Bundle.main.path(forResource: loc, ofType: "lproj"), let b = Bundle(path: bp) else {
                    return false
                }

                return b.path(forResource: "Localizable", ofType: "strings") != nil
        }
        .map { Locale(identifier: $0 == "Base" ? "en" : $0) }
        .sorted(by: {
            languageName(for: $0)! < languageName(for: $1)!
        })
    }()

    static func languageName(for locale: Locale) -> String? {
        guard let lc = locale.languageCode else {
            return nil
        }

        if let s = locale.localizedString(forLanguageCode: lc), s != lc {
            return s
        }

        // Fallback for unsupported OS-level magic
        guard let bp = Bundle.main.path(forResource: lc, ofType: "lproj"), let b = Bundle(path: bp) else {
            return lc
        }

        return b.localizedString(forKey: "locale_\(lc)", value: nil, table: nil)
    }
}
