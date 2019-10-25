import UIKit

public enum KeyType: Hashable {
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
    case sideKeyboardLeft
    case sideKeyboardRight
    case comma
    case fullStop
    case tab
    case caps
    
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


private enum Input {
    case string(String)
    case map([String: Any])
}

extension Input {
    static func from(_ input: Any) -> Input? {
        if let i = input as? String {
            return .string(i)
        } else if let i = input as? [String: Any] {
            return .map(i)
        } else {
            return nil
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
    
    init(string input: String, spaceName: String, returnName: String) {
        type = KeyType(string: input, spaceName: spaceName, returnName: returnName)
        size = CGSize(width: 1, height: 1)
    }
    
    init(string input: String, alternate: String, spaceName: String, returnName: String) {
        if input == alternate {
            type = KeyType(string: input, spaceName: spaceName, returnName: returnName)
        } else {
            type = KeyType(string: input, alternate: alternate, spaceName: spaceName, returnName: returnName)
        }
        
        size = CGSize(width: 1, height: 1)
    }
    
    init(map input: [String: Any], alternate: String? = nil, spaceName: String, returnName: String) {
        if let typeString = input["id"] as? String {
            type = KeyType(string: typeString, alternate: alternate, spaceName: spaceName, returnName: returnName)
        } else {
            type = KeyType(string: "", spaceName: spaceName, returnName: returnName)
        }

        var tempSize = CGSize(width: 1, height: 1)

        if let width = input["width"] as? CGFloat {
            tempSize.width = width
        }

        //            if let height = objectInput["height"] as? CGFloat {
        //                tempSize.height = height
        //            }

        size = tempSize
    }
    
    init(input: Any, spaceName: String, returnName: String) {
        if let input = input as? String {
            self.init(string: input, spaceName: spaceName, returnName: returnName)
        } else if let input = input as? [String: Any] {
            self.init(map: input, spaceName: spaceName, returnName: returnName)
        } else {
            fatalError("Unsupported type passed to KeyDefinition init")
        }
    }
    
    init(input: Any, alternate: Any, spaceName: String, returnName: String) {
        guard let input = Input.from(input) else {
            fatalError("Unsupported type passed to KeyDefinition init as input")
        }
        
        guard let alt = Input.from(alternate) else {
            fatalError("Unsupported type passed to KeyDefinition init as alt")
        }
        
        let alternate: String
        switch alt {
        case let .string(s):
            alternate = s
        case let .map(m):
            alternate = m["id"] as! String
        }
        
        switch input {
        case let .string(s):
            self.init(string: s, alternate: alternate, spaceName: spaceName, returnName: returnName)
        case let .map(m):
            self.init(map: m, alternate: alternate, spaceName: spaceName, returnName: returnName)
        }
    }
}

