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
    let space: String
    let enter: String
    
    let longPress: [String: [String]]
    let normal: [[String]]
    let shifted: [[String]]
    
    fileprivate init(raw: [String: Any]) {
        name = raw["name"] as! String
        internalName = raw["internalName"] as! String
        space = raw["space"] as! String
        enter = raw["return"] as! String
        
        longPress = raw["longPress"] as! [String: [String]]
        normal = raw["normal"] as! [[String]]
        shifted = raw["shifted"] as! [[String]]
    }
}
