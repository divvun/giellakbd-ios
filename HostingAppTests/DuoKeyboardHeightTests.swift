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

    private func height(screenSize: CGSize) -> CGFloat {
        let context = DeviceContext(device: .iPhoneDuo,
                                    isLandscape: screenSize.width > screenSize.height,
                                    screenSize: screenSize)
        return KeyboardHeightProvider.height(for: context, traitCollection: phoneTraits)
    }

    @Test("Folded outer display uses the 5.4 inch phone heights")
    func foldedOuterDisplay() {
        #expect(height(screenSize: Self.outerPortrait) == 272)
        #expect(height(screenSize: Self.outerLandscape) == 198)
    }

    @Test("Unfolded inner display matches the system keyboard plus the banner")
    func unfoldedInnerDisplay() {
        #expect(height(screenSize: Self.innerPortrait) == 301)
        #expect(height(screenSize: Self.innerLandscape) == 267)
    }
}
