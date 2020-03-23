import Foundation
import Sentry
import DivvunSpell

typealias SuggestionCompletion = ([String]) -> Void

protocol SpellBannerDelegate: class {
    var hasFullAccess: Bool { get }
    func didSelectSuggestion(banner: SpellBanner, suggestion: String)
}

public final class SpellBanner: Banner {
    weak var delegate: SpellBannerDelegate?
    private var dictionaryService: UserDictionaryService?
    private var speller: ThfstChunkedBoxSpeller?
    private let bannerView: SpellBannerView
    private let opQueue: OperationQueue = {
        let opQueue = OperationQueue()
        opQueue.underlyingQueue = DispatchQueue.global(qos: .userInteractive)
        opQueue.maxConcurrentOperationCount = 1
        return opQueue
    }()

    var view: UIView {
        bannerView
    }

    init(theme: ThemeType) {
        self.bannerView = SpellBannerView(theme: theme)
        bannerView.delegate = self
        loadSpeller()
    }

    public func updateSuggestions(_ context: CursorContext) {
        if let delegate = delegate,
            delegate.hasFullAccess {
            dictionaryService?.updateContext(WordContext(cursorContext: context))
        }

        let currentWord = context.current.1

        if currentWord.isEmpty {
            bannerView.clearSuggestions()
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
        let dictionary = self.dictionaryService?.dictionary
        let speller = self.speller
        let suggestionOp = SuggestionOperation(userDictionary: dictionary, speller: speller, word: word, completion: completion)
        opQueue.addOperation(suggestionOp)
    }

    private func makeSuggestionBannerItems(currentWord: String, suggestions: [String]) -> [SpellBannerItem] {
        let currentWordItem = SpellBannerItem(title: "\"\(currentWord)\"", value: currentWord)

        var suggestions = suggestions
        suggestions.removeAll { $0 == currentWord } // don't show current word twice
        let suggestionItems = suggestions.map { SpellBannerItem(title: $0, value: $0) }

        return [currentWordItem] + suggestionItems
    }

    func updateTheme(_ theme: ThemeType) {
        bannerView.updateTheme(theme)
    }

    private func getPrimaryLanguage() -> String? {
        guard let extensionInfo = Bundle.main.infoDictionary!["NSExtension"] as? [String: AnyObject],
            let attrs = extensionInfo["NSExtensionAttributes"] as? [String: AnyObject],
            let lang = attrs["PrimaryLanguage"] as? String else {
                return nil
        }
        return String(lang.split(separator: "-")[0])
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
        delegate?.didSelectSuggestion(banner: self, suggestion: item.value)
        opQueue.cancelAllOperations()
        banner.clearSuggestions()
    }
}

final class SuggestionOperation: Operation {
    weak var userDictionary: UserDictionary?
    weak var speller: ThfstChunkedBoxSpeller?
    let word: String
    let completion: SuggestionCompletion

    init(userDictionary: UserDictionary?,
         speller: ThfstChunkedBoxSpeller?,
         word: String,
         completion: @escaping SuggestionCompletion) {
        self.userDictionary = userDictionary
        self.speller = speller
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

        if let dictionary = userDictionary {
            let userSuggestions = dictionary.getSuggestions(for: word)
            suggestions.append(contentsOf: userSuggestions)
        }

        if let speller = speller {
            let spellerSuggestions = (try? speller
                .suggest(word: word)
                .prefix(3)) ?? []
            suggestions.append(contentsOf: spellerSuggestions)
        }

        return suggestions
    }
}
