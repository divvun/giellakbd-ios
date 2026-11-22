import Foundation
import UIKit

// MARK: - Theme

struct Theme {
    /// The system keyboard this theme copies. `Theme.current` picks it for the running system, and everything else
    /// sized or drawn for one system keyboard, such as the keyboard's height, takes it from here.
    let design: KeyboardDesign

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
    let longPressActiveColor: UIColor
    let altKeyTextColor: UIColor

    // Metrics
    let keyCornerRadius: CGFloat
    let popupCornerRadius: CGFloat
    let keyHorizontalMargin: CGFloat
    /// Key heights, the gap between rows and the space above and below them.
    let keyArea: KeyAreaMetrics

    // Fonts
    let lowerKeyFont: UIFont
    let capitalKeyFont: UIFont
    let modifierKeyFontSize: CGFloat
    let altKeyFontSize: CGFloat
    let altKeyFont: UIFont
    /// Font for both labels of the keys in a number row drawn shorter than the other rows, as on 13-inch iPads.
    let numberRowKeyFont: UIFont
    let popupLowerKeyFont: UIFont
    let popupCapitalKeyFont: UIFont
    let popupLongpressLowerKeyFont: UIFont
    let popupLongpressCapitalKeyFont: UIFont
    let bannerFont: UIFont

    // SF Symbols
    let sfSymbolConfiguration: UIImage.SymbolConfiguration

    // Banner
    let bannerBackgroundColor: UIColor
    let bannerSeparatorColor: UIColor
    /// Space between the banner's separators and its bottom edge, where they line up with the system keyboard's.
    /// `nil` centres them in the banner.
    let bannerSeparatorBottomInset: CGFloat?
    let bannerTextColor: UIColor
    let bannerHorizontalMargin: CGFloat
    let bannerHeight: CGFloat

    // Layout
    let altLabelTopAnchorConstant: CGFloat
    let altLabelBottomAnchorConstant: CGFloat
    let popupLongpressKeysPerRow: Int

    // MARK: - Static Factory Methods

    /// Get the current theme for the given trait collection
    /// This is the main entry point for creating themes
    /// - Parameter device: The context for the screen the keyboard is on. Orientation-dependent sizes
    ///   come from it, so pass `DeviceContext.current(in:)` with the view the theme is for.
    static func current(for traits: UITraitCollection, device: DeviceContext) -> Theme {
        ThemeFactory.make(isDark: traits.userInterfaceStyle == .dark, design: .current, device: device, traits: traits)
    }
}

// MARK: - Keyboard Design

/// The system keyboard whose sizes, colours and keys the keyboard copies.
enum KeyboardDesign {
    /// The keyboard from iOS 18 and earlier: every version the app supports before iOS 26.
    case iOS18
    /// The keyboard from iOS 26. Later versions use it until their keyboard is measured.
    case iOS26

    /// The design for the running system. The only place the keyboard checks the iOS version.
    static var current: KeyboardDesign {
        iOSVersion.isIOS26OrNewer ? .iOS26 : .iOS18
    }
}


// MARK: - Theme Factory

