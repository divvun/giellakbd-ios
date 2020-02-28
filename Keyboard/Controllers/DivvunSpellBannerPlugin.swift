import Foundation
import Sentry
import DivvunSpell

class SuggestionOp: Operation {
    weak var plugin: DivvunSpellBannerPlugin?
    let word: String

    init(plugin: DivvunSpellBannerPlugin, word: String) {
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
        guard let speller = plugin.speller else { return }

        let suggestionItems = getSuggestionItems(for: word, from: speller)

        if !isCancelled {
            DispatchQueue.main.async {
                plugin.banner.isHidden = false
                plugin.banner.setBannerItems(suggestionItems)
            }
        }
    }

    private func getSuggestionItems(for word: String, from speller: Speller) -> [BannerItem] {
        let currentWord = BannerItem(title: "\"\(word)\"", value: word)
        var suggestions = (try? speller
            .suggest(word: word)//, count: 3, maxWeight: 4999.99)
            .prefix(3)
            .map { BannerItem(title: $0, value: $0) }) ?? []

        // No need to show the same thing twice
        suggestions.removeAll { (bannerItem) -> Bool in
            bannerItem.value == word
        }
        return [currentWord] + suggestions
    }

}

extension DivvunSpellBannerPlugin: BannerViewDelegate {
    public func textInputDidChange(_ banner: BannerView, context: CursorContext) {
        dictionaryDaemon?.updateContext(WordContext(cursorContext: context))

        if context.current.1 == "" {
            banner.setBannerItems([])
            return
        }

        opQueue.cancelAllOperations()
        opQueue.addOperation(SuggestionOp(plugin: self, word: context.current.1))
    }

    public func didSelectBannerItem(_ banner: BannerView, item: BannerItem) {
        Audio.playClickSound()
        keyboard.replaceSelected(with: item.value)
        opQueue.cancelAllOperations()

        banner.setBannerItems([])
    }
}

public class DivvunSpellBannerPlugin {
    unowned let banner: BannerView
    unowned let keyboard: KeyboardViewController

    private var dictionaryDaemon: UserDictionaryDaemon?
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

    public init(keyboard: KeyboardViewController) {
        self.keyboard = keyboard

        guard let bannerView = keyboard.bannerView else {
            fatalError("No banner view found in DivvunSpellBannerPlugin init")
        }
        banner = bannerView

        banner.delegate = self
        loadBHFST()
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

            do {
                if let speller = try self.archive?.speller() {
                    self.dictionaryDaemon = UserDictionaryDaemon(speller: speller)
                }
            } catch {
                let error = Sentry.Event(level: .error)
                Client.shared?.send(event: error, completion: nil)
                print("DivvunSpell UserDictionaryDaemon **not** loaded.")
                return
            }
        }
    }
}
