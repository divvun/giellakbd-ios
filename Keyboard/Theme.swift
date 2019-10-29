import Foundation
import UIKit
import UIDeviceComplete

struct _Theme {
    let dark: ThemeType
    let light: ThemeType
}

extension _Theme {
    @available(iOSApplicationExtension 12.0, *)
    func select(byUIStyle interfaceStyle: UIUserInterfaceStyle) -> ThemeType {
        switch interfaceStyle {
        case .light:
            return self.light
        case .dark:
            return self.dark
        case .unspecified:
            // This should probably not be possible to get into, so assume light
            return self.light
        @unknown default:
            return self.light
        }
    }
    
    func select(byAppearance appearance: UIKeyboardAppearance, traits: UITraitCollection) -> ThemeType {
        switch appearance {
        case .dark, .alert:
            return self.dark
        case .light:
            return self.light
        case .default:
            if #available(iOSApplicationExtension 12.0, *) {
                return select(byUIStyle: traits.userInterfaceStyle)
            } else {
                return self.light
            }
        @unknown default:
            return self.light
        }
    }
}

protocol ThemeType {
    var appearance: UIKeyboardAppearance { get }
    
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
    var popupBorderColor: UIColor { get }
    var activeColor: UIColor { get }
    var activeTextColor: UIColor { get }

    var keyCornerRadius: CGFloat { get }
    var popupCornerRadius: CGFloat { get }
    var keyVerticalMargin: CGFloat { get }
    var keyHorizontalMargin: CGFloat { get }

    var keyFont: UIFont { get }
    var lowerKeyFont: UIFont { get }
    var capitalKeyFont: UIFont { get }
    var modifierKeyFontSize: CGFloat { get }
    var altKeyFontSize: CGFloat { get }
    var altKeyFont: UIFont { get }
    var popupLowerKeyFont: UIFont { get }
    var popupCapitalKeyFont: UIFont { get }
    var popupLongpressLowerKeyFont: UIFont { get }
    var popupLongpressCapitalKeyFont: UIFont { get }
    var bannerFont: UIFont { get }

    var bannerBackgroundColor: UIColor { get }
    var bannerSeparatorColor: UIColor { get }
    var bannerTextColor: UIColor { get }

    var bannerHorizontalMargin: CGFloat { get }
    var bannerVerticalMargin: CGFloat { get }
    var bannerHeight: CGFloat { get }
}

class LightThemeImpl: ThemeType {
    var appearance: UIKeyboardAppearance { return .light }
    var bannerHeight: CGFloat { return IPhoneThemeBase.bannerHeight }
    
    var regularKeyColor = UIColor.white
    var specialKeyColor = UIColor(r: 162, g: 167, b: 177)
    var popupColor = UIColor.white
    var backgroundColor = UIColor(r: 203, g: 206, b: 212)
    var underColor = UIColor(hue: 0.611, saturation: 0.04, brightness: 0.56, alpha: 1)
    var textColor = UIColor.black
    var inactiveTextColor: UIColor = UIColor(white: 0.0, alpha: 0.3)
    var borderColor = UIColor.clear
    var popupBorderColor = UIColor(hue: 0.595, saturation: 0.04, brightness: 0.65, alpha: 1.0)
    var specialKeyBorderColor: UIColor { return .clear }
    var keyShadowColor = UIColor(r: 103, g: 106, b: 110, a: 0.5)
    var shiftActiveColor = UIColor.white
    var solidRegularKeyColor: UIColor { return regularKeyColor }
    var solidSpecialKeyColor = UIColor(r: 183, g: 191, b: 202)
    var solidPopupColor: UIColor { return popupColor }
    var activeColor: UIColor = UIColor(r: 31, g: 126, b: 249)
    var activeTextColor: UIColor = UIColor.white
    
    var keyCornerRadius: CGFloat { return IPhoneThemeBase.keyCornerRadius }
    var popupCornerRadius: CGFloat = 12.0
    var keyHorizontalMargin: CGFloat { return IPhoneThemeBase.keyHorizontalMargin }
    var keyVerticalMargin: CGFloat { return IPhoneThemeBase.keyVerticalMargin }

    var keyFont: UIFont { return IPhoneThemeBase.keyFont }
    var lowerKeyFont: UIFont { return IPhoneThemeBase.lowerKeyFont }
    var capitalKeyFont: UIFont { return IPhoneThemeBase.capitalKeyFont }
    var modifierKeyFontSize: CGFloat { return IPhoneThemeBase.modifierKeyFontSize }
    var popupLowerKeyFont: UIFont { return IPhoneThemeBase.lowerKeyFont.withSize(IPhoneThemeBase.lowerKeyFont.pointSize + 16.0) }
    var popupCapitalKeyFont: UIFont { return IPhoneThemeBase.capitalKeyFont.withSize(IPhoneThemeBase.capitalKeyFont.pointSize + 16.0) }
    var popupLongpressCapitalKeyFont = IPhoneThemeBase.capitalKeyFont //UIFont.systemFont(ofSize: 36.0)
    var popupLongpressLowerKeyFont = IPhoneThemeBase.lowerKeyFont //UIFont.systemFont(ofSize: 34.0, weight: .light)
//    var popupLongpressKeyFont = UIFont.systemFont(ofSize: 24.0)
    var bannerFont = UIFont.systemFont(ofSize: 18.0)
    var altKeyFont: UIFont { return IPadThemeBase.altKeyFont }
    var altKeyFontSize: CGFloat { return IPadThemeBase.altKeyFontSize }

