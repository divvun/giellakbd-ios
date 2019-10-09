import UIKit

private let blue = UIColor(r: 92, g: 133, b: 224)
private let highlight = UIColor(r: 0, g: 122, b: 255)

class HomeMenuButton: SimpleButton {
    override func configureButtonStyles() {
        super.configureButtonStyles()

        contentEdgeInsets = UIEdgeInsets(top: 8, left: 2, bottom: 8, right: 2)

        titleLabel?.numberOfLines = 2
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.lineBreakMode = .byClipping
        titleLabel?.minimumScaleFactor = 0.3

        titleLabel?.textAlignment = .center

        setBorderColor(blue)
        setBorderWidth(2)

        setBackgroundColor(.clear, for: .normal)
        setBackgroundColor(highlight, for: .highlighted)
        setScale(0.99, for: .highlighted)

        setShadowColor(.gray)
        setShadowRadius(1)
        setShadowOffset(CGSize(width: 0, height: 0))

        setCornerRadius(2)

        setTitleColor(blue, for: .normal)
        setTitleColor(.white, for: .highlighted)
    }
}

class HomePrimaryButton: HomeMenuButton {
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
    @IBOutlet var helpButton: HomeMenuButton!
    @IBOutlet var layoutsButton: HomeMenuButton!
    @IBOutlet var aboutButton: HomeMenuButton!

    @IBOutlet var configStack: UIStackView?

    override func awakeFromNib() {
        titleLabel.text = Strings.localizedName
        langButton2.setTitle(Strings.language, for: [])
        helpButton.setTitle(Strings.setUp(keyboard: Strings.localizedName), for: [])
        layoutsButton.setTitle(Strings.layouts, for: [])
        aboutButton.setTitle(Strings.about, for: [])
    }
}
