import Foundation

final class UpdateBanner: Banner {
    private let bannerView: UpdateBannerView

    var view: UIView {
        bannerView
    }

    init(theme: Theme) {
        bannerView = UpdateBannerView(theme: theme)
    }

    func updateTheme(_ theme: Theme) {
        bannerView.updateTheme(theme)
    }
}