    var bannerBackgroundColor: UIColor { return backgroundColor }
    var bannerSeparatorColor: UIColor { return solidSpecialKeyColor }
    var bannerTextColor: UIColor { return .black }

    var bannerHorizontalMargin: CGFloat = 16.0
    var bannerVerticalMargin: CGFloat = 8.0

    public init() {}
}

class DarkThemeImpl: ThemeType {
    var appearance: UIKeyboardAppearance { return .dark }
    var bannerHeight: CGFloat { return IPhoneThemeBase.bannerHeight }
    var backgroundColor: UIColor = .clear

    var keyShadowColor: UIColor = UIColor(r: 103, g: 106, b: 110, a: 0.5)

    var regularKeyColor = UIColor.lightGray.withAlphaComponent(CGFloat(0.4))
    var specialKeyColor = UIColor.gray.withAlphaComponent(CGFloat(0.3))
    var popupColor = UIColor(r: 111, g: 103, b: 111, a: 1.0)
    var underColor = UIColor(r: 39, g: 18, b: 39, a: 0.4)
    var textColor = UIColor.white
    var inactiveTextColor: UIColor = UIColor.lightGray
    var borderColor = UIColor.clear
    var popupBorderColor = UIColor.clear
    var specialKeyBorderColor: UIColor { return .clear }
    var shiftActiveColor = UIColor(r: 214, g: 220, b: 208)
    var solidRegularKeyColor = UIColor(r: 83, g: 83, b: 83)
    var solidSpecialKeyColor = UIColor(r: 45, g: 45, b: 45)
    var solidPopupColor: UIColor { return solidRegularKeyColor }
    var activeColor: UIColor = UIColor(r: 31, g: 126, b: 249)
    var activeTextColor: UIColor = UIColor.white
    var altKeyFont: UIFont { return IPadThemeBase.altKeyFont }
    var altKeyFontSize: CGFloat { return IPadThemeBase.altKeyFontSize }
//    var popupLongpressKeyFont = UIFont.systemFont(ofSize: 30.0)
    
    var keyCornerRadius: CGFloat { return IPhoneThemeBase.keyCornerRadius }
    var popupCornerRadius: CGFloat = 12.0
    var keyHorizontalMargin: CGFloat { return IPhoneThemeBase.keyHorizontalMargin }
    var keyVerticalMargin: CGFloat { return IPhoneThemeBase.keyVerticalMargin }

    var keyFont: UIFont { return IPhoneThemeBase.keyFont }
    var lowerKeyFont: UIFont { return IPhoneThemeBase.lowerKeyFont }
    var capitalKeyFont: UIFont { return IPhoneThemeBase.capitalKeyFont }
    var modifierKeyFontSize: CGFloat { return IPhoneThemeBase.modifierKeyFontSize }
    var popupLowerKeyFont: UIFont { return IPhoneThemeBase.lowerKeyFont.withSize(IPhoneThemeBase.lowerKeyFont.pointSize + 10.0) }
    var popupCapitalKeyFont: UIFont { return IPhoneThemeBase.capitalKeyFont.withSize(IPhoneThemeBase.capitalKeyFont.pointSize + 10.0) }
    var popupLongpressCapitalKeyFont = IPhoneThemeBase.capitalKeyFont //UIFont.systemFont(ofSize: 36.0)
    var popupLongpressLowerKeyFont = IPhoneThemeBase.lowerKeyFont //UIFont.systemFont(ofSize: 34.0, weight: .light)
    var bannerFont = UIFont.systemFont(ofSize: 16.0)

    var bannerBackgroundColor: UIColor { return regularKeyColor }
    var bannerSeparatorColor: UIColor { return .clear }
    var bannerTextColor: UIColor { return .white }

    var bannerHorizontalMargin: CGFloat = 16.0
    var bannerVerticalMargin: CGFloat = 8.0

    public init() {}
}

