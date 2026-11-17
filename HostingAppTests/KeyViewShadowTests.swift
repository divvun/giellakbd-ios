@testable import BaseKeyboard
import XCTest

/// iOS 26 themes have no key shadow. A shadow with any opacity still makes Core Animation render
/// every key offscreen to find its shape, so keys must not have one at all.
final class KeyViewShadowTests: XCTestCase {
    private var window: UIWindow!
    private var sut: KeyboardView!
    private var widthConstraint: NSLayoutConstraint!

    override func setUpWithError() throws {
        try super.setUpWithError()
        try XCTSkipUnless(iOSVersion.isIOS26OrNewer, "Only iOS 26 themes have no key shadow")
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.isHidden = false
    }

    override func tearDown() {
        sut?.removeFromSuperview()
        sut = nil
        window = nil
        super.tearDown()
    }

    func test_lightTheme_keysHaveNoShadow() throws {
        let theme = Theme.current(for: traits(.light))
        XCTAssertEqual(theme.keyShadowColor.cgColor.alpha, 0, "test assumes the iOS 26 light theme has no shadow")
        try makeKeyboard(theme: theme)
        assertNoKeyShadows()
    }

    func test_darkTheme_keysHaveNoShadow() throws {
        let theme = Theme.current(for: traits(.dark))
        XCTAssertEqual(theme.keyShadowColor.cgColor.alpha, 0, "test assumes the iOS 26 dark theme has no shadow")
        try makeKeyboard(theme: theme)
        assertNoKeyShadows()
    }

    func test_afterThemeChange_keysHaveNoShadow() throws {
        try makeKeyboard(theme: Theme.current(for: traits(.light)))
        sut.updateTheme(theme: Theme.current(for: traits(.dark)))
        layout()
        assertNoKeyShadows()
    }

    func test_afterPageChange_keysHaveNoShadow() throws {
        try makeKeyboard(theme: Theme.current(for: traits(.light)))
        sut.page = .shifted
        layout()
        assertNoKeyShadows()
    }

    func test_afterResize_keysHaveNoShadow() throws {
        try makeKeyboard(theme: Theme.current(for: traits(.light)))
        widthConstraint.constant = 600
        layout()
        assertNoKeyShadows()
    }

    // MARK: - Helpers

    private func traits(_ style: UIUserInterfaceStyle) -> UITraitCollection {
        UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .phone),
            UITraitCollection(userInterfaceStyle: style)
        ])
    }

    private func makeKeyboard(theme: Theme) throws {
        sut = KeyboardView(definition: try makeDefinition(), theme: theme)
        sut.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(sut)
        sut.topAnchor.constraint(equalTo: window.topAnchor).isActive = true
        sut.leftAnchor.constraint(equalTo: window.leftAnchor).isActive = true
        sut.heightAnchor.constraint(equalToConstant: 216).isActive = true
        widthConstraint = sut.widthAnchor.constraint(equalToConstant: 390)
        widthConstraint.isActive = true
        layout()
    }

    private func layout() {
        window.layoutIfNeeded()
        sut.layoutIfNeeded()
        collectionView.layoutIfNeeded()
    }

    private var collectionView: UICollectionView {
        sut.subviews.compactMap { $0 as? UICollectionView }.first!
    }

    private func keyViews() -> [KeyView] {
        collectionView.indexPathsForVisibleItems.sorted().compactMap {
            (collectionView.cellForItem(at: $0) as? KeyboardView.KeyCell)?.keyView
        }
    }

    private func assertNoKeyShadows(file: StaticString = #filePath, line: UInt = #line) {
        let keys = keyViews()
        XCTAssertFalse(keys.isEmpty, "no keys laid out", file: file, line: line)
        for key in keys {
            XCTAssertEqual(key.layer.shadowOpacity, 0, "key \(key.accessibilityLabel ?? "?")", file: file, line: line)
        }
    }

    private func makeDefinition() throws -> KeyboardDefinition {
        let json = """
        {
            "name": "Test",
            "locale": "tt",
            "space": "space",
            "return": "return",
            "iphone": {
                "normal": [["q", "w", "e"], ["_shift", "a", "_backspace"], ["_keyboard", "z"]],
                "shifted": [["Q", "W", "E"], ["_shift", "A", "_backspace"], ["_keyboard", "Z"]],
                "symbols-1": [["1", "2", "3"]],
                "symbols-2": [["[", "]", "{"]]
            }
        }
        """
        let raw = try JSONDecoder().decode(RawKeyboardDefinition.self, from: Data(json.utf8))
        return try KeyboardDefinition(fromRaw: raw, traits: UITraitCollection(userInterfaceIdiom: .phone))
    }
}
