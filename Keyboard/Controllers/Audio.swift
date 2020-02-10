import Foundation
import AVFoundation

public class Audio {
    private static var isSoundEnabled: Bool = KeyboardSettings.isKeySoundEnabled
    private static let clickSound: SystemSoundID = 1123
    private static let deleteSound: SystemSoundID = 1155
    private static let modifierSound: SystemSoundID = 1156

    public static func checkIfSoundEnabled() {
        isSoundEnabled = KeyboardSettings.isKeySoundEnabled
    }

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
        guard isSoundEnabled else {
            return
        }

        DispatchQueue.global().async {
            AudioServicesPlaySystemSound(systemSound)
        }
    }

}
