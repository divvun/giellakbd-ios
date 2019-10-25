import UIKit
import UIDeviceComplete

public indirect enum TransformTree {
    case tree([String: TransformTree])
    case leaf(String)
}

public struct KeyboardDefinition {
    static let definitions: [KeyboardDefinition] = {
        let rawDefinitions: [[String: Any]] = {
            let path = Bundle.top.url(forResource: "KeyboardDefinitions", withExtension: "json")!
            let data = try! String(contentsOf: path).data(using: .utf8)!
            let obj = try! JSONSerialization.jsonObject(with: data, options: [])
            return obj as! [[String: Any]]
        }()

        return rawDefinitions.map { KeyboardDefinition(raw: $0) }
    }()

    public let name: String
    public let locale: String
    public let spaceName: String
    public let returnName: String

    public let deadKeys: [String: [String]]
    public let transforms: [String: TransformTree]
    public let longPress: [String: [String]]
    private(set) public var normal: [[KeyDefinition]] = []
    private(set) public var shifted: [[KeyDefinition]] = []
    private(set) public var symbols1: [[KeyDefinition]] = []
    private(set) public var symbols2: [[KeyDefinition]] = []
    
    public func copy(
        normal: [[KeyDefinition]],
        shifted: [[KeyDefinition]],
        symbols1: [[KeyDefinition]],
        symbols2: [[KeyDefinition]]
    ) -> KeyboardDefinition {
        return KeyboardDefinition(
            other: self, normal: normal, shifted: shifted, symbols1: symbols1, symbols2: symbols2)
    }

    private init(
        other: KeyboardDefinition,
        normal: [[KeyDefinition]],
        shifted: [[KeyDefinition]],
        symbols1: [[KeyDefinition]],
        symbols2: [[KeyDefinition]]
    ) {
        self.name = other.name
        self.locale = other.locale
        self.spaceName = other.spaceName
        self.returnName = other.returnName
        
        self.deadKeys = other.deadKeys
        self.transforms = other.transforms
        self.longPress = other.longPress
        
        self.normal = normal
        self.shifted = shifted
        self.symbols1 = symbols1
        self.symbols2 = symbols2
    }
    
    private static func recurseTransforms(_ current: [String: Any]) -> [String: TransformTree] {
        var transforms = [String: TransformTree]()

        current.forEach { key, value in
            if let value = value as? String {
                transforms[key] = TransformTree.leaf(value)
            } else if let value = value as? [String: Any] {
                let tree = recurseTransforms(value)
                transforms[key] = TransformTree.tree(tree)
            }
        }

        return transforms
    }

