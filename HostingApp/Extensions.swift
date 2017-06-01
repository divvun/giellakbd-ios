//
//  Extensions.swift
//  GiellaKeyboard
//
//  Created by Brendan Molloy on 12/5/17.
//  Copyright © 2017 Apple. All rights reserved.
//

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
                fatalError("Nib could not be loaded for nibName: \(self.nibName); check that the XIB owner has been set to the given view: \(self)")
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
    
    required init?(coder aDecoder: NSCoder) {
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
        if let infoDict = Bundle.main.localizedInfoDictionary,
            let name = infoDict["CFBundleName"] as? String
        {
            return name
        }
        
        return self.keyboard
    }
    
    private static func bolden(string: String, item: String, size: CGFloat) -> NSAttributedString {
        let nsstring = string as NSString
        let attr = NSMutableAttributedString(string: string)
        
        attr.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: size), range: nsstring.range(of: string))
        attr.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: size, weight: 0.3), range: nsstring.range(of: item))
        
        return attr
    }
    
    static func openApp(item: String, size: CGFloat = 15) -> NSAttributedString {
        let plain = Strings.openAppPlain(item: item)
        return bolden(string: plain, item: item, size: size)
    }
    
    static func tap(item: String, size: CGFloat = 15) -> NSAttributedString {
        let plain = Strings.tapPlain(item: item)
        return bolden(string: plain, item: item, size: size)
    }
    
    static var supportedLocales: [Locale] =
        Bundle.main.localizations
            .filter({ $0 != "Base" })
            .map({ Locale(identifier: $0) })
            .sorted(by: {
                languageName(for: $0)! < languageName(for: $1)!
            })
    
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
        
        return b.localizedString(forKey: lc, value: nil, table: nil)
    }
}

extension UIColor {
    convenience init(r: Int, g: Int, b: Int, a: Double = 1) {
        self.init(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: CGFloat(a))
    }
}
