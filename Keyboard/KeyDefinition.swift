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

public struct KeyDefinition {
    public let type: KeyType
    public let size: CGSize
    
    init(type: KeyType, size: CGSize = CGSize(width: 1, height: 1)) {
        self.type = type
        self.size = size
    }
    
    init(input: RawKeyDefinition, alternate: String? = nil, spaceName: String, returnName: String) {
        type = KeyType(string: input.id, alternate: alternate, spaceName: spaceName, returnName: returnName)
        size = CGSize(width: input.width, height: input.height)
    }
}

extension Array where Element == [KeyDefinition] {
    mutating func platformize(page: KeyboardPage, spaceName: String, returnName: String) {
        append(SystemKeys.systemKeyRowsForCurrentDevice(spaceName: spaceName, returnName: returnName))
    }

    func splitAndBalanceSpacebar() -> [[KeyDefinition]] {
        var copy = self
        for (i, row) in copy.enumerated() {
            var splitPoint = row.count / 2
            var length: CGFloat = 0.0
            for (keyIndex, key) in row.enumerated() {
                length += key.size.width
                if case .spacebar = key.type {
                    let splitSpace = KeyDefinition(type: key.type, size: CGSize(width: key.size.width / 2.0, height: key.size.height))
                    copy[i].remove(at: keyIndex)

                    copy[i].insert(splitSpace, at: keyIndex)
                    copy[i].insert(splitSpace, at: keyIndex)
                    splitPoint = keyIndex + 1
                }
            }

            while splitPoint != (copy[i].count / 2) {
                if splitPoint > copy[i].count / 2 {
                    copy[i].append(KeyDefinition(type: .spacer, size: CGSize(width: 0.0, height: 1.0)))
                } else {
                    copy[i].insert(KeyDefinition(type: .spacer, size: CGSize(width: 0.0, height: 1.0)), at: 0)
                }
            }
        }
        return copy
    }
}
