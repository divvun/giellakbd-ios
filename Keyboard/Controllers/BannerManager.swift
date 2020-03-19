import Foundation
import DivvunSpell // TODO: possible to remove this dependency except for inside DivvunSpellBanner?

final class BannerManager {
    private let view: UIView

    private let divvunSpell: DivvunSpellBanner

    init(view: UIView, theme: ThemeType) {
        self.view = view
        divvunSpell = DivvunSpellBanner(theme: theme)
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
