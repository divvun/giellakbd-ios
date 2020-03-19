import Foundation

protocol Banner: class {
    var view: UIView { get }
    func updateTheme(_ theme: ThemeType)
}