private class IPhoneThemeBase {
    static let keyHorizontalMargin: CGFloat = {
        switch UIDevice.current.dc.deviceModel {
        case .iPhoneX, .iPhoneXR, .iPhoneXS, .iPhone11, .iPhone11Pro:
            return 3.0
        case .iPhone11ProMax, .iPhoneXSMax:
            return 3.0
        case .iPhone5S, .iPhone5C:
            return 3.0
        default:
            return 3.0
        }
    }()
    static let portraitKeyVerticalMargin: CGFloat = {
        switch UIDevice.current.dc.deviceModel {
        case .iPhone5S, .iPhone5C:
            return 8.0
        case .iPhone6, .iPhone6S, .iPhone6Plus, .iPhone6SPlus, .iPhone7, .iPhone7Plus, .iPhone8:
            return 6.5
        case .iPhone8Plus, .iPhoneX, .iPhoneXR, .iPhoneXS, .iPhone11, .iPhone11Pro, .iPhone11ProMax, .iPhoneXSMax:
            return 6.0
        default:
            return 6.0
        }
    }()
    static let landscapeKeyVerticalMargin: CGFloat = {
        switch UIDevice.current.dc.deviceModel {
        case .iPhone5S, .iPhone5C:
            return 4.5
        case .iPhone6, .iPhone6S, .iPhone6Plus, .iPhone6SPlus, .iPhone7, .iPhone7Plus, .iPhone8:
            return 3.5
        case .iPhone8Plus, .iPhoneX, .iPhoneXR, .iPhoneXS, .iPhone11, .iPhone11Pro, .iPhone11ProMax, .iPhoneXSMax:
            return 3.5
        default:
            return 3.5
        }
    }()
    
    static var keyVerticalMargin: CGFloat {
        if UIScreen.main.isDeviceLandscape {
            return landscapeKeyVerticalMargin
        } else {
            return portraitKeyVerticalMargin
        }
    }
    
    static let keyCornerRadius: CGFloat = {
        switch UIDevice.current.dc.deviceModel {
        case .iPhone5S, .iPhone5C:
            return 4.0
        case .iPhone6, .iPhone6S, .iPhone6Plus, .iPhone6SPlus, .iPhone7, .iPhone7Plus, .iPhone8, .iPhone8Plus, .iPhoneX, .iPhoneXR, .iPhoneXS, .iPhone11, .iPhone11Pro, .iPhone11ProMax, .iPhoneXSMax:
            return 5.0
        default:
            return 5.0
        }
    }()
    
    static let bannerHeight: CGFloat = 42.0
    
    static let keyFont: UIFont = UIFont.systemFont(ofSize: 28.0) // TODO: this can be deprecated
    static let lowerKeyFont: UIFont = UIFont.systemFont(ofSize: 25.0, weight: .light)
    static let capitalKeyFont: UIFont = UIFont.systemFont(ofSize: 22.0)
    static let modifierKeyFontSize: CGFloat = 16.0
    
    private init() { fatalError() }
    
}

private class IPadThemeBase {
    static let altKeyFontSize: CGFloat = 13.0
    static let altKeyFont: UIFont = UIFont.systemFont(ofSize: altKeyFontSize)
    static let keyFont: UIFont = UIFont.systemFont(ofSize: 21.0)
    static let alternateKeyFontSize: CGFloat = 17.0
    
    static let bannerHeight: CGFloat = 55.0
    
    static let keyCornerRadius: CGFloat = 5.0
    static let keyHorizontalMargin: CGFloat = (UIDevice.current.dc.screenSize.sizeInches ?? Screen.maxSupportedInches) > 10
        ? 3.0
        : 5.0
    static let keyVerticalMargin: CGFloat = (UIDevice.current.dc.screenSize.sizeInches ?? Screen.maxSupportedInches) > 10
        ? 3.0
        : 5.0
    
    private init() { fatalError() }
}

class LightThemeIpadImpl: LightThemeImpl {
    override var keyCornerRadius: CGFloat { return IPadThemeBase.keyCornerRadius }
    override var keyHorizontalMargin: CGFloat { return IPadThemeBase.keyHorizontalMargin }
    override var keyVerticalMargin: CGFloat { return IPadThemeBase.keyVerticalMargin }
    
    override var keyFont: UIFont { return IPadThemeBase.keyFont }
    override var modifierKeyFontSize: CGFloat { return IPadThemeBase.alternateKeyFontSize }
    override var bannerHeight: CGFloat { return IPadThemeBase.bannerHeight }
}

class DarkThemeIpadImpl: DarkThemeImpl {
    override var keyCornerRadius: CGFloat { return IPadThemeBase.keyCornerRadius }
    override var keyHorizontalMargin: CGFloat { return IPadThemeBase.keyHorizontalMargin }
    override var keyVerticalMargin: CGFloat { return IPadThemeBase.keyVerticalMargin }

    override var keyFont: UIFont { return IPadThemeBase.keyFont }
    override var modifierKeyFontSize: CGFloat { return IPadThemeBase.alternateKeyFontSize }
    override var bannerHeight: CGFloat { return IPadThemeBase.bannerHeight }
}

private let LightTheme = UIDevice.current.dc.isIpad ? LightThemeIpadImpl() : LightThemeImpl()
private let DarkTheme = UIDevice.current.dc.isIpad ? DarkThemeIpadImpl() : DarkThemeImpl()

let Theme = _Theme(dark: DarkTheme, light: LightTheme)
