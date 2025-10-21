import Foundation

protocol Banner: AnyObject {
    var view: UIView { get }
    func updateTheme(_ theme: Theme)
}
