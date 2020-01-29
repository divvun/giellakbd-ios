import BaseKeyboard

class EntryKeyboard: KeyboardViewController {
    private var bannerPlugin: DivvunSpellBannerPlugin?
    private var showsBanner = true

    /*
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(withBanner: showsBanner)
        if showsBanner {
            bannerPlugin = DivvunSpellBannerPlugin(keyboard: self)
        }
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
    */

    override func viewDidLoad() {
        super.viewDidLoad()
        if showsBanner {
            bannerPlugin = DivvunSpellBannerPlugin(keyboard: self)
        }
    }
}
