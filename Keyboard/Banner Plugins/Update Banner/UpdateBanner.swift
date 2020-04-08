import Foundation

final class UpdateBanner: Banner {
    private let bannerView: UpdateBannerView

    var view: UIView {
        bannerView
    }

    init(theme: ThemeType) {
        bannerView = UpdateBannerView(theme: theme)
    }

    func updateTheme(_ theme: ThemeType) {
        bannerView.updateTheme(theme)
    }
}
