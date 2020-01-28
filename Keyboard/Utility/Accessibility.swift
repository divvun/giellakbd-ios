import Foundation

class Accessibility {
    public static func addAccessibilityLabel(to keyView: KeyView, page: KeyboardPage, key: KeyDefinition) {
        let label: String

        switch key.type {
        case let .input(keyText, _):
            label = keyText
        case .backspace:
            label = NSLocalizedString("backspace", comment: "")
        case .shift:
            label = NSLocalizedString("shift", comment: "")
        case .symbols:
            switch page {
            case .symbols1, .symbols2:
                label = NSLocalizedString("more, letters", comment: "")
            default:
                label = NSLocalizedString("more, numbers", comment: "")
            }
        case .shiftSymbols:
            label = NSLocalizedString("more, symbols", comment: "")
        default:
            return
        }

        keyView.isAccessibilityElement = true
        keyView.accessibilityLabel = label
    }
}
