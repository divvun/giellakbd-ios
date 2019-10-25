import Foundation
import UIKit

class SystemKeys {
    static func systemKeyRowsForCurrentDevice(spaceName: String, returnName: String) -> [KeyDefinition] {
        var keys = [KeyDefinition]()
        
        // Left side of space bar
        if !UIDevice.current.dc.deviceModel.hasNotch {
            if UIDevice.current.dc.isIpad && (UIDevice.current.dc.screenSize.sizeInches ?? 0.0) > 10.0 {
                keys.append(KeyDefinition(type: .keyboard, size: CGSize(width: 1.25, height: 1.0)))
                keys.append(KeyDefinition(type: .symbols, size: CGSize(width: 1.25, height: 1.0)))
            } else {
                keys.append(KeyDefinition(type: .symbols, size: CGSize(width: 1.25, height: 1.0)))
                keys.append(KeyDefinition(type: .keyboard, size: CGSize(width: 1.25, height: 1.0)))
            }
        } else if UIDevice.current.dc.deviceFamily != .iPad {
            keys.append(KeyDefinition(type: .symbols, size: CGSize(width: 2.5, height: 1.0)))
        } else {
            keys.append(KeyDefinition(type: .symbols))
        }
        keys.append(KeyDefinition(type: .spacebar(name: spaceName), size: CGSize(width: 5.0, height: 1.0)))
        
        // Right of spacebar
        if UIDevice.current.dc.deviceFamily == .iPad {
            keys.append(KeyDefinition(type: .symbols, size: CGSize(width: 1.25, height: 1.0)))
            keys.append(KeyDefinition(type: .keyboardMode, size: CGSize(width: 1.25, height: 1.0)))
        } else {
            keys.append(KeyDefinition(type: .returnkey(name: returnName), size: CGSize(width: 2.5, height: 1.0)))
        }

        return keys
    }
    
//    private static func phoneSymbolKeysFirstPage(currencySign: String) -> [[KeyDefinition]] {
//        return [
//            [
//                "1",
//                "2",
//                "3",
//                "4",
//                "5",
//                "6",
//                "7",
//                "8",
//                "9",
//                "0"
//                ].compactMap { KeyDefinition(input: $0) },
//
//            [
//                "-",
//                "/",
//                ":",
//                ";",
//                "(",
//                ")",
//                currencySign,
//                "&",
//                "@",
//                "\""
//                ].compactMap { KeyDefinition(input: $0) },
//
//            ([
//                KeyDefinition(type: .spacer, size: CGSize(width: 0.1, height: 1.0))
//                ]
//                +
//                [
//                    ".",
//                    ",",
//                    "?",
//                    "!",
//                    "'"
//                    ].compactMap { KeyDefinition(input: $0) }
//                +
//                [
//                    KeyDefinition(type: .spacer, size: CGSize(width: 0.1, height: 1.0))
//                ])
//        ]
//    }
//
//    private static func phoneSymbolKeysSecondPage(currencySign: String) -> [[KeyDefinition]] {
//        return [
//            [
//                "[",
//                "]",
//                "{",
//                "}",
//                "#",
//                "%",
//                "^",
//                "*",
//                "+",
//                "="
//                ].compactMap { KeyDefinition(input: $0) },
//
//            [
//                "_",
//                "\\",
//                "|",
//                "~",
//                "<",
//                ">",
//                "$",
//                "€",
//                "¥",
//                "•"
//                ].compactMap { KeyDefinition(input: $0) },
//
//            ([
//                KeyDefinition(type: .spacer, size: CGSize(width: 0.1, height: 1.0))
//                ]
//                +
//                [
//                    ".",
//                    ",",
//                    "?",
//                    "!",
//                    "'"
//                    ].compactMap { KeyDefinition(input: $0) }
//                +
//                [
//                    KeyDefinition(type: .spacer, size: CGSize(width: 0.1, height: 1.0))
//                ])
//        ]
//    }
//
//    static var symbolKeysFirstPage: [[KeyDefinition]] {
//        let currencySign = "kr"
//
//        if UIDevice.current.dc.deviceFamily == .iPad {
//            return phoneSymbolKeysFirstPage(currencySign: currencySign)
//        } else {
//            return phoneSymbolKeysFirstPage(currencySign: currencySign)
//        }
//    }
//
//    static var symbolKeysSecondPage: [[KeyDefinition]] {
//        let currencySign = "kr"
//
//        if UIDevice.current.dc.deviceFamily == .iPad {
//            return phoneSymbolKeysSecondPage(currencySign: currencySign)
//        } else {
//            return phoneSymbolKeysSecondPage(currencySign: currencySign)
//        }
//    }
}
