import BaseKeyboard

class EntryKeyboard: KeyboardViewController {
    private var bannerPlugin: DivvunSpellBannerPlugin!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(withBanner: true)
        bannerPlugin = DivvunSpellBannerPlugin(keyboard: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
