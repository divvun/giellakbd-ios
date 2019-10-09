import UIKit

class InstructionsView: UIView, Nibbable {
    @IBOutlet var step1Label: UILabel!
    @IBOutlet var step2Label: UILabel!
    @IBOutlet var step3Label: UILabel!
    @IBOutlet var step4Label: UILabel!
    @IBOutlet var step5Label: UILabel!
    @IBOutlet var step6Label: UILabel!

    @IBOutlet var finishLabel: UILabel!
    @IBOutlet var tapSoundsLabel: UILabel!

    @IBOutlet var bgImage: UIImageView!

    override func awakeFromNib() {
        step1Label.attributedText = Strings.openApp(item: Strings.settings)
        step2Label.attributedText = Strings.tap(item: Strings.general)
        step3Label.attributedText = Strings.tap(item: Strings.keyboard)
        step4Label.attributedText = Strings.tap(item: Strings.keyboards)
        step5Label.attributedText = Strings.tap(item: Strings.addNewKeyboard)
        step6Label.attributedText = Strings.tap(item: Strings.localizedName)

        finishLabel.text = Strings.whenYouHaveFinished
        tapSoundsLabel.attributedText = Strings.enableTapSounds
    }
}