    private init(raw: [String: Any]) {
        name = raw["name"] as! String
        locale = raw["locale"] as! String
        spaceName = raw["space"] as! String
        returnName = raw["return"] as! String

        longPress = raw["longPress"] as! [String: [String]]

        deadKeys = raw["deadKeys"] as? [String: [String]] ?? [:]
        if let rawTransforms = raw["transforms"] as? [String: Any] {
            transforms = KeyboardDefinition.recurseTransforms(rawTransforms)
        } else {
            transforms = [:]
        }

        let modes: [String: [[Any]]?]
        let family = UIDevice.current.dc.deviceFamily
        print("\(family)")
        if family == .iPad {
            if (UIDevice.current.dc.screenSize.sizeInches ?? 0.0) < 12.0 {
                modes = raw["ipad-9in"] as! [String: [[Any]]?]
                
                // On iPad Pro 9 inch, we want to have swipe keys so we merge all of our layers
                let normal = modes["normal"]!!
                let shifted = modes["shifted"]!!
                let alt = modes["alt"]!!
                let altShift = modes["alt+shift"]!!
                let symbols1 = modes["symbols-1"]!!
                let symbols2 = modes["symbols-2"]!!
                
                self.normal = zip(normal, alt)
                    .map { zip($0, $1).map { KeyDefinition(input: $0, alternate: $1, spaceName: spaceName, returnName: returnName) }}
                self.shifted = zip(shifted, altShift)
                    .map { zip($0, $1).map { KeyDefinition(input: $0, alternate: $1, spaceName: spaceName, returnName: returnName) }}
                self.symbols1 = zip(symbols1, symbols2).map {
                    zip($0, $1).map {
                        return KeyDefinition(input: $0, alternate: $1, spaceName: spaceName, returnName: returnName)
                    }
                }
                self.symbols2 = symbols2.map { $0.map { KeyDefinition(input: $0, spaceName: spaceName, returnName: returnName) } }
                
            } else {
                // On iPad Pro 12 inch, we want to have swipe keys only on the top row
                modes = raw["ipad-12in"] as! [String: [[Any]]?]
                let normal = modes["normal"]!!
                let shifted = modes["shifted"]!!
                let symbols1 = modes["symbols-1"]!!
//                let symbols2 = modes["symbols-2"]!!
                
                var normal1: [[KeyDefinition]] = [zip(normal[0], symbols1[0]).map {
                    KeyDefinition(input: $0, alternate: $1, spaceName: spaceName, returnName: returnName)
                }]
                normal.suffix(from: 1)
                    .forEach { normal1.append($0.compactMap { KeyDefinition(input: $0, spaceName: spaceName, returnName: returnName) }) }
                self.normal = normal1
                
                var shifted1: [[KeyDefinition]] = [zip(shifted[0], symbols1[0]).map {
                    KeyDefinition(input: $0, alternate: $1, spaceName: spaceName, returnName: returnName)
                }]
                shifted.suffix(from: 1)
                    .forEach { shifted1.append($0.compactMap { KeyDefinition(input: $0, spaceName: spaceName, returnName: returnName) }) }
                self.shifted = shifted1
                
                self.symbols1 = symbols1.map { $0.map { KeyDefinition(input: $0, spaceName: spaceName, returnName: returnName) } }
            }
        } else {
            modes = raw["iphone"] as! [String: [[Any]]?]
            
            normal = (modes["normal"]!!).map { $0.map { KeyDefinition(input: $0, spaceName: spaceName, returnName: returnName) } }
            shifted = (modes["shifted"]!!).map { $0.map { KeyDefinition(input: $0, spaceName: spaceName, returnName: returnName) } }
            
            symbols1 = modes["symbols-1"]!!.map { $0.map { KeyDefinition(input: $0, spaceName: spaceName, returnName: returnName) }}
            symbols2 = modes["symbols-2"]!!.map { $0.map { KeyDefinition(input: $0, spaceName: spaceName, returnName: returnName) }}

//            symbols1 = SystemKeys.symbolKeysFirstPage
//            // Naively pad out the symbols. Should rather be a larger list and trimmed in the future
//            for (rowIndex, _) in symbols1.enumerated() {
//                while symbols1[rowIndex].count < normal[rowIndex].count {
//                    symbols1[rowIndex].append(KeyDefinition(type: KeyType.spacer, size: CGSize(width: 0.0, height: 1.0)))
//                }
//            }
//
//            symbols2 = SystemKeys.symbolKeysSecondPage
//            for (rowIndex, _) in symbols2.enumerated() {
//                while symbols2[rowIndex].count < normal[rowIndex].count {
//                    symbols2[rowIndex].append(KeyDefinition(type: KeyType.spacer, size: CGSize(width: 0.0, height: 1.0)))
//                }
//            }
        }

        normal.platformize(page: .normal, spaceName: spaceName, returnName: returnName)
        shifted.platformize(page: .shifted, spaceName: spaceName, returnName: returnName)
        symbols1.platformize(page: .symbols1, spaceName: spaceName, returnName: returnName)
        symbols2.platformize(page: .symbols2, spaceName: spaceName, returnName: returnName)
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

public enum KeyboardPage {
    case normal
    case shifted
    case capslock
    case symbols1
    case symbols2

    func alternatePage() -> KeyboardPage {
        switch self {
        case .normal, .shifted, .capslock:
            return .symbols1
        default:
            return .symbols2
        }
    }
}
