import DeviceKit
import UIKit

typealias KeyboardHeight = (portrait: CGFloat, landscape: CGFloat)

struct KeyboardHeightProvider {
    static func height(for device: Device, traitCollection: UITraitCollection) -> KeyboardHeight {
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

        // Fall back to diagonal-based lookup
        return height(forDiagonal: device.diagonal)
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

    private static func height(forDiagonal diagonal: Double) -> KeyboardHeight {
        guard let screenSize = ScreenSize(diagonal: diagonal) else {
            // Fallback for unknown sizes
            return (portrait: 262, landscape: 203)
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
