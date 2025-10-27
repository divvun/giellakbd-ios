struct KeyboardHeight {
    let portrait: CGFloat
    let landscape: CGFloat
}

struct KeyboardHeightProvider {
    static func height(for diagonal: Double) -> KeyboardHeight {
        guard let screenSize = ScreenSize(diagonal: diagonal) else {
            // Fallback for unknown sizes
            // TODO: remove this when done testing
            fatalError("Unknown screen size")
//            return KeyboardHeight(portrait: 262, landscape: 0)
        }
        
        switch screenSize {
        case .size3_5:
            // TODO: check
            return KeyboardHeight(portrait: 0, landscape: 0)
        case .size4:
            // TODO: check
            return KeyboardHeight(portrait: 254, landscape: 0)
        case .size4_7:
            // TODO: check
            return KeyboardHeight(portrait: 262, landscape: 0)
        case .size5_4:
            // TODO: check
            return KeyboardHeight(portrait: 0, landscape: 0)
        case .size5_5:
            // TODO: check
            return KeyboardHeight(portrait: 272, landscape: 0)
        case .size5_8:
            // TODO: check
            return KeyboardHeight(portrait: 262, landscape: 0)
        case .size6_1:
            // TODO: check
            return KeyboardHeight(portrait: 272, landscape: 0)
        case .size6_3:
            // TODO: check
            return KeyboardHeight(portrait: 272, landscape: 0)
        case .size6_5:
            // TODO: check
            return KeyboardHeight(portrait: 0, landscape: 0)
        case .size6_7:
            // TODO: check
            return KeyboardHeight(portrait: 272, landscape: 0)
        case .size6_9:
            // TODO: check
            return KeyboardHeight(portrait: 272, landscape: 0)
        case .size7_9:
            // TODO: check
            return KeyboardHeight(portrait: 0, landscape: 0)
        case .size8_3:
            // TODO: check
            return KeyboardHeight(portrait: 0, landscape: 0)
        case .size9_7:
            // TODO: check
            return KeyboardHeight(portrait: 0, landscape: 0)
        case .size10_2:
            // TODO: check
            return KeyboardHeight(portrait: 0, landscape: 0)
        case .size10_5:
            // TODO: check
            return KeyboardHeight(portrait: 0, landscape: 0)
        case .size10_9:
            // TODO: check
            return KeyboardHeight(portrait: 0, landscape: 0)
        case .size11_0:
            // TODO: check
            return KeyboardHeight(portrait: 0, landscape: 0)
        case .size12_9:
            // TODO: check
            return KeyboardHeight(portrait: 0, landscape: 0)
        case .size13_0:
            // TODO: check
            return KeyboardHeight(portrait: 0, landscape: 0)
        }
    }
}

enum ScreenSize: Double, CaseIterable {
    case size3_5 = 3.5
    case size4 = 4
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
