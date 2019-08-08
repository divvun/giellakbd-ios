import BaseKeyboard

class EntryKeyboard: KeyboardViewController {
    private var bannerPlugin: DivvunSpellBannerPlugin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bannerPlugin = DivvunSpellBannerPlugin(keyboard: self)
    }
}
