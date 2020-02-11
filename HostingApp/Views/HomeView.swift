import UIKit

private let blue = UIColor(r: 92, g: 133, b: 224)

class HomePrimaryButton: MenuButton {
    override func configureButtonStyles() {
        super.configureButtonStyles()

        setBackgroundColor(blue, for: .normal)
        setTitleColor(.white, for: .normal)
    }
}

class HomeView: UIView, Nibbable {
    @IBOutlet var bgImage: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var langButton: UIButton!
    @IBOutlet var langButton2: UIButton!
    @IBOutlet var helpButton: MenuButton!
    @IBOutlet var layoutsButton: MenuButton!
    @IBOutlet var aboutButton: MenuButton!
    @IBOutlet var testingButton: MenuButton!
    @IBOutlet var userDictionaryButton: MenuButton!

    @IBOutlet var configStack: UIStackView?

    override func awakeFromNib() {
        titleLabel.text = Strings.localizedName
        langButton2.setTitle(Strings.language, for: [])
        helpButton.setTitle(Strings.setUp(keyboard: Strings.localizedName), for: [])
        layoutsButton.setTitle(Strings.layouts, for: [])
        aboutButton.setTitle(Strings.about, for: [])
    }
}
