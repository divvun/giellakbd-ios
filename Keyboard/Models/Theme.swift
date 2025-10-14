import Foundation
import UIKit

// MARK: - Theme Configuration

// Backward compatibility typealias
typealias ThemeType = ThemeConfiguration

struct ThemeConfiguration {
    // Colors
    let appearance: UIKeyboardAppearance
    let regularKeyColor: UIColor
    let specialKeyColor: UIColor
    let popupColor: UIColor
    let backgroundColor: UIColor
    let textColor: UIColor
    let inactiveTextColor: UIColor
    let borderColor: UIColor
    let specialKeyBorderColor: UIColor
    let keyShadowColor: UIColor
    let shiftActiveColor: UIColor
    let shiftTintColor: UIColor
    let popupBorderColor: UIColor
    let activeColor: UIColor
    let activeTextColor: UIColor
    let altKeyTextColor: UIColor

    // Metrics
    let keyCornerRadius: CGFloat
    let popupCornerRadius: CGFloat
    let keyVerticalMargin: CGFloat
    let keyHorizontalMargin: CGFloat

    // Fonts
    let lowerKeyFont: UIFont
    let capitalKeyFont: UIFont
    let modifierKeyFontSize: CGFloat
    let altKeyFontSize: CGFloat
    let altKeyFont: UIFont
    let popupLowerKeyFont: UIFont
    let popupCapitalKeyFont: UIFont
    let popupLongpressLowerKeyFont: UIFont
    let popupLongpressCapitalKeyFont: UIFont
    let bannerFont: UIFont

    // Banner
    let bannerBackgroundColor: UIColor
    let bannerSeparatorColor: UIColor
    let bannerTextColor: UIColor
    let bannerHorizontalMargin: CGFloat
    let bannerVerticalMargin: CGFloat
    let bannerHeight: CGFloat

    // Layout
    let altLabelTopAnchorConstant: CGFloat
    let altLabelBottomAnchorConstant: CGFloat
    let popupLongpressKeysPerRow: Int
}

// MARK: - Device Context

struct DeviceContext {
    let idiom: UIUserInterfaceIdiom
    let screenInches: CGFloat
    let isLandscape: Bool

    var isPhone: Bool { idiom == .phone }
    var isPad: Bool { idiom == .pad }
    var isLargeiPad: Bool { isPad && screenInches >= 11 }
    var isLargeLandscape: Bool { isLargeiPad && isLandscape }
    var isSmallOrMediumLandscape: Bool { isPad && screenInches < 11 && isLandscape }

    static func current() -> DeviceContext {
        let screenInches = UIDevice.current.dc.screenSize.sizeInches ?? Screen.maxSupportedInches
        return DeviceContext(
            idiom: UIDevice.current.userInterfaceIdiom,
            screenInches: screenInches,
            isLandscape: UIScreen.main.isDeviceLandscape
        )
    }
}

// MARK: - Theme Variants

enum ThemeStyle {
    case light
    case dark
    case legacyLight
    case legacyDark

    var isLegacy: Bool {
        switch self {
        case .legacyLight, .legacyDark: return true
        case .light, .dark: return false
        }
    }

    var isDark: Bool {
        switch self {
        case .dark, .legacyDark: return true
        case .light, .legacyLight: return false
        }
    }
}

// MARK: - Theme

struct Theme {
    let light: ThemeConfiguration
    let dark: ThemeConfiguration
    let legacyLight: ThemeConfiguration
    let legacyDark: ThemeConfiguration

    /// Select theme configuration based on traits and optionally override iOS version detection
    /// - Parameters:
    ///   - traits: The UITraitCollection to determine light/dark mode
    ///   - useLegacy: Optional override. If nil (default), auto-detects iOS version. If true/false, forces legacy/modern theme.
    func select(traits: UITraitCollection, useLegacy: Bool? = nil) -> ThemeConfiguration {
        let isDark = traits.userInterfaceStyle == .dark
        let shouldUseLegacy = useLegacy ?? !iOSVersion.isIOS26OrNewer

        switch (isDark, shouldUseLegacy) {
        case (true, true): return legacyDark
        case (true, false): return dark
        case (false, true): return legacyLight
        case (false, false): return light
        }
    }

