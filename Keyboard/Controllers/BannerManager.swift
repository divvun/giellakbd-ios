import Foundation
import DivvunSpell // TODO: possible to remove this dependency except for inside DivvunSpellBanner?

protocol BannerManagerDelegate: class {
    var hasFullAccess: Bool { get }
    func bannerDidProvideInput(banner: Banner, inputText: String)
}

final class BannerManager {
    private let view: UIView

    weak var delegate: BannerManagerDelegate?

    private let divvunSpell: SpellBanner

    init(view: UIView, theme: ThemeType, delegate: BannerManagerDelegate?) {
        self.view = view
        self.delegate = delegate

        spellBanner = SpellBanner(theme: theme)
        spellBanner.delegate = self
        presentBanner(spellBanner)
    }

    private func presentBanner(_ banner: Banner) {
        view.addSubview(banner.view)
        banner.view.fill(superview: self.view)
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
