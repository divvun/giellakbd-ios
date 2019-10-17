import Foundation
import UIKit

protocol Theme {
    var regularKeyColor: UIColor { get }
    var specialKeyColor: UIColor { get }
    var popupColor: UIColor { get }
    var backgroundColor: UIColor { get }
    var underColor: UIColor { get }
    var textColor: UIColor { get }
    var inactiveTextColor: UIColor { get }
    var borderColor: UIColor { get }
    var specialKeyBorderColor: UIColor { get }
    var keyShadowColor: UIColor { get }
    var shiftActiveColor: UIColor { get }
    var solidRegularKeyColor: UIColor { get }
    var solidSpecialKeyColor: UIColor { get }
    var solidPopupColor: UIColor { get }
    var activeColor: UIColor { get }
    var activeTextColor: UIColor { get }

    var keyCornerRadius: CGFloat { get }
    var popupCornerRadius: CGFloat { get }
    var keyVerticalMargin: CGFloat { get }
    var keyHorizontalMargin: CGFloat { get }

    var keyFont: UIFont { get }
    var lowerKeyFont: UIFont { get }
    var capitalKeyFont: UIFont { get }
    var alternateKeyFontSize: CGFloat { get }
    var popupKeyFont: UIFont { get }
    var bannerFont: UIFont { get }

    var bannerBackgroundColor: UIColor { get }
    var bannerSeparatorColor: UIColor { get }
    var bannerTextColor: UIColor { get }

    var bannerHorizontalMargin: CGFloat { get }
    var bannerVerticalMargin: CGFloat { get }
}

class LightThemeImpl: Theme {
    private let _keyFont: UIFont = UIFont.systemFont(ofSize: 26.0)
    private let _lowerKeyFont: UIFont = UIFont.systemFont(ofSize: 26.0, weight: .light)
    private let _capitalKeyFont: UIFont = UIFont.systemFont(ofSize: 24.0)
    
    var regularKeyColor = UIColor.white
    var specialKeyColor = UIColor(r: 162, g: 167, b: 177)
    var popupColor = UIColor.white
    var backgroundColor = UIColor(r: 203, g: 206, b: 212)
    var underColor = UIColor(hue: 0.611, saturation: 0.04, brightness: 0.56, alpha: 1)
    var textColor = UIColor.black
    var inactiveTextColor: UIColor = UIColor(white: 0.0, alpha: 0.3)
    var borderColor = UIColor.clear // UIColor(hue: 0.595, saturation: 0.04, brightness: 0.65, alpha: 1.0)
    var specialKeyBorderColor: UIColor { return .clear }
    var keyShadowColor = UIColor(r: 103, g: 106, b: 110, a: 0.5)
    var shiftActiveColor = UIColor.white
    var solidRegularKeyColor: UIColor { return regularKeyColor }
    var solidSpecialKeyColor = UIColor(r: 183, g: 191, b: 202)
    var solidPopupColor: UIColor { return popupColor }
    var activeColor: UIColor = UIColor(r: 31, g: 126, b: 249)
    var activeTextColor: UIColor = UIColor.white

    var keyCornerRadius: CGFloat { return 5.0 }
    var popupCornerRadius: CGFloat = 12.0
    var keyHorizontalMargin: CGFloat { return 2.5 }
    var keyVerticalMargin: CGFloat { return 5.0 }

    var keyFont: UIFont { return _keyFont }
    var lowerKeyFont: UIFont { return _lowerKeyFont }
    var capitalKeyFont: UIFont { return _capitalKeyFont }
//    var keyFont: UIFont { return UIFont.init(name: ".SFUIDisplay-Light", size: 26.0)! }
//    var capitalKeyFont: UIFont { return UIFont.init(name: ".SFUIDisplay-Light", size: 24.0)! }
    var alternateKeyFontSize: CGFloat { return 17.0 }
    var popupKeyFont = UIFont.systemFont(ofSize: 36.0)
    var bannerFont = UIFont.systemFont(ofSize: 18.0)

