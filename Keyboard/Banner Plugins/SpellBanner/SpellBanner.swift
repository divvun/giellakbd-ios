import Foundation
import Sentry
import DivvunSpell

typealias SuggestionCompletion = ([String]) -> Void

protocol SpellBannerDelegate: class {
    var hasFullAccess: Bool { get }
    func didSelectSuggestion(banner: SpellBanner, text: String)
}

public final class SpellBanner: Banner {
    let bannerView: SpellBannerView
    let opQueue: OperationQueue = {
        let opQueue = OperationQueue()
        opQueue.underlyingQueue = DispatchQueue.global(qos: .userInteractive)
        opQueue.maxConcurrentOperationCount = 1
        return opQueue
    }()

    weak var delegate: SpellBannerDelegate?

    var view: UIView {
        bannerView
    }

    fileprivate var dictionaryService: UserDictionaryService?
    fileprivate var speller: ThfstChunkedBoxSpeller?

    init(theme: ThemeType) {
        self.bannerView = SpellBannerView(theme: theme)
        bannerView.delegate = self
        loadSpeller()
    }

    public func setContext(_ context: CursorContext) {
        if let delegate = delegate,
            delegate.hasFullAccess {
            dictionaryService?.updateContext(WordContext(cursorContext: context))
        }

        let currentWord = context.current.1

        if currentWord.isEmpty {
            bannerView.setBannerItems([])
            return
        }

        getSuggestionsFor(currentWord) { (suggestions) in
            let suggestionItems = self.makeSuggestionBannerItems(currentWord: currentWord, suggestions: suggestions)
            self.bannerView.isHidden = false
            self.bannerView.setBannerItems(suggestionItems)
        }
    }

    private func getSuggestionsFor(_ word: String, completion: @escaping SuggestionCompletion) {
        opQueue.cancelAllOperations()
        let suggestionOp = SuggestionOperation(banner: self, word: word, completion: completion)
        opQueue.addOperation(suggestionOp)
    }

    private func makeSuggestionBannerItems(currentWord: String, suggestions: [String]) -> [SpellBannerItem] {
        var suggestions = suggestions
        // Don't show the current word twice; it will always be shown in the banner item created below
        suggestions.removeAll { $0 == currentWord }
        let suggestionItems = suggestions.map { SpellBannerItem(title: $0, value: $0) }

        let currentWordItem = SpellBannerItem(title: "\"\(currentWord)\"", value: currentWord)

        return [currentWordItem] + suggestionItems
    }

    func updateTheme(_ theme: ThemeType) {
        bannerView.updateTheme(theme: theme)
    }

    private func getPrimaryLanguage() -> String? {
        if let extensionInfo = Bundle.main.infoDictionary!["NSExtension"] as? [String: AnyObject] {
            if let attrs = extensionInfo["NSExtensionAttributes"] as? [String: AnyObject] {
                if let lang = attrs["PrimaryLanguage"] as? String {
                    return String(lang.split(separator: "-")[0])
                }
            }
        }

        return nil
    }

    private func loadSpeller() {
        print("Loading speller…")

        DispatchQueue.global(qos: .background).async {
            print("Dispatching request to load speller…")

            guard let bundle = Bundle.top.url(forResource: "dicts", withExtension: "bundle") else {
                print("No dict bundle found; BHFST not loaded.")
                return
            }

            guard let lang = self.getPrimaryLanguage() else {
                print("No primary language found for keyboard; BHFST not loaded.")
                return
            }

            let path = bundle.appendingPathComponent("\(lang).bhfst")

            if !FileManager.default.fileExists(atPath: path.path) {
                print("No speller at: \(path)")
                print("DivvunSpell **not** loaded.")
                return
            }

            let speller: ThfstChunkedBoxSpeller
            do {
                let archive = try ThfstChunkedBoxSpellerArchive.open(path: path.path)
                speller = try archive.speller()
                self.speller = speller
                print("DivvunSpell loaded!")
            } catch {
                let error = Sentry.Event(level: .error)
                Client.shared?.send(event: error, completion: nil)
                print("DivvunSpell **not** loaded.")
                return
            }

            #if ENABLE_USER_DICTIONARY
            self.dictionaryService = UserDictionaryService(speller: speller, locale: KeyboardLocale.current)
            #endif
        }
    }
}

extension SpellBanner: SpellBannerViewDelegate {
    public func didSelectBannerItem(_ banner: SpellBannerView, item: SpellBannerItem) {
        delegate?.didSelectSuggestion(banner: self, text: item.value)
        opQueue.cancelAllOperations()
        banner.setBannerItems([])
    }
}

final class SuggestionOperation: Operation {
    weak var banner: SpellBanner?
    let word: String
    let completion: SuggestionCompletion

    init(banner: SpellBanner, word: String, completion: @escaping SuggestionCompletion) {
        self.banner = banner
        self.word = word
        self.completion = completion
    }

    override func main() {
        if isCancelled {
            return
        }

        let suggestions = getSuggestions(for: word)
        if !isCancelled {
            DispatchQueue.main.async {
                self.completion(suggestions)
            }
        }
    }

    private func getSuggestions(for word: String) -> [String] {
        var suggestions: [String] = []

        if let dictionary = self.banner?.dictionaryService?.dictionary {
            let userSuggestions = dictionary.getSuggestions(for: word)
            suggestions.append(contentsOf: userSuggestions)
        }

        if let speller = self.banner?.speller {
            let spellerSuggestions = (try? speller
                .suggest(word: word)
                .prefix(3)) ?? []
            suggestions.append(contentsOf: spellerSuggestions)
        }

        return suggestions
    }
}
