import UIKit
import Sentry

typealias KeyboardHeight = (portrait: CGFloat, landscape: CGFloat)

/// Sizes of the key area, in points.
///
/// Keys in neighbouring rows are `rowGap` apart. The top row's keys sit `topInset` below the top of the key area and
/// the bottom row's keys `bottomInset` above its bottom.
struct KeyAreaMetrics: Equatable {
    var keyHeight: CGFloat
    /// Height of the number row's keys, on devices where the system keyboard draws its number row shorter than the
    /// other rows, such as 13-inch iPads. `nil` where every row is `keyHeight` tall.
    var numberRowKeyHeight: CGFloat?
    var rowGap: CGFloat
    var topInset: CGFloat
    var bottomInset: CGFloat
    /// Extra space between each side of the key area and the outermost keys, on top of the keys' own horizontal
    /// margin.
    var sideInset: CGFloat = 0

    /// Layouts with a number row have at least this many rows: the number row and the four letter rows below it.
    static let minimumRowCountWithNumberRow = 5

    /// Whether the first of `rowCount` rows is a number row, drawn shorter than the others.
    func hasNumberRow(rowCount: Int) -> Bool {
        numberRowKeyHeight != nil && rowCount >= Self.minimumRowCountWithNumberRow
    }

    /// Height of the keys in each row.
    func keyHeights(rowCount: Int) -> [CGFloat] {
        let hasNumberRow = hasNumberRow(rowCount: rowCount)
        return (0..<max(rowCount, 0)).map { row in
            row == 0 && hasNumberRow ? numberRowKeyHeight ?? keyHeight : keyHeight
        }
    }

    /// Height of a key area with `rowCount` rows.
    func height(rowCount: Int) -> CGFloat {
        let keys = keyHeights(rowCount: rowCount).reduce(0, +)
        return topInset + keys + CGFloat(max(rowCount - 1, 0)) * rowGap + bottomInset
    }
}

struct KeyboardHeightProvider {

    /// Height of the keyboard, banner included, for a layout with `rowCount` rows.
    ///
    /// The banner and the key area are sized separately, so either can change without resizing the other. Layouts
    /// with more rows than usual keep their key height until the keyboard would grow taller than earlier versions
    /// made it, and their keys shrink to fit from there.
    /// - Parameters:
    ///   - rowCount: Rows in the layout. Defaults to the usual number for the device.
    ///   - legacy: Whether to size for the keyboard before iOS 26. Defaults to the running system.
    static func height(
        for deviceContext: DeviceContext,
        traitCollection: UITraitCollection,
        rowCount: Int? = nil,
        legacy: Bool = !iOSVersion.isIOS26OrNewer
    ) -> CGFloat {
        let normalRowCount = self.normalRowCount(for: deviceContext)
        let rowCount = rowCount ?? normalRowCount
        let keyArea = keyArea(for: deviceContext, traitCollection: traitCollection, legacy: legacy)
        let height = bannerHeight(for: deviceContext, traitCollection: traitCollection) + keyArea.height(rowCount: rowCount)

        guard rowCount > normalRowCount else {
            return height
        }
        return min(height, maximumHeight(for: deviceContext, traitCollection: traitCollection, rowCount: rowCount))
    }

    /// Height of the banner above the keys.
    static func bannerHeight(for deviceContext: DeviceContext, traitCollection: UITraitCollection) -> CGFloat {
        deviceContext.shouldUseIPadLayout(traitCollection: traitCollection) ? 55 : 48
    }

    /// Sizes of the key area for the device's usual number of rows.
    ///
    /// On iOS 26 and later, uses the system keyboard's sizes where they have been measured. Elsewhere, fits the rows
    /// into the key area of the height table, with the key margin above and below each row as before.
    static func keyArea(for deviceContext: DeviceContext, traitCollection: UITraitCollection,
                        legacy: Bool = !iOSVersion.isIOS26OrNewer) -> KeyAreaMetrics {
        if !legacy, let measured = measuredKeyArea(for: deviceContext, traitCollection: traitCollection) {
            return measured
        }
        return fittedKeyArea(for: deviceContext, traitCollection: traitCollection, legacy: legacy)
    }

