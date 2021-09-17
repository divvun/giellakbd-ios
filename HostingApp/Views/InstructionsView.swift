import UIKit

final class InstructionsView: UIView, Nibbable {
    @IBOutlet var step1Label: UILabel!
    @IBOutlet var step2Label: UILabel!
    @IBOutlet var step3Label: UILabel!
    @IBOutlet var step4Label: UILabel!


    @IBOutlet var finishLabel: UILabel!
    @IBOutlet var tapSoundsLabel: UILabel!

    @IBOutlet var bgImage: UIImageView!
    @IBOutlet var settingsButton: MenuButton!

    override func awakeFromNib() {
        step1Label.attributedText = Strings.openApp(item: Strings.settings)
        step2Label.attributedText = Strings.tap(item: Strings.keyboards)
        step3Label.text = Strings.enableKeyboards
        step4Label.attributedText = Strings.tap(item: Strings.allowFullAccess)
        settingsButton.setTitle(Strings.settings, for: .normal)

        finishLabel.text = Strings.whenYouHaveFinished
        tapSoundsLabel.attributedText = Strings.enableTapSounds
    }
}
