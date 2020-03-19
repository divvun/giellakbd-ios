import Foundation
import DivvunSpell // TODO: possible to remove this dependency except for inside DivvunSpellBanner?

protocol BannerManagerDelegate: class {
    func bannerDidProvideInput(banner: Banner, inputText: String)
}

final class BannerManager {
    private let view: UIView

    weak var delegate: BannerManagerDelegate?

    private let divvunSpell: DivvunSpellBanner

    init(view: UIView, theme: ThemeType, delegate: BannerManagerDelegate?) {
        self.view = view
        self.delegate = delegate

        divvunSpell = DivvunSpellBanner(theme: theme)
        divvunSpell.delegate = self
        presentBanner(divvunSpell)
    }

    private func presentBanner(_ banner: Banner) {
        view.addSubview(banner.view)
        banner.view.fill(superview: self.view)
    }

    public func propagateTextInputUpdateToBanners(newContext: CursorContext) {
        divvunSpell.setContext(newContext)
    }

    public func updateTheme(_ theme: ThemeType) {

    }
}

extension BannerManager: DivvunSpellBannerDelegate {
    func didSelectSuggestion(banner: DivvunSpellBanner, text: String) {
        delegate?.bannerDidProvideInput(banner: banner, inputText: text)
    }
}
