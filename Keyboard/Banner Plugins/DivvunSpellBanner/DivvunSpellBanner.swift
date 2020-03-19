import Foundation
import Sentry
import DivvunSpell

protocol DivvunSpellBannerDelegate: class {
    var hasFullAccess: Bool { get }
    func didSelectSuggestion(banner: DivvunSpellBanner, text: String)
}

public final class DivvunSpellBanner: Banner {
    let bannerView: DivvunSpellBannerView

    weak var delegate: DivvunSpellBannerDelegate?

    var view: UIView {
        bannerView
    }

    fileprivate var dictionaryService: UserDictionaryService?
    fileprivate var archive: ThfstChunkedBoxSpellerArchive?
    fileprivate var speller: ThfstChunkedBoxSpeller? {
        return try? archive?.speller()
    }

    let opQueue: OperationQueue = {
        let opQueue = OperationQueue()
        opQueue.underlyingQueue = DispatchQueue.global(qos: .userInteractive)
        opQueue.maxConcurrentOperationCount = 1
        return opQueue
    }()

    init(theme: ThemeType) {
        self.bannerView = DivvunSpellBannerView(theme: theme)
        bannerView.delegate = self

        loadBHFST()
    }

    public func setContext(_ context: CursorContext) {
        if let delegate = delegate,
            delegate.hasFullAccess {
            dictionaryService?.updateContext(WordContext(cursorContext: context))
        }

        if context.current.1 == "" {
            bannerView.setBannerItems([])
            return
        }

        opQueue.cancelAllOperations()
        opQueue.addOperation(SuggestionOperation(plugin: self, word: context.current.1))
    }

    func updateTheme(_ theme: ThemeType) {
        // TODO: implement me
        // probably self.bannerView.updateTheme(theme)
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

    private func loadBHFST() {
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

            do {
                self.archive = try ThfstChunkedBoxSpellerArchive.open(path: path.path)
                print("DivvunSpell loaded!")
            } catch {
                let error = Sentry.Event(level: .error)
                Client.shared?.send(event: error, completion: nil)
                print("DivvunSpell **not** loaded.")
                return
            }

            #if ENABLE_USER_DICTIONARY
            do {
                if let speller = try self.archive?.speller() {
                    self.dictionaryService = UserDictionaryService(speller: speller, locale: KeyboardLocale.current)
                }
            } catch {
                let error = Sentry.Event(level: .error)
                Client.shared?.send(event: error, completion: nil)
                print("DivvunSpell UserDictionaryService **not** loaded.")
                return
            }
            #endif
        }
    }
}

extension DivvunSpellBanner: DivvunSpellBannerViewDelegate {
    public func didSelectBannerItem(_ banner: DivvunSpellBannerView, item: BannerItem) {
        delegate?.didSelectSuggestion(banner: self, text: item.value)
        opQueue.cancelAllOperations()

        banner.setBannerItems([])
    }
}

final class SuggestionOperation: Operation {
    weak var plugin: DivvunSpellBanner?
    let word: String

    init(plugin: DivvunSpellBanner, word: String) {
        self.plugin = plugin
        self.word = word
    }

    override func main() {
        if isCancelled {
            return
        }

        showSpellingSuggestionsInBanner()
    }

    private func showSpellingSuggestionsInBanner() {
        guard let plugin = self.plugin else { return }

        let suggestionItems = getSuggestionItems(for: word)

        if !isCancelled {
            DispatchQueue.main.async {
                plugin.bannerView.isHidden = false
                plugin.bannerView.setBannerItems(suggestionItems)
            }
        }
    }

    private func getSuggestionItems(for word: String) -> [BannerItem] {
        var suggestions = getSuggestions(for: word)

        // Don't show the current word twice; it will always be shown in the banner item created below
        suggestions.removeAll { $0 == word }
        let suggestionItems = suggestions.map { BannerItem(title: $0, value: $0) }

        let currentWord = BannerItem(title: "\"\(word)\"", value: word)

        return [currentWord] + suggestionItems
    }

    private func getSuggestions(for word: String) -> [String] {
        var suggestions: [String] = []

        if let dictionary = self.plugin?.dictionaryService?.dictionary {
            let userSuggestions = dictionary.getSuggestions(for: word)
            suggestions.append(contentsOf: userSuggestions)
        }

        if let speller = self.plugin?.speller {
            let spellerSuggestions = (try? speller
                .suggest(word: word)
                .prefix(3)) ?? []
            suggestions.append(contentsOf: spellerSuggestions)
        }

        return suggestions
    }
}
