import UIKit
import Sentry

typealias KeyboardHeight = (portrait: CGFloat, landscape: CGFloat)

struct KeyboardHeightProvider {
    private static let portraitDeviceHeight: CGFloat = {
        let size = UIScreen.main.bounds.size
        return max(size.height, size.width)
    }()

    private static let landscapeDeviceHeight: CGFloat = {
        let size = UIScreen.main.bounds.size
        return min(size.height, size.width)
    }()

    /// Returns keyboard height for a given device and orientation, optionally adjusted for custom row counts
    static func height(
        for deviceContext: DeviceContext,
        traitCollection: UITraitCollection,
        rowCount: Int? = nil
    ) -> CGFloat {
        let heights = heights(for: deviceContext, traitCollection: traitCollection)
        let isLandscape = deviceContext.isLandscape
        let baseHeight = isLandscape ? heights.landscape : heights.portrait

        guard let rowCount = rowCount else {
            return baseHeight
        }

        // Adjust for custom row count
        // Ordinarily a keyboard has 4 rows, iPad 12 inch+ has 5. Some have more. We calculate for that.
        let normalRowCount: CGFloat = deviceContext.isLargeIPad ? 5.0 : 4.0
        let rowHeight = baseHeight / normalRowCount
        var adjustedHeight = rowHeight * CGFloat(rowCount)

        // Some keyboards are more than 4 rows, and on small iPads they take up
        // almost the whole screen in landscape unless we shave off some pixels
        if !deviceContext.isLargeIPad, rowCount > 4, isLandscape {
            adjustedHeight -= 40
        }

        return adjustedHeight
    }

    private static func heights(for deviceContext: DeviceContext, traitCollection: UITraitCollection) -> KeyboardHeight {
        // Special case: iPhone app running on iPad in compatibility mode
        if isIPhoneAppRunningOnIPad(traitCollection: traitCollection) {
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

    /// Device-specific overrides for devices that need different heights than their diagonal peers
    private static func deviceOverride(for deviceContext: DeviceContext) -> KeyboardHeight? {
        switch deviceContext.device {
        case .simulator(let inner):
            return deviceOverride(for: DeviceContext(device: inner, isLandscape: deviceContext.isLandscape))
        case .iPhoneXSMax, .iPhone11ProMax:
            return (portrait: 272, landscape: 196)
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

    private static func nearestScreenSize(to diagonal: Double, maxDistance: Double = 0.2) -> ScreenSize? {
        // Notify about unrecognized screen size
        SentrySDK.capture(message: "Unrecognized device screen size: \(diagonal)\"") { scope in
            scope.setLevel(.warning)
            scope.setContext(value: ["diagonal": diagonal], key: "screen_size")
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