    /// Rows in a layout for the device: 4, or 5 on large iPads, whose layouts start with a number row.
    private static func normalRowCount(for deviceContext: DeviceContext) -> Int {
        deviceContext.isLargeIPad ? 5 : 4
    }

    /// The system keyboard's key area on iOS 26 and later, measured from simulator screenshots, or `nil` where it
    /// hasn't been measured.
    ///
    /// Side insets put the outermost keys as far from the screen edges as the system keyboard's. Insets put the bottom
    /// row where the system keyboard's ends. The extension's view ends higher than the system
    /// keyboard's own key area: 75 pt above the bottom of the screen on iPhones in portrait, where the system shows its
    /// globe and dictation bar, and 20 pt above in landscape and on iPad. On iPhones up to 6.3 inches the system's
    /// bottom row ends lower than the view does, so the bottom row sits on the view's bottom edge instead.
    private static func measuredKeyArea(for deviceContext: DeviceContext,
                                        traitCollection: UITraitCollection) -> KeyAreaMetrics? {
        let isLandscape = deviceContext.isLandscape

        if deviceContext.shouldUseIPadLayout(traitCollection: traitCollection) {
            if deviceContext.isLargeIPad {
                return isLandscape
                    ? KeyAreaMetrics(keyHeight: 79, numberRowKeyHeight: 59, rowGap: 9, topInset: 6, bottomInset: 4,
                                     sideInset: 1)
                    : KeyAreaMetrics(keyHeight: 61, numberRowKeyHeight: 45.5, rowGap: 7, topInset: 8, bottomInset: 4,
                                     sideInset: 0.5)
            } else if deviceContext.isMiniIPad {
                return isLandscape
                    ? KeyAreaMetrics(keyHeight: 75, rowGap: 11, topInset: 11, bottomInset: 10)
                    : KeyAreaMetrics(keyHeight: 55.5, rowGap: 9, topInset: 8, bottomInset: 8, sideInset: 1)
            } else {
                return isLandscape
                    ? KeyAreaMetrics(keyHeight: 72, rowGap: 12, topInset: 11, bottomInset: 11)
                    : KeyAreaMetrics(keyHeight: 55, rowGap: 9, topInset: 8, bottomInset: 8, sideInset: 4)
            }
        }

        // Only iPhone Duo's inner display has been measured. Its outer display keeps the fitted sizes, which give
        // the same key height as the system keyboard's there.
        if deviceContext.device.realDevice == .iPhoneDuo {
            guard isDuoInnerDisplay(deviceContext) else {
                return nil
            }
            return isLandscape
                ? KeyAreaMetrics(keyHeight: 39, rowGap: 13, topInset: 6, bottomInset: 4)
                : KeyAreaMetrics(keyHeight: 46, rowGap: 14, topInset: 8, bottomInset: 3, sideInset: 8)
        }

        guard deviceContext.hasSystemBarBelowKeyboard else {
            return nil
        }
        if isLandscape {
            return KeyAreaMetrics(keyHeight: 32, rowGap: 8, topInset: 6, bottomInset: 2, sideInset: 1)
        }
        return deviceContext.screenInches >= 6.5
            ? KeyAreaMetrics(keyHeight: 45, rowGap: 11, topInset: 8, bottomInset: 7, sideInset: 3.5)
            : KeyAreaMetrics(keyHeight: 43, rowGap: 11, topInset: 8, bottomInset: 0, sideInset: 3.5)
    }

    /// The key area of the height table, shared equally between the rows, with the key margin on either side of
    /// every row. Key heights may be fractional here; the row layout rounds them to whole pixels.
    private static func fittedKeyArea(for deviceContext: DeviceContext, traitCollection: UITraitCollection,
                                      legacy: Bool) -> KeyAreaMetrics {
        let heights = heights(for: deviceContext, traitCollection: traitCollection)
        let tableHeight = deviceContext.isLandscape ? heights.landscape : heights.portrait
        let height = tableHeight - bannerHeight(for: deviceContext, traitCollection: traitCollection)
        let margin = keyMargin(for: deviceContext, traitCollection: traitCollection, legacy: legacy)
        let rows = CGFloat(normalRowCount(for: deviceContext))
        return KeyAreaMetrics(keyHeight: (height - 2 * margin * rows) / rows,
                              rowGap: 2 * margin, topInset: margin, bottomInset: margin)
    }

