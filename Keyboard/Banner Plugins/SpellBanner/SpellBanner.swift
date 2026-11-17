import Foundation
import Sentry
import DivvunSpell

struct SuggestionResult {
    let suggestions: [String]
    let isWordCorrect: Bool
}

/// Called on the main thread, with `nil` when no speller is loaded.
typealias SuggestionCompletion = (SuggestionResult?) -> Void

protocol SpellBannerDelegate: AnyObject {
    var hasFullAccess: Bool { get }
    func didSelectSuggestion(banner: SpellBanner, suggestion: String)
}

public final class SpellBanner: Banner {
    weak var delegate: SpellBannerDelegate?
    private(set) var dictionaryService: UserDictionaryService?
    private var speller: Speller?
    private let bannerView: SpellBannerView
    private let opQueue: OperationQueue = {
        let opQueue = OperationQueue()
        opQueue.underlyingQueue = DispatchQueue.global(qos: .userInteractive)
        opQueue.maxConcurrentOperationCount = 1
        return opQueue
    }()
    /// Serial, so the user dictionary sees each context in order. Its writes go to SQLite, which is too slow
    /// to do on the main thread for every keystroke.
    let dictionaryQueue = DispatchQueue(label: "SpellBanner.userDictionary", qos: .utility)
    /// Serial, so if a speller is reloaded while an earlier load is still running, the later one wins.
    /// User-initiated: suggestions can't appear until it finishes.
    private let spellerLoadingQueue = DispatchQueue(label: "SpellBanner.spellerLoading", qos: .userInitiated)
    /// Called on the main thread once a speller has loaded and is in use. For tests.
    var spellerDidLoad: (() -> Void)?

    var view: UIView {
        bannerView
    }

    var spellerURL: URL? {
        let spellerPackagesDir = KeyboardSettings.pahkatStoreURL
            .appendingPathComponent("pkg")

        let currentKeyboard = Bundle.main

        guard let spellerKey = currentKeyboard.spellerPackageKey,
            let packageId = spellerKey.pathComponents.last
        else {
            print("No speller package key found; BHFST not loaded.")
            return nil
        }

        guard let spellerPath = currentKeyboard.spellerPath else {
            print("No speller path found; BHFST not loaded.")
            return nil
        }

        return spellerPackagesDir
            .appendingPathComponent(packageId)
            .appendingPathComponent(spellerPath)
    }

    var spellerNeedsInstall: Bool {
        guard let spellerURL = spellerURL else {
            return false
        }
        let hasSpeller = FileManager.default.fileExists(atPath: spellerURL.path)
        let databaseExists = FileManager.default.fileExists(atPath: UserDictionary.dbFilePath)
        return !hasSpeller || !databaseExists
    }

    init(theme: Theme) {
        self.bannerView = SpellBannerView(theme: theme)
        bannerView.delegate = self
        loadSpeller()
    }

