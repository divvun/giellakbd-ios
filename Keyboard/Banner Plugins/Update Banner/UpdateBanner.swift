import Foundation

protocol UpdateBannerDelegate: class {
    func willBeginupdates(banner: UpdateBanner)
    func didFinishUpdates(banner: UpdateBanner)
}

final class UpdateBanner: Banner {
    weak var delegate: UpdateBannerDelegate?
    private let bannerView: UpdateBannerView

    var view: UIView {
        bannerView
    }

    init(theme: ThemeType) {
        bannerView = UpdateBannerView(theme: theme)
        bannerView.progress = 0.3 // TESTING only - remove
    }

    func updateTheme(_ theme: ThemeType) {
        bannerView.updateTheme(theme)
    }

    private func checkForUpdates() {
        // TODO: implement this and a didFinishUpdates() method
        // interface may look a bit different once pahkat is added
    }

    private func startUpdates() {
        delegate?.willBeginupdates(banner: self)
    }
}