    /// Space above and below each row's keys in the fitted key area.
    private static func keyMargin(for deviceContext: DeviceContext, traitCollection: UITraitCollection,
                                  legacy: Bool) -> CGFloat {
        if deviceContext.shouldUseIPadLayout(traitCollection: traitCollection) {
            if deviceContext.isLargeLandscape { return 4.0 }
            if deviceContext.isSmallOrMediumLandscape { return 6.0 }
            if deviceContext.isLargeIPad { return 3.5 }
            return 5.0
        }
        if deviceContext.isLandscape { return 3.5 }
        return legacy ? 6.0 : 5.5
    }

    /// Tallest the keyboard gets for layouts with more rows than usual: the height of the table, banner included,
    /// scaled by the number of rows. On small and medium iPads in landscape it is 40 pt less, as these layouts would
    /// otherwise cover most of the screen.
    private static func maximumHeight(for deviceContext: DeviceContext, traitCollection: UITraitCollection,
                                      rowCount: Int) -> CGFloat {
        let heights = heights(for: deviceContext, traitCollection: traitCollection)
        let tableHeight = deviceContext.isLandscape ? heights.landscape : heights.portrait
        var height = tableHeight / CGFloat(normalRowCount(for: deviceContext)) * CGFloat(rowCount)
        if !deviceContext.isLargeIPad, rowCount > 4, deviceContext.isLandscape {
            height -= 40
        }
        return height
    }

    private static func heights(for deviceContext: DeviceContext, traitCollection: UITraitCollection) -> KeyboardHeight {
        // Special case: iPhone app running on iPad in compatibility mode
        if deviceContext.isIPhoneAppRunningOnIPad(traitCollection: traitCollection) {
            let portrait: CGFloat = deviceContext.isLargeIPad ? 328 : 258
            let landscape = portrait - 56
            return (portrait: portrait, landscape: landscape)
        }

        // Check device-specific overrides
        if let override = deviceOverride(for: deviceContext) {
            return override
        }

        // Try diagonal-based lookup
        if let height = height(forDiagonal: deviceContext.device.diagonal) {
            return height
        }

        return fallbackHeight(for: deviceContext)
    }

    /// Shortest screen side, in points, at or above which an iPhone Duo keyboard is on the inner display.
    /// The outer display's short side is 466 pt and the inner display's is 669 pt.
    private static let duoInnerDisplayMinShortSide: CGFloat = 600

    /// Whether an iPhone Duo keyboard is on the unfolded inner display.
    private static func isDuoInnerDisplay(_ deviceContext: DeviceContext) -> Bool {
        let shortSide = min(deviceContext.screenSize.width, deviceContext.screenSize.height)
        return shortSide >= duoInnerDisplayMinShortSide
    }

    /// Device-specific overrides for devices that need different heights than their diagonal peers
    private static func deviceOverride(for deviceContext: DeviceContext) -> KeyboardHeight? {
        switch deviceContext.device {
        case .simulator(let inner):
            return deviceOverride(for: DeviceContext(device: inner,
                                                     isLandscape: deviceContext.isLandscape,
                                                     screenSize: deviceContext.screenSize))
        case .iPhoneXSMax, .iPhone11ProMax:
            return (portrait: 272, landscape: 196)
        case .iPhoneDuo:
            // DeviceKit describes only the 5.4" outer display, which the diagonal table already handles.
            // The unfolded inner display is much larger: match the system keyboard's key area there
            // (253 pt portrait, 219 pt landscape) plus our 48 pt banner.
            return isDuoInnerDisplay(deviceContext) ? (portrait: 301, landscape: 267) : nil
        default:
            return nil
        }
    }

    private static func height(forDiagonal diagonal: Double) -> KeyboardHeight? {
        // Try exact match first
        if let screenSize = ScreenSize(diagonal: diagonal) {
            return heightForScreenSize(screenSize)
        }

        // Try nearest neighbor if close enough
        if let nearest = nearestScreenSize(to: diagonal) {
            return heightForScreenSize(nearest)
        }

        return nil
    }

