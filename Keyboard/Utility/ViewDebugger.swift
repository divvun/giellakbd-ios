import UIKit

class ViewDebugger {
    public static func printViewHierarchy(view: UIView, indentLevel: Int = 0, depth: Int) {
        guard depth > 0 else {
            return
        }

        let indent = String(repeating: "    ", count: indentLevel)

        let viewDescription = String(describing: view.self)
        print(indent + viewDescription)

        for constraint in view.constraints {
            let constraintDescription = String(describing: constraint)
            let constraintPrefix = "  - " // So we can tell views and constraints apart
            print(indent + constraintPrefix + constraintDescription)
        }

        for subview in view.subviews {
            printViewHierarchy(view: subview, indentLevel: indentLevel + 1, depth: depth - 1)
        }
    }
}
