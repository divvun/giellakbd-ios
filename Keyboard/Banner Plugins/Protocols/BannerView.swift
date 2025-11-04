import Foundation

protocol BannerView: UIView {
    init(theme: Theme)
    func updateTheme(_ theme: Theme)
}
