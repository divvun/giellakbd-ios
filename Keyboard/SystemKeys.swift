import Foundation
import UIKit

class SystemKeys {
    static func systemKeyRowsForCurrentDevice(spaceName: String, returnName: String) -> [KeyDefinition] {
        var keys = [KeyDefinition]()
        
        // Left side of space bar
        if !UIDevice.current.isXFamily {
            keys.append(KeyDefinition(type: .symbols))
            keys.append(KeyDefinition(type: .keyboard))
        } else if UIDevice.current.kind != .iPad {
            keys.append(KeyDefinition(type: .symbols, size: CGSize(width: 2.0, height: 1.0)))
        } else {
            keys.append(KeyDefinition(type: .symbols))
        }
        keys.append(KeyDefinition(type: .spacebar(name: spaceName), size: CGSize(width: 5.0, height: 1.0)))
        
        // Right of spacebar
        if UIDevice.current.kind == .iPad {
            keys.append(KeyDefinition(type: .symbols))
            keys.append(KeyDefinition(type: .keyboardMode))
        } else {
            keys.append(KeyDefinition(type: .returnkey(name: returnName), size: CGSize(width: 2.0, height: 1.0)))
        }

        return keys
    }

    static var symbolKeysFirstPage: [[KeyDefinition]] {
        let currencySign = "kr"
        return [
            [
                "1",
                "2",
                "3",
                "4",
                "5",
                "6",
                "7",
                "8",
                "9",
                "0"
                ].compactMap { KeyDefinition(input: $0) },

            [
                "-",
                "/",
                ":",
                ";",
                "(",
                ")",
                currencySign,
                "&",
                "@",
                "\""
                ].compactMap { KeyDefinition(input: $0) },

            ([
                KeyDefinition(type: .spacer, size: CGSize(width: 0.1, height: 1.0))
                ]
                +
                [
                    ".",
                    ",",
                    "?",
                    "!",
                    "'"
                    ].compactMap { KeyDefinition(input: $0) }
                +
                [
                    KeyDefinition(type: .spacer, size: CGSize(width: 0.1, height: 1.0))
                ])
        ]
    }

    static var symbolKeysSecondPage: [[KeyDefinition]] {
        return [
            [
                "[",
                "]",
                "{",
                "}",
                "#",
                "%",
                "^",
                "*",
                "+",
                "="
                ].compactMap { KeyDefinition(input: $0) },

            [
                "_",
                "\\",
                "|",
                "~",
                "<",
                "?",
                "€",
                "$",
                "£",
                "•"
                ].compactMap { KeyDefinition(input: $0) },

            ([
                KeyDefinition(type: .spacer, size: CGSize(width: 0.1, height: 1.0))
                ]
                +
                [
                    ".",
                    ",",
                    "?",
                    "!",
                    "'"
                    ].compactMap { KeyDefinition(input: $0) }
                +
                [
                    KeyDefinition(type: .spacer, size: CGSize(width: 0.1, height: 1.0))
                ])
        ]
    }
}