    public func updateSuggestions(_ context: CursorContext) {
        if let delegate = delegate,
            delegate.hasFullAccess,
            let dictionaryService = dictionaryService {
            let wordContext = WordContext(cursorContext: context)
            dictionaryQueue.async {
                dictionaryService.updateContext(wordContext)
            }
        }

        let currentWord = context.current.1

        if currentWord.isEmpty {
            bannerView.clearSuggestions()
            return
        }

        getSuggestionsFor(currentWord) { result in
            let suggestionItems = result.map {
                Self.makeSuggestionBannerItems(
                    currentWord: currentWord, suggestions: $0.suggestions, isWordCorrect: $0.isWordCorrect
                )
            } ?? []
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

    static func makeSuggestionBannerItems(currentWord: String, suggestions: [String], isWordCorrect: Bool) -> [SpellBannerItem] {
        var suggestions = suggestions
        suggestions.removeAll { $0 == currentWord } // don't show current word twice

        let currentWordItem = SpellBannerItem(title: .humanInput(currentWord, isCorrect: isWordCorrect), value: currentWord)
       
        let suggestionItems = suggestions.enumerated().map { (i, s) -> SpellBannerItemTitle in
            if (i == 0 && !isWordCorrect) {
                return .correction(s)
            }
            return .normal(s)
        }.map { SpellBannerItem(title: $0, value: $0.value.trimmingCharacters(in: CharacterSet(charactersIn: "*")))}
        return [currentWordItem] + suggestionItems
    }
    

    func updateTheme(_ theme: Theme) {
        bannerView.updateTheme(theme)
    }

    public func loadSpeller() {
        loadSpeller(from: spellerURL, locale: { KeyboardLocale.current })
    }

    func loadSpeller(from spellerURL: URL?, locale: @escaping () -> KeyboardLocale) {
        print("Loading speller…")

        // `speller` and `dictionaryService` are read on the main thread on every keystroke, so load on a
        // background queue but only hand the results over on the main thread.
        spellerLoadingQueue.async { [weak self] in
            print("Dispatching request to load speller…")

            guard let spellerPath = spellerURL?.path else {
                print("Unable to get spellerURL; BHFST not loaded")
                return
            }

            if !FileManager.default.fileExists(atPath: spellerPath) {
                print("No speller at: \(spellerPath)")
                print("DivvunSpell **not** loaded.")
                return
            }

            let speller: Speller
            do {
                let archive = try SpellerArchive.open(path: spellerPath)
                speller = try archive.speller()
                print("DivvunSpell loaded!")
            } catch let error {
                SentrySDK.capture(error: error)
                print("DivvunSpell **not** loaded.")
                return
            }

            // Created here, as it opens the user dictionary database.
            let dictionaryService = FeatureFlag.userDictionary
                ? UserDictionaryService(speller: speller, locale: locale())
                : nil

            DispatchQueue.main.async {
                guard let self = self else { return }
                self.speller = speller
                self.dictionaryService = dictionaryService
                self.spellerDidLoad?()
            }
        }
    }
}

extension SpellBanner: SpellBannerViewDelegate {
    public func didSelectBannerItem(_ banner: SpellBannerView, item: SpellBannerItem) {
        // Before the delegate replaces the word, so the dictionary sees this before the replacement.
        if let dictionaryService = dictionaryService {
            dictionaryQueue.async {
                dictionaryService.discardCurrentWord()
            }
        }
        delegate?.didSelectSuggestion(banner: self, suggestion: item.value)
        opQueue.cancelAllOperations()
        banner.clearSuggestions()
    }
}

final class SuggestionOperation: Operation, @unchecked Sendable {
    weak var userDictionary: UserDictionary?
    weak var speller: Speller?
    let word: String
    let completion: SuggestionCompletion

    init(userDictionary: UserDictionary?,
         speller: Speller?,
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

        // Hold the speller for the whole operation, so it can't go away between the two lookups.
        guard let speller = speller else {
            DispatchQueue.main.async {
                self.completion(nil)
            }
            return
        }

        let suggestions = getSuggestions(for: word, speller: speller)
        // Checked here rather than when building the banner items, which happens on the main thread.
        let isWordCorrect = (try? speller.isCorrect(word: word)) ?? false
        if !isCancelled {
            let result = SuggestionResult(suggestions: suggestions, isWordCorrect: isWordCorrect)
            DispatchQueue.main.async {
                self.completion(result)
            }
        }
    }

    private func getSuggestions(for word: String, speller: Speller) -> [String] {
        var suggestions: [String] = []

        if let dictionary = userDictionary {
            let userSuggestions = dictionary.getSuggestions(for: word)
            if !userSuggestions.isEmpty {
                let userSuggestion = ["*" + userSuggestions[0]]
                suggestions.append(contentsOf: userSuggestion)
            } else {
                suggestions.append(contentsOf: userSuggestions)
            }
        }
        
        let spellerSuggestions = (try? speller
            .suggest(word: word)
            .prefix(3)) ?? []
        suggestions.append(contentsOf: spellerSuggestions)
    
        return suggestions
    }
}
