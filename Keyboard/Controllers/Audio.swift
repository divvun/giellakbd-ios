import Foundation
import AVFoundation
import UIKit

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

/// A light tap on each key press, like the system keyboard's haptic feedback.
///
/// Third-party keyboards can't read the system's Keyboard Feedback setting, so this has its own, off by default.
/// iOS only plays it when the user has allowed Full Access, and not when System Haptics is off.
public final class KeyHaptics {
    private static var isEnabled: Bool = KeyboardSettings.isHapticFeedbackEnabled
    private static let generator = UIImpactFeedbackGenerator(style: .light)
    /// Full-strength `.light` taps felt firmer than the system keyboard's, so play them at reduced intensity.
    private static let intensity: CGFloat = 0.7

    public static func checkIfEnabled() {
        isEnabled = KeyboardSettings.isHapticFeedbackEnabled
    }

    /// Readies the Taptic Engine so the next tap isn't delayed. Call when a touch begins.
    public static func prepare() {
        guard isEnabled else {
            return
        }
        generator.prepare()
    }

    public static func playKeyPress() {
        guard isEnabled else {
            return
        }
        generator.impactOccurred(intensity: intensity)
    }
}
