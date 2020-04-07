import Foundation

final class UpdateBanner: Banner {
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
}

extension UpdateBanner: IPCDelegate {
    func didBeginDownloading(id: String) {
        bannerView.text = "Downloading \(id)"
    }

    func didFinishInstalling(id: String) {
        bannerView.text = "Finished installing \(id)"
    }
}
