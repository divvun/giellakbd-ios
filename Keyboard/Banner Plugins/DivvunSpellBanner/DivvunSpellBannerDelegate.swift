import Foundation

protocol DivvunSpellBannerDelegate: class {
    var hasFullAccess: Bool { get }
    func didSelectSuggestion(banner: DivvunSpellBanner, text: String)
}
