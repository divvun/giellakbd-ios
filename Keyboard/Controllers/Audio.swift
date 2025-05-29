import Foundation
import AVFoundation

public final class Audio {
    private static var isSoundEnabled: Bool = KeyboardSettings.isKeySoundEnabled

    public static func checkIfSoundEnabled() {
        isSoundEnabled = KeyboardSettings.isKeySoundEnabled
    }

    public static func playClickSound() {
        let clickSound: SystemSoundID = 1123
        play(systemSound: clickSound)
    }

    public static func playModifierSound() {
        let modifierSound: SystemSoundID = 1156
        play(systemSound: modifierSound)
    }

    public static func playDeleteSound() {
        let deleteSound: SystemSoundID = 1155
        play(systemSound: deleteSound)
    }

    private static func play(systemSound: SystemSoundID) {
        guard isSoundEnabled else {
            return
        }

        DispatchQueue.global().async {
            AudioServicesPlaySystemSound(systemSound)
        }
    }

}
