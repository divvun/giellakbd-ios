import Foundation

protocol DivvunSpellBannerDelegate: class {
    func didSelectSuggestion(banner: DivvunSpellBanner, text: String)
}
