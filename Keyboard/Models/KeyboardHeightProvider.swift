struct KeyboardHeight {
    let portrait: CGFloat
    let landscape: CGFloat
}

struct KeyboardHeightProvider {
    static func height(for diagonal: Double) -> KeyboardHeight {
        guard let screenSize = ScreenSize(diagonal: diagonal) else {
            // Fallback for unknown sizes
            return KeyboardHeight(portrait: 262, landscape: 203)
        }

        print("CURRENT screen size: \(screenSize)")

        switch screenSize {
        case .size4_7:
            return KeyboardHeight(portrait: 262, landscape: 208)
        case .size5_4:
            return KeyboardHeight(portrait: 272, landscape: 198)
        case .size5_5:
            return KeyboardHeight(portrait: 272, landscape: 208)
        case .size5_8:
            return KeyboardHeight(portrait: 262, landscape: 196)
        case .size6_1:
            return KeyboardHeight(portrait: 262, landscape: 206)
        case .size6_3:
            return KeyboardHeight(portrait: 262, landscape: 206)
        case .size6_5:
            // This is correct for iPhone Air, but slightly too short in portrait and too tall in landscape on iPhone 11 Pro Max and presumably iPhone XS Max, whose values are (272, 190).
            return KeyboardHeight(portrait: 262, landscape: 206)
        case .size6_7:
            return KeyboardHeight(portrait: 272, landscape: 206)
        case .size6_9:
            return KeyboardHeight(portrait: 272, landscape: 206)
        case .size7_9:
            // TODO: check
            // iPad Mini 2/3/4/5
            return KeyboardHeight(portrait: 314, landscape: 400)
        case .size8_3:
            // TODO: check
            // iPad Mini 6
            return KeyboardHeight(portrait: 314, landscape: 400)
        case .size9_7:
            // TODO: check
            // iPad 3/4/5/6, iPad Air/Air 2, iPad Pro 9.7"
            return KeyboardHeight(portrait: 314, landscape: 353)
        case .size10_2:
            // TODO: check
            // iPad 7/8/9
            return KeyboardHeight(portrait: 314, landscape: 353)
        case .size10_5:
            // TODO: check
            // iPad Air 3, iPad Pro 10.5"
            return KeyboardHeight(portrait: 314, landscape: 405)
        case .size10_9:
            // TODO: check
            // iPad 10, iPad Air 4/5
            return KeyboardHeight(portrait: 314, landscape: 405)
        case .size11_0:
            // TODO: check
            // iPad Pro 11" (all generations)
            return KeyboardHeight(portrait: 314, landscape: 405)
        case .size12_9:
            // TODO: check
            // iPad Pro 12.9" (all generations)
            return KeyboardHeight(portrait: 384, landscape: 426)
        case .size13_0:
            // TODO: check
            // iPad Pro 13" (M4)
            return KeyboardHeight(portrait: 384, landscape: 426)
        }
    }
}

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
