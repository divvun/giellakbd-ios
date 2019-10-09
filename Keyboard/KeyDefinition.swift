import UIKit

public enum KeyType: Hashable {
    private static let definitions: [String: KeyType] = [
        "_spacer": .spacer,
        "_backspace": .backspace,
        "_shift": .shift,
        "_spacebar": .spacebar(name: " "),
        "_return": .returnkey(name: "return"),
        "_symbols": .symbols,
        "_keyboard": .keyboard
    ]

    case input(key: String)
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
    case sideKeyboardLeft
    case sideKeyboardRight
    
    var inputValue: String? {
        switch self {
        case .input(let key):
            return key
        default:
            return nil
        }
    }

    init(string: String) {
        if let type = KeyType.definitions[string] {
            self = type
        } else {
            self = .input(key: string)
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
        case .input, .spacebar:
            return false
        default:
            return true
        }
    }
}

public struct KeyDefinition {
    public let type: KeyType
    public let size: CGSize
    
    

    init(type: KeyType, size: CGSize = CGSize(width: 1, height: 1)) {
        self.type = type
        self.size = size
    }

    init?(input: Any) {
        if let stringInput = input as? String {
            type = KeyType(string: stringInput)
            size = CGSize(width: 1, height: 1)
        } else if let objectInput = input as? [String: Any] {
            guard let typeString = objectInput["id"] as? String else {
                return nil
            }
            type = KeyType(string: typeString)

            var tempSize = CGSize(width: 1, height: 1)

            if let width = objectInput["width"] as? CGFloat {
                tempSize.width = width
            }

            //            if let height = objectInput["height"] as? CGFloat {
            //                tempSize.height = height
            //            }

            size = tempSize
        } else {
            return nil
        }
    }
}