    /// Create a theme for the current device
    static func forCurrentDevice() -> Theme {
        return forDevice(DeviceContext.current())
    }

    /// Create a theme for a specific device context (useful for testing)
    static func forDevice(_ device: DeviceContext) -> Theme {
        return Theme(
            light: ThemeFactory.make(.light, device: device),
            dark: ThemeFactory.make(.dark, device: device),
            legacyLight: ThemeFactory.make(.legacyLight, device: device),
            legacyDark: ThemeFactory.make(.legacyDark, device: device)
        )
    }
}

// MARK: - Theme Factory

private struct ThemeFactory {
    static func make(_ style: ThemeStyle, device: DeviceContext) -> ThemeConfiguration {
        let metrics = makeMetrics(for: device, legacy: style.isLegacy)
        let fonts = makeFonts(for: device)
        let colors = makeColors(for: style, device: device)

        return ThemeConfiguration(
            // Colors
            appearance: style.isDark ? .dark : .light,
            regularKeyColor: colors.regularKey,
            specialKeyColor: colors.specialKey,
            popupColor: colors.popup,
            backgroundColor: colors.background,
            textColor: colors.text,
            inactiveTextColor: colors.inactiveText,
            borderColor: colors.border,
            specialKeyBorderColor: colors.specialKeyBorder,
            keyShadowColor: colors.keyShadow,
            shiftActiveColor: colors.shiftActive,
            shiftTintColor: colors.shiftTint,
            popupBorderColor: colors.popupBorder,
            activeColor: colors.active,
            activeTextColor: colors.activeText,
            altKeyTextColor: colors.altKeyText,

            // Metrics
            keyCornerRadius: metrics.keyCornerRadius,
            popupCornerRadius: 12.0,
            keyVerticalMargin: metrics.keyVerticalMargin,
            keyHorizontalMargin: metrics.keyHorizontalMargin,

            // Fonts
            lowerKeyFont: fonts.lowerKey,
            capitalKeyFont: fonts.capitalKey,
            modifierKeyFontSize: fonts.modifierKeySize,
            altKeyFontSize: fonts.altKeySize,
            altKeyFont: fonts.altKey,
            popupLowerKeyFont: fonts.lowerKey.withSize(fonts.lowerKey.pointSize + (style.isDark ? 10.0 : 16.0)),
            popupCapitalKeyFont: fonts.capitalKey.withSize(fonts.capitalKey.pointSize + (style.isDark ? 10.0 : 16.0)),
            popupLongpressLowerKeyFont: fonts.lowerKey,
            popupLongpressCapitalKeyFont: fonts.capitalKey,
            bannerFont: fonts.banner,

            // Banner
            bannerBackgroundColor: colors.background,
            bannerSeparatorColor: colors.bannerSeparator,
            bannerTextColor: colors.bannerText,
            bannerHorizontalMargin: 16.0,
            bannerVerticalMargin: 8.0,
            bannerHeight: metrics.bannerHeight,

            // Layout
            altLabelTopAnchorConstant: metrics.altLabelTop,
            altLabelBottomAnchorConstant: metrics.altLabelBottom,
            popupLongpressKeysPerRow: metrics.popupLongpressKeysPerRow
        )
    }

    // MARK: - Metrics

    private struct Metrics {
        let keyCornerRadius: CGFloat
        let keyHorizontalMargin: CGFloat
        let keyVerticalMargin: CGFloat
        let bannerHeight: CGFloat
        let altLabelTop: CGFloat
        let altLabelBottom: CGFloat
        let popupLongpressKeysPerRow: Int
    }

    private static func makeMetrics(for device: DeviceContext, legacy: Bool) -> Metrics {
        if device.isPad {
            return makeiPadMetrics(for: device, legacy: legacy)
        } else {
            return makeiPhoneMetrics(for: device, legacy: legacy)
        }
    }

