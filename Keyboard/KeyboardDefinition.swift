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

struct KeyboardDefinition {
    static let definitions: [KeyboardDefinition] = {
        let rawDefinitions: [[String: Any]] = {
            let path = Bundle.top.url(forResource: "KeyboardDefinitions", withExtension: "json")!
            let data = try! String(contentsOf: path).data(using: .utf8)!
            let obj = try! JSONSerialization.jsonObject(with: data, options: [])
            return obj as! [[String: Any]]
        }()
        
        return rawDefinitions.map({ KeyboardDefinition(raw: $0) })
    }()
    
    let name: String
    let internalName: String
    let spaceName: String
    let enterName: String
    
    let deadKeys: [String: [String]]
    let transforms: [String: TransformTree]
    let longPress: [String: [String]]
    let normal: [[KeyDefinition]]
    let shifted: [[KeyDefinition]]
    
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
        
        var normalrows = (raw["normal"] as! [[Any]]).map { $0.compactMap { return KeyDefinition(input: $0) } }
        normalrows.append(SystemKeys.systemKeyRowsForCurrentDevice(spaceName: spaceName, returnName: enterName))
        normal = normalrows
        
        var shiftedrows = (raw["shifted"] as! [[Any]]).map { $0.compactMap { return KeyDefinition(input: $0) } }
        shiftedrows.append(SystemKeys.systemKeyRowsForCurrentDevice(spaceName: spaceName, returnName: enterName))
        shifted = shiftedrows
    }
}

enum KeyboardPage {
    case normal
    case shifted
    case capslock
    case symbols1
    case symbols2
}