private struct ThemeFactory {
    static func make(isDark: Bool, design: KeyboardDesign, device: DeviceContext, traits: UITraitCollection) -> Theme {
        let metrics = makeMetrics(for: device, traits: traits, design: design)
        let fonts = makeFonts(for: device, traits: traits, design: design)
        let colors = makeColors(isDark: isDark, design: design, device: device)

        return Theme(
            design: design,

            // Colors
            appearance: isDark ? .dark : .light,
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
            longPressActiveColor: colors.longPressActive,
            altKeyTextColor: colors.altKeyText,

            // Metrics
            keyCornerRadius: metrics.keyCornerRadius,
            popupCornerRadius: 12.0,
            keyHorizontalMargin: metrics.keyHorizontalMargin,
            keyArea: KeyboardHeightProvider.keyArea(for: device, traitCollection: traits, design: design),

            // Fonts
            lowerKeyFont: fonts.lowerKey,
            capitalKeyFont: fonts.capitalKey,
            modifierKeyFontSize: fonts.modifierKeySize,
            altKeyFontSize: fonts.altKeySize,
            altKeyFont: fonts.altKey,
            numberRowKeyFont: fonts.numberRowKey,
            popupLowerKeyFont: fonts.lowerKey.withSize(fonts.lowerKey.pointSize + (isDark ? 10.0 : 16.0)),
            popupCapitalKeyFont: fonts.capitalKey.withSize(fonts.capitalKey.pointSize + (isDark ? 10.0 : 16.0)),
            popupLongpressLowerKeyFont: fonts.lowerKey,
            popupLongpressCapitalKeyFont: fonts.capitalKey,
            bannerFont: fonts.banner,

            // SF Symbols
            sfSymbolConfiguration: metrics.sfSymbolConfiguration,

            // Banner
            bannerBackgroundColor: colors.background,
            bannerSeparatorColor: colors.bannerSeparator,
            bannerSeparatorBottomInset: KeyboardHeightProvider.bannerSeparatorBottomInset(
                for: device, traitCollection: traits, design: design),
            bannerTextColor: colors.bannerText,
            bannerHorizontalMargin: 16.0,
            bannerHeight: KeyboardHeightProvider.bannerHeight(for: device, traitCollection: traits,
                                                              design: design),

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
        let altLabelTop: CGFloat
        let altLabelBottom: CGFloat
        let popupLongpressKeysPerRow: Int
        let sfSymbolConfiguration: UIImage.SymbolConfiguration
    }

    private static func makeMetrics(for device: DeviceContext, traits: UITraitCollection,
                                    design: KeyboardDesign) -> Metrics {
        if device.shouldUseIPadLayout(traitCollection: traits) {
            return makeiPadMetrics(for: device, design: design)
        } else {
            return makeiPhoneMetrics(for: device, design: design)
        }
    }

    private static func makeiPhoneMetrics(for device: DeviceContext, design: KeyboardDesign) -> Metrics {
        // iOS 26 has significantly larger corner radius for rounder keys
        let keyCornerRadius: CGFloat = design == .iOS18 ? 5.0 : 10.0

        let sfSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: device.isLandscape ? 19 : 20,
            weight: .regular
        )

        return Metrics(
            keyCornerRadius: keyCornerRadius,
            keyHorizontalMargin: 3.0,
            altLabelTop: 0.0,
            altLabelBottom: 0.0,
            popupLongpressKeysPerRow: 10,
            sfSymbolConfiguration: sfSymbolConfiguration
        )
    }

    private static func makeiPadMetrics(for device: DeviceContext, design: KeyboardDesign) -> Metrics {
        let keyCornerRadius: CGFloat = {
            if design == .iOS18 {
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
            else if device.isLargeIPad { return 3.0 } // Large iPad in portrait
            else { return 5.0 } // Small/medium iPad in portrait
        }()

        let altLabelTop: CGFloat = {
            if device.isLargeIPad { return 3.0 } // More spacing from top edge
            else if device.isSmallOrMediumLandscape { return 4.0 }
            else { return 5.0 }
        }()

        let altLabelBottom: CGFloat = {
            if device.isLargeIPad { return -3.0 } // More spacing from bottom
            else if device.isSmallOrMediumLandscape { return -5.0 }
            else { return -4.0 }
        }()

        let sfSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: device.isLandscape ? 24 : 21,
            weight: .light
        )

        return Metrics(
            keyCornerRadius: keyCornerRadius,
            keyHorizontalMargin: keyHorizontalMargin,
            altLabelTop: altLabelTop,
            altLabelBottom: altLabelBottom,
            popupLongpressKeysPerRow: 4,
            sfSymbolConfiguration: sfSymbolConfiguration
        )
    }

    // MARK: - Fonts

    private struct Fonts {
        let lowerKey: UIFont
        let capitalKey: UIFont
        let modifierKeySize: CGFloat
        let altKeySize: CGFloat
        let altKey: UIFont
        let numberRowKey: UIFont
        let banner: UIFont
    }