    private static func makeiPhoneMetrics(for device: DeviceContext, legacy: Bool) -> Metrics {
        // iOS 26 has significantly larger corner radius for rounder keys
        let keyCornerRadius: CGFloat = legacy ? 5.0 : 10.0

        let keyVerticalMargin: CGFloat = {
            // Simplified - in production you'd check device model via UIDevice.current.dc.deviceModel
            device.isLandscape ? 3.5 : 6.0
        }()

        let bannerHeight: CGFloat = 48.0 // Simplified - could check for smaller devices

        return Metrics(
            keyCornerRadius: keyCornerRadius,
            keyHorizontalMargin: 3.0,
            keyVerticalMargin: keyVerticalMargin,
            bannerHeight: bannerHeight,
            altLabelTop: 0.0,
            altLabelBottom: 0.0,
            popupLongpressKeysPerRow: 10
        )
    }

    private static func makeiPadMetrics(for device: DeviceContext, legacy: Bool) -> Metrics {
        let keyCornerRadius: CGFloat = {
            if legacy {
                if device.isLargeLandscape { return 7.0 }
                else if device.isSmallOrMediumLandscape { return 6.0 }
                else { return 5.0 }
            } else {
                // iOS 26 style - significantly larger corner radius for rounder keys
                if device.isLargeLandscape { return 12.0 }
                else if device.isSmallOrMediumLandscape { return 11.0 }
                else { return 10.0 }
            }
        }()

        let keyHorizontalMargin: CGFloat = {
            if device.isLargeLandscape { return 4.0 }
            else if device.isSmallOrMediumLandscape { return 7.0 }
            else { return 5.0 }
        }()

        let keyVerticalMargin: CGFloat = {
            if device.isLargeLandscape { return 4.0 }
            else if device.isSmallOrMediumLandscape { return 6.0 }
            else { return 5.0 }
        }()

        let altLabelTop: CGFloat = {
            if device.isLargeiPad { return 0.0 }
            else if device.isSmallOrMediumLandscape { return 4.0 }
            else { return 5.0 }
        }()

        let altLabelBottom: CGFloat = {
            if device.isLargeiPad { return -3.0 }
            else if device.isSmallOrMediumLandscape { return -5.0 }
            else { return -4.0 }
        }()

        return Metrics(
            keyCornerRadius: keyCornerRadius,
            keyHorizontalMargin: keyHorizontalMargin,
            keyVerticalMargin: keyVerticalMargin,
            bannerHeight: 55.0,
            altLabelTop: altLabelTop,
            altLabelBottom: altLabelBottom,
            popupLongpressKeysPerRow: 4
        )
    }

    // MARK: - Fonts

    private struct Fonts {
        let lowerKey: UIFont
        let capitalKey: UIFont
        let modifierKeySize: CGFloat
        let altKeySize: CGFloat
        let altKey: UIFont
        let banner: UIFont
    }

    private static func makeFonts(for device: DeviceContext) -> Fonts {
        if device.isPad {
            let altKeySize: CGFloat = device.isSmallOrMediumLandscape ? 16.0 : 13.0
            let lowerKey: UIFont = {
                (device.isLargeLandscape || device.isSmallOrMediumLandscape)
                ? UIFont.systemFont(ofSize: 29.0)
                : UIFont.systemFont(ofSize: 24.0, weight: .light)
            }()
            let capitalKey: UIFont = {
                (device.isLargeLandscape || device.isSmallOrMediumLandscape)
                ? UIFont.systemFont(ofSize: 28.0)
                : UIFont.systemFont(ofSize: 22.0)
            }()

            return Fonts(
                lowerKey: lowerKey,
                capitalKey: capitalKey,
                modifierKeySize: 17.0,
                altKeySize: altKeySize,
                altKey: UIFont.systemFont(ofSize: altKeySize),
                banner: UIFont.systemFont(ofSize: 17.0)
            )
        } else {
            let altKeySize: CGFloat = 13.0
            return Fonts(
                lowerKey: UIFont.systemFont(ofSize: 25.0, weight: .light),
                capitalKey: UIFont.systemFont(ofSize: 22.0),
                modifierKeySize: 16.0,
                altKeySize: altKeySize,
                altKey: UIFont.systemFont(ofSize: altKeySize),
                banner: UIFont.systemFont(ofSize: 17.0)
            )
        }
    }

