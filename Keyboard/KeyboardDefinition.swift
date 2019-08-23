//
//  KeyboardDefinition.swift
//  GiellaKeyboard
//
//  Created by Brendan Molloy on 26/4/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

extension Bundle {
    static var top: Bundle {
        if Bundle.main.bundleURL.pathExtension == "appex" {
            let url = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
            if let other = Bundle(url: url) {
                return other
            }
        }
        
        return Bundle.main
    }
}

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
        
        return rawDefinitions.map({ KeyboardDefinition(raw: $0) })
    }()
    
    public let name: String
    public let internalName: String
    public let spaceName: String
    public let enterName: String
    
    public let deadKeys: [String: [String]]
    public let transforms: [String: TransformTree]
    public let longPress: [String: [String]]
    public var normal: [[KeyDefinition]]
    public var shifted: [[KeyDefinition]]
    public var symbols1: [[KeyDefinition]]
    public var symbols2: [[KeyDefinition]]
    
    private static func recurseTransforms(_ current: [String: Any]) -> [String: TransformTree] {
        var transforms = [String: TransformTree]()
        
        current.forEach({ (key, value) in
            if let value = value as? String {
                transforms[key] = TransformTree.leaf(value)
            } else if let value = value as? [String: Any] {
                let tree = recurseTransforms(value)
                transforms[key] = TransformTree.tree(tree)
            }
        })
        
        return transforms
    }
    
    fileprivate init(raw: [String: Any]) {
        name = raw["name"] as! String
        internalName = raw["internalName"] as! String
        spaceName = raw["space"] as! String
        enterName = raw["return"] as! String
        
        longPress = raw["longPress"] as! [String: [String]]
        
        deadKeys = raw["deadKeys"] as? [String: [String]] ?? [:]
        if let rawTransforms = raw["transforms"] as? [String: Any] {
            self.transforms = KeyboardDefinition.recurseTransforms(rawTransforms)
        } else {
            self.transforms = [:]
        }
        
        let normalrows = (raw["normal"] as! [[Any]]).map { $0.compactMap { return KeyDefinition(input: $0) } }
        normal = normalrows
        
        let shiftedrows = (raw["shifted"] as! [[Any]]).map { $0.compactMap { return KeyDefinition(input: $0) } }
        shifted = shiftedrows
        
        symbols1 = SystemKeys.symbolKeysFirstPage
        symbols2 = SystemKeys.symbolKeysSecondPage
        
        normal.platformize(page: .normal, spaceName: spaceName, returnName: enterName)
        shifted.platformize(page: .shifted, spaceName: spaceName, returnName: enterName)
        symbols1.platformize(page: .symbols1, spaceName: spaceName, returnName: enterName)
        symbols2.platformize(page: .symbols2, spaceName: spaceName, returnName: enterName)
    }
    
    

}

extension Array where Element == Array<KeyDefinition> {
    mutating func platformize(page: KeyboardPage, spaceName: String, returnName: String) {
        var shiftType: KeyType = .shift
        
        if case page = KeyboardPage.symbols1 {
            shiftType = .shiftSymbols
        }
        if case page = KeyboardPage.symbols2 {
            shiftType = .shiftSymbols
        }

        if UIDevice.current.kind == UIDevice.Kind.iPad {
            
            self[2].insert(KeyDefinition.init(type: shiftType), at: 0)
            self[2].append(KeyDefinition.init(type: shiftType, size: CGSize(width: 1.5, height: 1.0)))
            
            self[0].append(KeyDefinition.init(type: .backspace))
            self[1].append(KeyDefinition.init(type: KeyType.returnkey(name: returnName), size: CGSize(width: 2.0, height: 1.0)))
            
        } else {
            self[2].insert(KeyDefinition.init(type: shiftType, size: CGSize(width: 1.5, height: 1.0)), at: 0)
            self[2].insert(KeyDefinition.init(type: .spacer, size: CGSize(width: 0.5, height: 1.0)), at: 1)

            self[2].append(KeyDefinition.init(type: .spacer, size: CGSize(width: 0.5, height: 1.0)))
            self[2].append(KeyDefinition.init(type: .backspace, size: CGSize(width: 1.5, height: 1.0)))
            
        }
        self.append(SystemKeys.systemKeyRowsForCurrentDevice(spaceName: spaceName, returnName: returnName))
    }
}

enum KeyboardPage {
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
