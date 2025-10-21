import Foundation

final class SpellerAvailableBanner: Banner {
    private let bannerView: SpellerAvailableBannerView

    var view: UIView {
        bannerView
    }

    init(theme: Theme) {
        bannerView = SpellerAvailableBannerView(theme: theme)
    }

    func updateTheme(_ theme: Theme) {
        bannerView.updateTheme(theme)
    }
}
