import Foundation

class Accessibility {
    public static func addAccessibilityLabel(to keyView: KeyView, page: KeyboardPage, key: KeyDefinition) {
        let label: String

        switch key.type {
        case let .input(keyText, _):
            label = keyText
        case .backspace:
            label = NSLocalizedString("accessibility.backspace", comment: "")
        case .shift:
            label = NSLocalizedString("accessibility.shift", comment: "")
        case .symbols:
            switch page {
            case .symbols1, .symbols2:
                label = NSLocalizedString("accessibility.moreLetters", comment: "")
            default:
                label = NSLocalizedString("accessibility.moreNumbers", comment: "")
            }
        case .shiftSymbols:
            label = NSLocalizedString("accessibility.moreSymbols", comment: "")
        default:
            return
        }

        keyView.isAccessibilityElement = true
        keyView.accessibilityLabel = label
    }
}