    private static func makeFonts(for device: DeviceContext, traits: UITraitCollection,
                                  design: KeyboardDesign) -> Fonts {
        if device.shouldUseIPadLayout(traitCollection: traits) {
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
                // The system keyboard's number row on 13-inch iPads, measured from its digits' cap height
                numberRowKey: UIFont.systemFont(ofSize: device.isLandscape ? 19.0 : 14.0),
                banner: UIFont.systemFont(ofSize: 17.0)
            )
        } else {
            let altKeySize: CGFloat = 13.0
            let lowerKey = design == .iOS18
                ? UIFont.systemFont(ofSize: 25.0, weight: .light)
                : UIFont.systemFont(ofSize: 25.0)
            
            return Fonts(
                lowerKey: lowerKey,
                capitalKey: UIFont.systemFont(ofSize: 22.0),
                modifierKeySize: 16.0,
                altKeySize: altKeySize,
                altKey: UIFont.systemFont(ofSize: altKeySize),
                numberRowKey: UIFont.systemFont(ofSize: altKeySize),
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
        let longPressActive: UIColor
        let altKeyText: UIColor
        let bannerSeparator: UIColor
        let bannerText: UIColor
    }

    private static func makeColors(isDark: Bool, design: KeyboardDesign, device: DeviceContext) -> Colors {
        let blueLegacy = UIColor(r: 31, g: 126, b: 249)
        
        if isDark {
            let keyShadow = design == .iOS18
                ? UIColor(r: 103, g: 106, b: 110, a: 0.5)
                : .clear

            let regularKey = design == .iOS18
                ? UIColor.lightGray.withAlphaComponent(0.4)
                : UIColor(r: 61, g: 61, b: 61)

            // iOS 26: Special keys use same color as regular keys
            let specialKey = design == .iOS18
                ? UIColor.gray.withAlphaComponent(0.3)
                : regularKey
            
            let popup = design == .iOS18
                ? UIColor(r: 109, g: 109, b: 109)
                : UIColor(r: 83, g: 83, b: 83)

            let activeKeyColor = design == .iOS18
                ? blueLegacy
                : UIColor(r: 38, g: 38, b: 38)
            
            let longPressActive = design == .iOS18
                ? blueLegacy
                : UIColor(r: 0, g: 145, b: 255)

            return Colors(
                regularKey: regularKey,
                specialKey: specialKey,
                popup: popup,
                background: .clear,
                text: .white,
                inactiveText: .lightGray,
                border: .clear,
                specialKeyBorder: .clear,
                keyShadow: keyShadow,
                shiftActive: specialKey,
                shiftTint: .white,
                popupBorder: .clear,
                active: activeKeyColor,
                activeText: .white,
                longPressActive: longPressActive,
                altKeyText: device.isLargeIPad ? UIColor.white : UIColor.lightGray,
                bannerSeparator: UIColor(r: 56, g: 56, b: 57),
                bannerText: UIColor(r: 233, g: 233, b: 233)
            )
        } else {
            let keyShadow = design == .iOS18
                ? UIColor(r: 136, g: 138, b: 141)
                : .clear

            // iOS 26: Special keys look the same as regular keys
            let specialKeyColor = design == .iOS18
                ? UIColor(r: 171, g: 177, b: 186)
                : .white
            
            let popupBorder = design == .iOS18
                ? UIColor(hue: 0.595, saturation: 0.04, brightness: 0.65, alpha: 1.0)
                : .clear

            let activeKeyColor = design == .iOS18
                ? blueLegacy
                : UIColor(r: 231, g: 232, b: 236)
            
            let longPressActive = design == .iOS18
                ? blueLegacy
                : UIColor(r: 0, g: 136, b: 255)

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
                popupBorder: popupBorder,
                active: activeKeyColor,
                activeText: .white,
                longPressActive: longPressActive,
                altKeyText: device.isLargeIPad ? UIColor.black : UIColor(white: 0.0, alpha: 0.3),
                // The system keyboard's separators: black at 6.6%, (211, 212, 217) over the keyboard's background
                bannerSeparator: design == .iOS18 ? UIColor(r: 188, g: 191, b: 195) : UIColor(white: 0, alpha: 0.066),
                bannerText: UIColor(r: 21, g: 21, b: 21)
            )
        }
    }
}

extension Theme {
    /// The appearance `current(for:)` would give a theme built for these traits, without building one.
    /// Only the interface style decides it, so callers can check for a light/dark switch cheaply.
    static func appearance(for traits: UITraitCollection) -> UIKeyboardAppearance {
        traits.userInterfaceStyle == .dark ? .dark : .light
    }
}
