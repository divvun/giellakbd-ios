import Foundation
import Sentry
import libdivvunspell

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

        let currentWord = BannerItem(title: "\"\(word)\"", value: word)
        
        var suggestions = (try? speller
            .suggest(word: word)//, count: 3, maxWeight: 4999.99)
            .prefix(3)
            .map { BannerItem(title: $0, value: $0) }) ?? []
        
        // No need to show the same thing twice
        suggestions.removeAll { (bannerItem) -> Bool in
            bannerItem.value == word
        }

        if !isCancelled {
            DispatchQueue.main.async {
                plugin.banner.isHidden = false
                let items = [currentWord] + suggestions
                plugin.banner.setBannerItems(items)
            }
        }
    }
    
}

extension DivvunSpellBannerPlugin: BannerViewDelegate {
    public func textInputDidChange(_ banner: BannerView, context: CursorContext) {
        if context.currentWord == "" {
            banner.setBannerItems([])
            return
        }

        opQueue.cancelAllOperations()
        opQueue.addOperation(SuggestionOp(plugin: self, word: context.currentWord))
    }

    public func didSelectBannerItem(_ banner: BannerView, item: BannerItem) {
        keyboard.replaceSelected(with: item.value)
        // TODO: Sami languages want to autosuggest compounds, so let's not add spaces without configuration
//        keyboard.insertText(" ")
        opQueue.cancelAllOperations()

        banner.setBannerItems([])
    }
}

public class DivvunSpellBannerPlugin {
    unowned let banner: BannerView
    unowned let keyboard: KeyboardViewController

    fileprivate var archive: ThfstChunkedBoxSpellerArchive?
    fileprivate var speller: ThfstChunkedBoxSpeller? {
        return try? archive?.speller()
    }

    let opQueue: OperationQueue = {
        let o = OperationQueue()
        o.underlyingQueue = DispatchQueue.global(qos: .userInteractive)
        o.maxConcurrentOperationCount = 1
        return o
    }()

    private func getPrimaryLanguage() -> String? {
        if let ex = Bundle.main.infoDictionary!["NSExtension"] as? [String: AnyObject] {
            if let attrs = ex["NSExtensionAttributes"] as? [String: AnyObject] {
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
                let e = Sentry.Event(level: .error)
                Client.shared?.send(event: e, completion: nil)
                print("DivvunSpell **not** loaded.")
                return
            }

        }
    }

    public init(keyboard: KeyboardViewController) {
        self.keyboard = keyboard
        
        guard let bannerView = keyboard.bannerView else {
            fatalError("†hænx")
        }
        banner = bannerView

        banner.delegate = self
        loadBHFST()
    }
}
