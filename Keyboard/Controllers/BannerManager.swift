import Foundation
import DivvunSpell

protocol BannerManagerDelegate: class {
    var hasFullAccess: Bool { get }
    func bannerDidProvideInput(banner: Banner, inputText: String)
}

final class BannerManager {
    weak var delegate: BannerManagerDelegate?
    private let view: UIView
    private let spellBanner: SpellBanner
    private let updateInProgressBanner: UpdateBanner
    private let spellerAvailableBanner: SpellerAvailableBanner
    private var currentBanner: Banner?
    private let ipc = IPC()

    init(view: UIView, theme: ThemeType, delegate: BannerManagerDelegate?) {
        self.view = view
        self.delegate = delegate

        spellBanner = SpellBanner(theme: theme)
        updateInProgressBanner = UpdateBanner(theme: theme)
        spellerAvailableBanner = SpellerAvailableBanner(theme: theme)

        ipc.delegate = self
        spellBanner.delegate = self

        print(KeyboardSettings.groupContainerURL)

        updateBanner()
    }

    private func updateBanner() {
        guard let currentSpellerId = Bundle.main.spellerPackageKey else {
            print("BannerMananger: Couldn't get current speller id")
            // There is no speller for this keyboard. Show empty spell banner.
            presentBanner(spellBanner)
            return
        }

        if ipc.isDownloading(id: currentSpellerId.absoluteString) {
            presentBanner(updateInProgressBanner)
        } else if spellBanner.spellerNeedsInstall {
            presentBanner(spellerAvailableBanner)
        } else {
            presentBanner(spellBanner)
        }
    }

    private func presentBanner(_ banner: Banner) {
        if type(of: banner) == type(of: currentBanner) {
            return
        }
        currentBanner?.view.removeFromSuperview()
        view.addSubview(banner.view)
        banner.view.fill(superview: self.view)
        currentBanner = banner
    }

    public func propagateTextInputUpdateToBanners(newContext: CursorContext) {
        spellBanner.updateSuggestions(newContext)
    }

    public func updateTheme(_ theme: ThemeType) {
        spellBanner.updateTheme(theme)
    }
}

extension BannerManager: IPCDelegate {
    func didBeginDownloading(id: String) {
    }

    func didFinishInstalling(id: String) {
        spellBanner.loadSpeller()
        updateBanner()
    }
}

extension BannerManager: SpellBannerDelegate {
    var hasFullAccess: Bool {
        return delegate?.hasFullAccess ?? false
    }

    func didSelectSuggestion(banner: SpellBanner, suggestion: String) {
        delegate?.bannerDidProvideInput(banner: banner, inputText: suggestion)
    }
}
