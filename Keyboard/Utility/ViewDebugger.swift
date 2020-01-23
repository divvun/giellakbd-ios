import UIKit

class ViewDebugger {
    public static func printViewHierarchy(view: UIView, indent: Int) {
        var emptyString = ""
        for _ in 0..<indent {
            emptyString += "    "
        }

        emptyString += String(describing: view.self).split(separator: ";").first! + ">"
        print(emptyString)
        
        for constraint in view.constraints {
            var ffs = ""
            for _ in 0..<indent {
                ffs += "    "
            }
            
            ffs += " - "
            ffs += String(describing: constraint)
            print(ffs)
        }
        
        for subview in view.subviews {
            printViewHierarchy(view: subview, indent: indent + 1)
        }
    }
}