    var bannerBackgroundColor: UIColor { return backgroundColor }
    var bannerSeparatorColor: UIColor { return solidSpecialKeyColor }
    var bannerTextColor: UIColor { return .black }

    var bannerHorizontalMargin: CGFloat = 16.0
    var bannerVerticalMargin: CGFloat = 8.0

    public init() {}
}

class LightThemeIpadImpl: LightThemeImpl {
    let _keyFont: UIFont = UIFont.systemFont(ofSize: 28.0)
    
    override var keyCornerRadius: CGFloat { return 7.0 }
    override var keyHorizontalMargin: CGFloat { return 7.0 }
    override var keyVerticalMargin: CGFloat { return 7.0 }
    
    override var keyFont: UIFont { return _keyFont }
    override var alternateKeyFontSize: CGFloat { return 17.0 }
}

class DarkThemeImpl: Theme {
    private let _keyFont: UIFont = UIFont.systemFont(ofSize: 26.0)
    private let _lowerKeyFont: UIFont = UIFont.systemFont(ofSize: 26.0, weight: .light)
    private let _capitalKeyFont: UIFont = UIFont.systemFont(ofSize: 24.0)
    
    var backgroundColor: UIColor = .clear

    var keyShadowColor: UIColor = UIColor(r: 103, g: 106, b: 110, a: 0.5)

    var regularKeyColor = UIColor.lightGray.withAlphaComponent(CGFloat(0.4))
    var specialKeyColor = UIColor.gray.withAlphaComponent(CGFloat(0.3))
    var popupColor = UIColor(r: 111, g: 103, b: 111, a: 1.0)
    var underColor = UIColor(r: 39, g: 18, b: 39, a: 0.4)
    var textColor = UIColor.white
    var inactiveTextColor: UIColor = UIColor.lightGray
    var borderColor = UIColor.clear
    var specialKeyBorderColor: UIColor { return .clear }
    var shiftActiveColor = UIColor(r: 214, g: 220, b: 208)
    var solidRegularKeyColor = UIColor(r: 83, g: 83, b: 83)
    var solidSpecialKeyColor = UIColor(r: 45, g: 45, b: 45)
    var solidPopupColor: UIColor { return solidRegularKeyColor }
    var activeColor: UIColor = UIColor(r: 31, g: 126, b: 249)
    var activeTextColor: UIColor = UIColor.white

    var keyCornerRadius: CGFloat { return 8.0 }
    var popupCornerRadius: CGFloat = 12.0
    var keyHorizontalMargin: CGFloat { return 2.5 }
    var keyVerticalMargin: CGFloat { return 5.0 }

    var keyFont: UIFont { return _keyFont }
    var lowerKeyFont: UIFont { return _lowerKeyFont }
    var capitalKeyFont: UIFont { return _capitalKeyFont }
    var alternateKeyFontSize: CGFloat { return 17.0 }
    var popupKeyFont = UIFont.systemFont(ofSize: 26.0)
    var bannerFont = UIFont.systemFont(ofSize: 16.0)

    var bannerBackgroundColor: UIColor { return regularKeyColor }
    var bannerSeparatorColor: UIColor { return .clear }
    var bannerTextColor: UIColor { return .white }

    var bannerHorizontalMargin: CGFloat = 16.0
    var bannerVerticalMargin: CGFloat = 8.0

    public init() {}
}

class DarkThemeIpadImpl: DarkThemeImpl {
    override var keyCornerRadius: CGFloat { return 12.0 }
    override var keyHorizontalMargin: CGFloat { return 9.0 }
    override var keyVerticalMargin: CGFloat { return 7.0 }

    override var keyFont: UIFont { return UIFont.systemFont(ofSize: 28.0) }
    override var alternateKeyFontSize: CGFloat { return 17.0 }
}