    /// Sends an unrecognised screen diagonal to Sentry. Replaceable for tests.
    static var reportUnrecognizedScreenSize: (Double) -> Void = { diagonal in
        SentrySDK.capture(message: "Unrecognized device screen size: \(diagonal)\"") { scope in
            scope.setLevel(.warning)
            scope.setContext(value: ["diagonal": diagonal], key: "screen_size")
        }
    }

    /// Diagonals already reported by this keyboard process. Heights are worked out on every layout, so without this
    /// the same event would be sent over and over. Only used on the main thread.
    static var reportedScreenSizes = Set<Double>()

    private static func nearestScreenSize(to diagonal: Double, maxDistance: Double = 0.2) -> ScreenSize? {
        // Notify about unrecognized screen size, once per size
        if reportedScreenSizes.insert(diagonal).inserted {
            reportUnrecognizedScreenSize(diagonal)
        }

        // Find nearest known size by calculating distance for each
        guard let nearest = ScreenSize.allCases.min(by: { size1, size2 in
            let distance1 = abs(size1.rawValue - diagonal)
            let distance2 = abs(size2.rawValue - diagonal)
            return distance1 < distance2
        }) else {
            return nil
        }

        // Only use nearest match if it's close enough
        let distance = abs(nearest.rawValue - diagonal)
        guard distance <= maxDistance else {
            print("⚠️ Unknown screen size: \(diagonal)\" - nearest match \(nearest.rawValue)\" is too far (\(distance)\")")
            return nil
        }

        print("⚠️ Unknown screen size: \(diagonal)\" - using nearest match: \(nearest.rawValue)\"")
        return nearest
    }

    /// Heights for screen sizes that have been tested.
    /// New values should be added here as new devices are released.
    private static func heightForScreenSize(_ screenSize: ScreenSize) -> KeyboardHeight {
        switch screenSize {
        case .size4_7:
            return (portrait: 262, landscape: 208)
        case .size5_4:
            return (portrait: 272, landscape: 198)
        case .size5_5:
            return (portrait: 272, landscape: 208)
        case .size5_8:
            return (portrait: 262, landscape: 196)
        case .size6_1, .size6_3, .size6_5:
            return (portrait: 262, landscape: 206)
        case .size6_7, .size6_9:
            return (portrait: 272, landscape: 206)
        case .size7_9, .size8_3, .size9_7, .size10_2, .size10_5, .size11_0:
            return (portrait: 318, landscape: 404)
        case .size10_9:
            return (portrait: 314, landscape: 398)
        case .size12_9, .size13_0:
            return (portrait: 384, landscape: 476)
        }
    }

    private static func fallbackHeight(for deviceContext: DeviceContext) -> KeyboardHeight {
        // Screen extents of the display the keyboard is on, independent of orientation
        let screenSize = deviceContext.screenSize
        let portraitDeviceHeight = max(screenSize.height, screenSize.width)
        let landscapeDeviceHeight = min(screenSize.height, screenSize.width)

        if deviceContext.isPad {
            let landscape = landscapeDeviceHeight / 2.0 - 70
            return (portrait: 384, landscape: landscape)
        } else if deviceContext.isPhone {
            return (portrait: 262, landscape: 203)
        } else {
            // Should never get here
            // Leaving just in case because this logic existed previously
            let portraitHeight = portraitDeviceHeight / 3.0
            let landscapeHeight = portraitHeight - 56
            return (portrait: portraitHeight, landscape: landscapeHeight)
        }
    }
}

/// Exhaustive list of the device sizes we support and have tested.
/// New device sizes will need to be added here as they become available.
enum ScreenSize: Double, CaseIterable {
    // 3.5- and 4-inch devices are not supported; they are not compatible with iOS 13
    case size4_7 = 4.7
    case size5_4 = 5.4
    case size5_5 = 5.5
    case size5_8 = 5.8
    case size6_1 = 6.1
    case size6_3 = 6.3
    case size6_5 = 6.5
    case size6_7 = 6.7
    case size6_9 = 6.9
    case size7_9 = 7.9
    case size8_3 = 8.3
    case size9_7 = 9.7
    case size10_2 = 10.2
    case size10_5 = 10.5
    case size10_9 = 10.9
    case size11_0 = 11.0
    case size12_9 = 12.9
    case size13_0 = 13.0

    init?(diagonal: Double) {
        self.init(rawValue: diagonal)
    }
}
