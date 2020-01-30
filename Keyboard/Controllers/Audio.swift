import Foundation
import AVFoundation

public class Audio {
    private static let clickSound: SystemSoundID = 1123
    private static let deleteSound: SystemSoundID = 1155
    private static let modifierSound: SystemSoundID = 1156
    private static let fallbackSound: SystemSoundID = 1104

    public static func playClickSound() {
        play(systemSound: clickSound)
    }

    public static func playModifierSound() {
        play(systemSound: modifierSound)
    }

    public static func playDeleteSound() {
        play(systemSound: deleteSound)
    }

    private static func play(systemSound: SystemSoundID) {

        var sound = systemSound

        if #available(iOS 10.0, *) {
            // Nothing
        } else {
            sound = fallbackSound
        }

        DispatchQueue.global().async {
            AudioServicesPlaySystemSound(sound)
        }
    }

}
