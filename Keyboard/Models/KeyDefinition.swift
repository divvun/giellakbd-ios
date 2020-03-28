import UIKit

struct RawKeyType: Codable {
    let id: String
    let name: String?
    let alternate: String?
}

public enum KeyType: Codable, Hashable {
    case input(key: String, alternate: String?)
    case spacer
    case shift
    case backspace
    case spacebar(name: String)
    case returnkey(name: String)
    case symbols
    case shiftSymbols
    case keyboard
    case keyboardMode
    case splitKeyboard
    case normalKeyboard
    case sideKeyboardLeft
    case sideKeyboardRight
    case comma
    case fullStop
    case tab
    case caps

    public init(from decoder: Decoder) throws {
        let decoder = try decoder.singleValueContainer()
        let raw = try decoder.decode(RawKeyType.self)
        self = Self.init(string: raw.id, alternate: raw.alternate, spaceName: raw.name ?? "", returnName: raw.name ?? "")
    }

    public func encode(to encoder: Encoder) throws {
        var encoder = encoder.singleValueContainer()
        let raw: RawKeyType

        switch self {
        case .input(let key, let alternate):
            raw = RawKeyType(id: key, name: nil, alternate: alternate)
        case .spacer:
            raw = RawKeyType(id: "_spacer", name: nil, alternate: nil)
        case .shift:
            raw = RawKeyType(id: "_shift", name: nil, alternate: nil)
        case .backspace:
            raw = RawKeyType(id: "_backspace", name: nil, alternate: nil)
        case .spacebar(let name):
            raw = RawKeyType(id: "_spacebar", name: name, alternate: nil)
        case .returnkey(let name):
            raw = RawKeyType(id: "_return", name: name, alternate: nil)
        case .symbols:
            raw = RawKeyType(id: "_symbols", name: nil, alternate: nil)
        case .shiftSymbols:
            raw = RawKeyType(id: "_shiftSymbols", name: nil, alternate: nil)
        case .keyboard:
            raw = RawKeyType(id: "_keyboard", name: nil, alternate: nil)
        case .comma:
            raw = RawKeyType(id: "_comma", name: nil, alternate: nil)
        case .fullStop:
            raw = RawKeyType(id: "_fullstop", name: nil, alternate: nil)
        case .tab:
            raw = RawKeyType(id: "_tab", name: nil, alternate: nil)
        case .caps:
            raw = RawKeyType(id: "_caps", name: nil, alternate: nil)
        case .keyboardMode:
            raw = RawKeyType(id: "_keyboardMode", name: nil, alternate: nil)
        default:
            try encoder.encodeNil()
            return
        }

        try encoder.encode(raw)
    }

    init(string: String, alternate: String? = nil, spaceName: String, returnName: String) {
        switch string {
        case "_spacer":
            self = .spacer
        case "_backspace":
            self = .backspace
        case "_shift":
            self = .shift
        case "_spacebar":
            self = .spacebar(name: spaceName)
        case "_return":
            self = .returnkey(name: returnName)
        case "_symbols":
            self = .symbols
        case "_shiftSymbols":
            self = .shiftSymbols
        case "_keyboard":
            self = .keyboard
        case "_comma":
            self = .comma
        case "_fullstop":
            self = .fullStop
        case "_tab":
            self = .tab
        case "_caps":
            self = .caps
        case "_keyboardMode":
            self = .keyboardMode
        default:
            self = .input(key: string, alternate: alternate)
        }
    }

    var supportsDoubleTap: Bool {
        switch self {
        case .shift:
            return true
        default:
            return false
        }
    }

    var triggersOnTouchDown: Bool {
        switch self {
        case .shift, .backspace, .symbols:
            return true
        default:
            return false
        }
    }

    var triggersOnTouchUp: Bool {
        return !triggersOnTouchDown
    }

    var supportsRepeatTrigger: Bool {
        switch self {
        case .backspace:
            return true
        default:
            return false
        }
    }

    var isSpecialKeyStyle: Bool {
        switch self {
        case .input, .spacebar, .comma, .fullStop:
            return false
        default:
            return true
        }
    }
}

public struct KeyDefinition: Codable {
    public let type: KeyType
    public let size: CGSize

    init(type: KeyType, size: CGSize = CGSize(width: 1, height: 1)) {
        self.type = type
        self.size = size
    }

    init(input: RawKeyDefinition, alternate: String? = nil, spaceName: String, returnName: String) {
        if input.id == alternate {
            type = KeyType(string: input.id, alternate: nil, spaceName: spaceName, returnName: returnName)
        } else {
            type = KeyType(string: input.id, alternate: alternate, spaceName: spaceName, returnName: returnName)
        }
        size = CGSize(width: input.width, height: input.height)
    }

    public func accessibilityLabel(for page: KeyboardPage) -> String? {
        switch self.type {
        case let .input(keyText, _):
            return keyText
        case .spacebar(name: _):
            return NSLocalizedString("accessibility.space", comment: "")
        case .backspace:
            return NSLocalizedString("accessibility.backspace", comment: "")
        case .shift:
            return NSLocalizedString("accessibility.shift", comment: "")
        case .symbols:
            switch page {
            case .symbols1, .symbols2:
                return NSLocalizedString("accessibility.moreLetters", comment: "")
            default:
                return NSLocalizedString("accessibility.moreNumbers", comment: "")
            }
        case .shiftSymbols:
            switch page {
            case .symbols2:
                return NSLocalizedString("accessibility.moreNumbers", comment: "")
            default:
                return NSLocalizedString("accessibility.moreSymbols", comment: "")
            }
        default:
            return nil
        }
    }
}
