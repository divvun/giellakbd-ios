import Foundation
import UIKit

extension String {
    func suffix(after index: String.Index) -> String.SubSequence {
        if index >= endIndex {
            return suffix(from: endIndex)
        }

        return suffix(from: self.index(after: index))
    }
}

extension Substring {
    func lastIndex(after character: Character) -> String.Index? {
        guard let index = self.lastIndex(of: character) else { return nil }
        if index == endIndex { return nil }
        return self.index(after: index)
    }
}

extension UIColor {
    convenience init(r: Int, g: Int, b: Int, a: Double = 1) {
        self.init(red: CGFloat(r) / CGFloat(255), green: CGFloat(g) / CGFloat(255), blue: CGFloat(b) / CGFloat(255), alpha: CGFloat(a))
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
        let components = cgColor.components!

        switch components.count == 2 {
        case true: return (r: components[0], g: components[0], b: components[0], a: components[1])
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
