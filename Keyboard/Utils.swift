//
//  Utils.swift
//  Keyboard
//
//  Created by Brendan Molloy on 2019-08-08.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation
import UIKit

extension String {
    func suffix(after index: String.Index) -> String.SubSequence {
        if index >= self.endIndex {
            return self.suffix(from: self.endIndex)
        }
        
        return self.suffix(from: self.index(after: index))
    }
}

extension Substring {
    func lastIndex(after character: Character) -> String.Index? {
        guard let index = self.lastIndex(of: character) else { return nil }
        if index == self.endIndex { return nil }
        return self.index(after: index)
    }
}

extension UIColor {
    convenience init(r: Int, g: Int, b: Int, a: Double = 1) {
        self.init(red: CGFloat(r)/CGFloat(255), green: CGFloat(g)/CGFloat(255), blue: CGFloat(b)/CGFloat(255), alpha: CGFloat(a))
    }
}

// From https://stackoverflow.com/a/52821290
public extension UIDevice {
    
    var isXFamily: Bool {
        return [UIDevice.Kind.iPhone_X_Xs, UIDevice.Kind.iPhone_Xr ,UIDevice.Kind.iPhone_Xs_Max].contains(self.kind)
    }
    
    enum Kind {
        case iPad
        case iPhone_unknown
        case iPhone_5_5S_5C
        case iPhone_6_6S_7_8
        case iPhone_6_6S_7_8_PLUS
        case iPhone_X_Xs
        case iPhone_Xs_Max
        case iPhone_Xr
    }
    
    var kind: Kind {
        if userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 1136:
                return .iPhone_5_5S_5C
            case 1334:
                return .iPhone_6_6S_7_8
            case 1920, 2208:
                return .iPhone_6_6S_7_8_PLUS
            case 2436:
                return .iPhone_X_Xs
            case 2688:
                return .iPhone_Xs_Max
            case 1792:
                return .iPhone_Xr
            default:
                return .iPhone_unknown
            }
        }
        return .iPad
    }
}

extension UIView {
    func fillSuperview(_ other: UIView, margins: UIEdgeInsets = .zero) {
        leftAnchor.constraint(equalTo: other.leftAnchor, constant: margins.left).isActive = true
        rightAnchor.constraint(equalTo: other.rightAnchor, constant: -margins.right).isActive = true
        topAnchor.constraint(equalTo: other.topAnchor, constant: margins.top).isActive = true
        bottomAnchor.constraint(equalTo: other.bottomAnchor, constant: -margins.bottom).isActive = true
    }
}

public extension UIColor {
    var components: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let components = self.cgColor.components!
        
        switch components.count == 2 {
        case true : return (r: components[0], g: components[0], b: components[0], a: components[1])
        case false: return (r: components[0], g: components[1], b: components[2], a: components[3])
        }
    }
    
    static func interpolate(from fromColor: UIColor, to toColor: UIColor, with progress: CGFloat) -> UIColor {
        let fromComponents = fromColor.components
        let toComponents = toColor.components
        
        let r = (1 - progress) * fromComponents.r + progress * toComponents.r
        let g = (1 - progress) * fromComponents.g + progress * toComponents.g
        let b = (1 - progress) * fromComponents.b + progress * toComponents.b
        let a = (1 - progress) * fromComponents.a + progress * toComponents.a
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
