import Foundation

protocol UpdateBannerDelegate: class {
    func willBeginupdates(banner: UpdateBanner)
    func didFinishUpdates(banner: UpdateBanner)
}

final class UpdateBanner: Banner {
    weak var delegate: UpdateBannerDelegate?
    private let bannerView: UpdateBannerView
    private let ipc = IPC()

    var view: UIView {
        bannerView
    }

    init(theme: ThemeType) {
        bannerView = UpdateBannerView(theme: theme)
        ipc.delegate = self
    }

    func updateTheme(_ theme: ThemeType) {
        bannerView.updateTheme(theme)
    }

    private func startUpdates() {
        delegate?.willBeginupdates(banner: self)
    }
}

extension UpdateBanner: IPCDelegate {
    func didBeginDownloading(id: String) {
        bannerView.text = "Downloading \(id)"
    }

    func didFinishInstalling(id: String) {
        bannerView.text = "Finished installing \(id)"
    }
}
