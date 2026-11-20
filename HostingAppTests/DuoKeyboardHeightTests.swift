@testable import BaseKeyboard
import Testing
import UIKit

/// iPhone Duo heights depend on which display the keyboard is on, not just the device model.
@MainActor
struct DuoKeyboardHeightTests {
    private static let outerPortrait = CGSize(width: 466, height: 678)
    private static let outerLandscape = CGSize(width: 678, height: 466)
    private static let innerPortrait = CGSize(width: 669, height: 951)
    private static let innerLandscape = CGSize(width: 951, height: 669)

    private let phoneTraits = UITraitCollection(userInterfaceIdiom: .phone)

    private func height(screenSize: CGSize, legacy: Bool = false) -> CGFloat {
        let context = DeviceContext(device: .iPhoneDuo,
                                    isLandscape: screenSize.width > screenSize.height,
                                    screenSize: screenSize)
        return KeyboardHeightProvider.height(for: context, traitCollection: phoneTraits, legacy: legacy)
    }

    @Test("Folded outer display uses the system keyboard's key sizes plus the banner")
    func foldedOuterDisplay() {
        #expect(abs(height(screenSize: Self.outerPortrait) - (48 + 8 + 4 * 45 + 3 * 11 + 20.0 / 3)) < 0.001)
        #expect(abs(height(screenSize: Self.outerLandscape) - (48 + 6 + 4 * 100.0 / 3 + 3 * 9 + 4)) < 0.001)
    }

    @Test("Before iOS 26, the folded outer display uses the 5.4 inch phone heights")
    func foldedOuterDisplayBeforeIOS26() {
        #expect(height(screenSize: Self.outerPortrait, legacy: true) == 272)
        #expect(height(screenSize: Self.outerLandscape, legacy: true) == 198)
    }

    @Test("Unfolded inner display uses the system keyboard's key sizes plus the banner")
    func unfoldedInnerDisplay() {
        #expect(height(screenSize: Self.innerPortrait, legacy: false) == 285)
        #expect(height(screenSize: Self.innerLandscape, legacy: false) == 253)
    }

    @Test("Before iOS 26, the unfolded inner display uses its own height")
    func unfoldedInnerDisplayBeforeIOS26() {
        #expect(height(screenSize: Self.innerPortrait, legacy: true) == 301)
        #expect(height(screenSize: Self.innerLandscape, legacy: true) == 267)
    }
}
