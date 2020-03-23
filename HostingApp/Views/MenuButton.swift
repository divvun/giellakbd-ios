import UIKit

private let blue = UIColor(r: 92, g: 133, b: 224)
private let highlight = UIColor(r: 0, g: 122, b: 255)

class MenuButton: SimpleButton {
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
