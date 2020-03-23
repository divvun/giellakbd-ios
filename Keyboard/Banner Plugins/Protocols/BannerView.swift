import Foundation

protocol BannerView: UIView {
    init(theme: ThemeType)
    func updateTheme(_ theme: ThemeType)
}
