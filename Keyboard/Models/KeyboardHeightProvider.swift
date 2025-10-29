import DeviceKit
import UIKit

typealias KeyboardHeight = (portrait: CGFloat, landscape: CGFloat)

private let portraitDeviceHeight: CGFloat = {
    let size = UIScreen.main.bounds.size
    return max(size.height, size.width)
}()

private let landscapeDeviceHeight: CGFloat = {
    let size = UIScreen.main.bounds.size
    return min(size.height, size.width)
}()

struct KeyboardHeightProvider {
    static func height(for device: Device, traitCollection: UITraitCollection, isLandscape: Bool) -> CGFloat {
        let heights = self.height(for: device, traitCollection: traitCollection)
        return isLandscape ? heights.landscape : heights.portrait
    }

        // Special case: iPhone app running on iPad in compatibility mode
        if isIPhoneAppRunningOnIPad(traitCollection: traitCollection) {
            let sizeInches = UIScreen.sizeInches
            let portrait = sizeInches <= 11 ? 258.0 : 328.0
            let landscape = portrait - 56
            return (portrait: portrait, landscape: landscape)
        }

        // Check device-specific overrides
        if let override = override(for: device) {
            return override
        }

        // Try diagonal-based lookup
        if let height = height(forDiagonal: device.diagonal) {
            return height
        }

        return fallbackHeight(for: device)
    }

    /// Returns keyboard height adjusted for custom row counts and device-specific constraints
    static func adjustedHeight(
        for device: Device,
        traitCollection: UITraitCollection,
        isLandscape: Bool,
        rowCount: Int
    ) -> CGFloat {
        let heights = height(for: device, traitCollection: traitCollection)
        let baseHeight = isLandscape ? heights.landscape : heights.portrait
        let diagonal = device.diagonal

        guard diagonal > 0 else {
            // Can't adjust for row count without knowing diagonal
            return baseHeight
        }

        // Adjust for row count
        // Ordinarily a keyboard has 4 rows, iPad 12 inch+ has 5. Some have more. We calculate for that.
        let normalRowCount: CGFloat = diagonal >= 12.0
            ? 5.0
            : 4.0
        var adjustedHeight = baseHeight / normalRowCount * CGFloat(rowCount)

        // Some keyboards are more than 4 rows, and on small iPads they take up
        // almost the whole screen in landscape unless we shave off some pixels
        if diagonal < 11, rowCount > 4, isLandscape {
            adjustedHeight -= 40
        }

        return adjustedHeight
    }

    /// Device-specific overrides for devices that need different heights than their diagonal peers
    private static func override(for device: Device) -> KeyboardHeight? {
        switch device {
        case .simulator(let inner):
            return override(for: inner)
        case .iPhoneXSMax, .iPhone11ProMax:
            return (portrait: 272, landscape: 196)
        default:
            return nil
        }
    }

    private static func height(forDiagonal diagonal: Double) -> KeyboardHeight? {
        guard let screenSize = ScreenSize(diagonal: diagonal) else {
            return nil
        }

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

    private static func fallbackHeight(for device: Device) -> KeyboardHeight {
        if device.isPad {
            let landscape = landscapeDeviceHeight / 2.0 - 70
            return (portrait: 384, landscape: landscape)
        } else if device.isPhone {
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

enum ScreenSize: Double {
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
