import Foundation

enum DeadKeyState {
    case none
    case transforming
    case output(String)
}

struct DeadKeyHandler {
    private var current: [String: TransformTree]?
    private let keyboard: KeyboardDefinition

    init(keyboard: KeyboardDefinition) {
        self.keyboard = keyboard
    }

    mutating func finish() -> String? {
        if case let .output(value) = handleInput(" ", page: .normal) {
            return value
        }
        return nil
    }

    mutating func handleInput(_ input: String, page: KeyboardPage) -> DeadKeyState {
        if let deadKeyRef = deadKey(input, page: page) {
            current = deadKeyRef
            return .transforming
        }

        if current != nil {
            let t = transform(input)

            switch t {
            case let .leaf(value):
                current = nil
                return .output(value)
            case let .tree(ref):
                current = ref
                return .transforming
            }
        }

        return .none
    }

    private mutating func deadKey(_ input: String, page: KeyboardPage) -> [String: TransformTree]? {
        let key: String
        switch page {
        case .normal:
            key = "default"
        case .shifted:
            key = "shift"
        case .symbols1:
            key = "symbols-1"
        case .symbols2:
            key = "symbols-2"
        case .capslock:
            key = "caps"
        }

        guard let deadKeys = keyboard.deadKeys[key] else {
            return nil
        }

        if deadKeys.contains(input) {
            current = keyboard.transforms

            switch transform(input) {
            case let .tree(ref):
                return ref
            default:
                return nil
            }
        } else {
            return nil
        }
    }

    func transform(_ input: String) -> TransformTree {
        guard let current = current else {
            // Fallback, this is an invalid case that should never happen.
            return .leaf(input)
        }

        if let result = current[input] {
            return result
        } else {
            if case let .some(.leaf(v)) = current[" "] {
                return .leaf("\(v)\(input)")
            }

            return .leaf(input)
        }
    }
}
