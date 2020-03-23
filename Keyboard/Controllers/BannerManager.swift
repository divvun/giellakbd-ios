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
    private let updateBanner: UpdateBanner
    private var currentBanner: Banner?

    init(view: UIView, theme: ThemeType, delegate: BannerManagerDelegate?) {
        self.view = view
        self.delegate = delegate

        spellBanner = SpellBanner(theme: theme)
        updateBanner = UpdateBanner(theme: theme)

        spellBanner.delegate = self
        updateBanner.delegate = self

        presentBanner(updateBanner)
    }

    private func presentBanner(_ banner: Banner) {
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

extension BannerManager: SpellBannerDelegate {
    var hasFullAccess: Bool {
        return delegate?.hasFullAccess ?? false
    }

    func didSelectSuggestion(banner: SpellBanner, suggestion: String) {
        delegate?.bannerDidProvideInput(banner: banner, inputText: suggestion)
    }
}

extension BannerManager: UpdateBannerDelegate {
    func willBeginupdates(banner: UpdateBanner) {
        presentBanner(banner)
    }

    func didFinishUpdates(banner: UpdateBanner) {
        presentBanner(spellBanner)
    }
}
