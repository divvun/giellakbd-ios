@testable import BaseKeyboard
import XCTest

/// From iOS 26, scroll views blur and fade content near their edges. The keyboard's collection views are small and
/// their content sits right against the edges, so the effect blurred the keys, popups and suggestions themselves.
final class ScrollEdgeEffectTests: XCTestCase {
    private let traits = UITraitCollection(userInterfaceIdiom: .phone)
    private lazy var theme = Theme.current(for: traits, device: .current)

    override func setUpWithError() throws {
        try super.setUpWithError()
        try XCTSkipUnless(iOSVersion.isIOS26OrNewer, "Scroll edge effects only exist from iOS 26")
    }

    func test_keyboard_hasNoEdgeEffects() throws {
        let keyboard = KeyboardView(definition: try makeDefinition(), theme: theme)
        let collectionView = try XCTUnwrap(keyboard.subviews.compactMap { $0 as? UICollectionView }.first)
        assertNoEdgeEffects(collectionView)
    }

    func test_longPressPopup_hasNoEdgeEffects() throws {
        let key = KeyDefinition(type: .input(key: "a", alternate: nil))
        let sut = LongPressOverlayController(key: key, page: .normal, theme: theme,
                                             longpressValues: [key, KeyDefinition(type: .input(key: "á", alternate: nil))])
        let delegate = OverlayDelegateSpy()
        sut.delegate = delegate
        sut.touchesBegan(.zero)
        assertNoEdgeEffects(try XCTUnwrap(delegate.contentView as? UICollectionView))
    }

    func test_spellBanner_hasNoEdgeEffects() throws {
        let banner = SpellBannerView(theme: theme)
        assertNoEdgeEffects(try XCTUnwrap(banner.subviews.compactMap { $0 as? UICollectionView }.first))
    }

    func test_spellBanner_afterThemeChange_hasNoEdgeEffects() throws {
        // A theme change replaces the collection view.
        let banner = SpellBannerView(theme: theme)
        banner.updateTheme(Theme.current(for: UITraitCollection(traitsFrom: [traits, UITraitCollection(userInterfaceStyle: .dark)]),
                                         device: .current))
        assertNoEdgeEffects(try XCTUnwrap(banner.subviews.compactMap { $0 as? UICollectionView }.first))
    }

    // MARK: - Helpers

    private func assertNoEdgeEffects(_ scrollView: UIScrollView, file: StaticString = #filePath, line: UInt = #line) {
        guard #available(iOS 26.0, *) else { return }
        XCTAssertTrue(scrollView.topEdgeEffect.isHidden, "top", file: file, line: line)
        XCTAssertTrue(scrollView.leftEdgeEffect.isHidden, "left", file: file, line: line)
        XCTAssertTrue(scrollView.bottomEdgeEffect.isHidden, "bottom", file: file, line: line)
        XCTAssertTrue(scrollView.rightEdgeEffect.isHidden, "right", file: file, line: line)
    }

    private func makeDefinition() throws -> KeyboardDefinition {
        let json = """
        {
            "name": "Test",
            "locale": "tt",
            "space": "space",
            "return": "return",
            "iphone": {
                "normal": [["q", "w", "e"], ["_shift", "a", "_backspace"]],
                "shifted": [["Q", "W", "E"], ["_shift", "A", "_backspace"]],
                "symbols-1": [["1", "2", "3"]],
                "symbols-2": [["[", "]", "{"]]
            }
        }
        """
        let raw = try JSONDecoder().decode(RawKeyboardDefinition.self, from: Data(json.utf8))
        return try KeyboardDefinition(fromRaw: raw, traits: traits, needsInputModeSwitchKey: false)
    }
}

private final class OverlayDelegateSpy: LongPressOverlayDelegate {
    var contentView: UIView?

    func longpress(didCreateOverlayContentView contentView: UIView) {
        self.contentView = contentView
    }

    func longpressDidCancel() {}
    func longpress(didSelectKey key: KeyDefinition) {}
    func longpressFrameOfReference() -> CGRect { CGRect(x: 0, y: 0, width: 390, height: 216) }
    func longpressKeySize() -> CGSize { CGSize(width: 40, height: 54) }
}
