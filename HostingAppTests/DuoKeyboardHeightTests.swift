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

    private func height(screenSize: CGSize, design: KeyboardDesign = .iOS26) -> CGFloat {
        let context = DeviceContext(device: .iPhoneDuo,
                                    isLandscape: screenSize.width > screenSize.height,
                                    screenSize: screenSize)
        return KeyboardHeightProvider.height(for: context, traitCollection: phoneTraits, design: design)
    }

    @Test("Folded outer display uses the system keyboard's key sizes plus the banner")
    func foldedOuterDisplay() {
        #expect(abs(height(screenSize: Self.outerPortrait) - (44 + 8 + 4 * 45 + 3 * 11 + 20.0 / 3)) < 0.001)
        #expect(abs(height(screenSize: Self.outerLandscape) - (44 + 6 + 4 * 100.0 / 3 + 3 * 9 + 4)) < 0.001)
    }

    @Test("Before iOS 26, the folded outer display uses the 5.4 inch phone heights")
    func foldedOuterDisplayBeforeIOS26() {
        #expect(height(screenSize: Self.outerPortrait, design: .iOS18) == 272)
        #expect(height(screenSize: Self.outerLandscape, design: .iOS18) == 198)
    }

    @Test("Unfolded inner display uses the system keyboard's key sizes plus the banner")
    func unfoldedInnerDisplay() {
        let portrait: CGFloat = 38 + 8 + 4 * 46 + 3 * 14 + 3
        let landscape: CGFloat = 38 + 6 + 4 * 39 + 3 * 13 + 4
        #expect(abs(height(screenSize: Self.innerPortrait, design: .iOS26) - portrait) < 0.001)
        #expect(abs(height(screenSize: Self.innerLandscape, design: .iOS26) - landscape) < 0.001)
    }

    @Test("Before iOS 26, the unfolded inner display uses its own height")
    func unfoldedInnerDisplayBeforeIOS26() {
        #expect(height(screenSize: Self.innerPortrait, design: .iOS18) == 301)
        #expect(height(screenSize: Self.innerLandscape, design: .iOS18) == 267)
    }
}