    // MARK: - Colors

    private struct Colors {
        let regularKey: UIColor
        let specialKey: UIColor
        let popup: UIColor
        let background: UIColor
        let text: UIColor
        let inactiveText: UIColor
        let border: UIColor
        let specialKeyBorder: UIColor
        let keyShadow: UIColor
        let shiftActive: UIColor
        let shiftTint: UIColor
        let popupBorder: UIColor
        let active: UIColor
        let activeText: UIColor
        let altKeyText: UIColor
        let bannerSeparator: UIColor
        let bannerText: UIColor
    }

    private static func makeColors(for style: ThemeStyle, device: DeviceContext) -> Colors {
        if style.isDark {
            // iOS 26 uses flatter design with no/minimal shadows
            let keyShadow = style.isLegacy
                ? UIColor(r: 103, g: 106, b: 110, a: 0.5)
                : .clear

            return Colors(
                regularKey: UIColor.lightGray.withAlphaComponent(0.4),
                specialKey: UIColor.gray.withAlphaComponent(0.3),
                popup: UIColor(r: 109, g: 109, b: 109),
                background: .clear,
                text: .white,
                inactiveText: .lightGray,
                border: .clear,
                specialKeyBorder: .clear,
                keyShadow: keyShadow,
                shiftActive: UIColor(r: 214, g: 220, b: 208),
                shiftTint: .black,
                popupBorder: .clear,
                active: UIColor(r: 31, g: 126, b: 249),
                activeText: .white,
                altKeyText: device.screenInches > 10 ? UIColor.white : UIColor.lightGray,
                bannerSeparator: UIColor(r: 56, g: 56, b: 57),
                bannerText: UIColor(r: 233, g: 233, b: 233)
            )
        } else {
            // iOS 26 uses flatter design with no shadows
            let keyShadow = style.isLegacy
                ? UIColor(r: 136, g: 138, b: 141)
                : .clear

            // iOS 26: Special keys use white background like regular keys
            let specialKeyColor = style.isLegacy
                ? UIColor(r: 171, g: 177, b: 186)
                : .white

            return Colors(
                regularKey: .white,
                specialKey: specialKeyColor,
                popup: .white,
                background: UIColor(r: 209, g: 212, b: 217, a: 0.0),
                text: .black,
                inactiveText: UIColor(white: 0.0, alpha: 0.3),
                border: .clear,
                specialKeyBorder: .clear,
                keyShadow: keyShadow,
                shiftActive: .white,
                shiftTint: .black,
                popupBorder: UIColor(hue: 0.595, saturation: 0.04, brightness: 0.65, alpha: 1.0),
                active: UIColor(r: 31, g: 126, b: 249),
                activeText: .white,
                altKeyText: device.screenInches >= 11 ? UIColor.black : UIColor(white: 0.0, alpha: 0.3),
                bannerSeparator: UIColor(r: 188, g: 191, b: 195),
                bannerText: UIColor(r: 21, g: 21, b: 21)
            )
        }
    }
}

// MARK: - Utilities

// iOS version detection
struct iOSVersion {
    static var current: OperatingSystemVersion {
        return ProcessInfo.processInfo.operatingSystemVersion
    }

    static var majorVersion: Int {
        return current.majorVersion
    }

    static var isIOS26OrNewer: Bool {
        return majorVersion >= 26
    }
}

// Global screen size utility for backward compatibility
let screenInches = UIDevice.current.dc.screenSize.sizeInches ?? Screen.maxSupportedInches

// MARK: - Convenience

extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) {
        self.init(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: a)
    }
}
