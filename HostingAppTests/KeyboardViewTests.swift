@testable import BaseKeyboard
import XCTest

final class KeyboardViewTests: XCTestCase {
    private var window: UIWindow!
    private var sut: KeyboardView!
    private var widthConstraint: NSLayoutConstraint!
    private let traits = UITraitCollection(userInterfaceIdiom: .phone)

    override func setUpWithError() throws {
        try super.setUpWithError()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.isHidden = false
        sut = KeyboardView(definition: try makeDefinition(), theme: Theme.current(for: traits))
        // Size the view with Auto Layout, as the keyboard does, so size changes go through `bounds`.
        sut.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(sut)
        sut.topAnchor.constraint(equalTo: window.topAnchor).isActive = true
        sut.leftAnchor.constraint(equalTo: window.leftAnchor).isActive = true
        sut.heightAnchor.constraint(equalToConstant: 216).isActive = true
        widthConstraint = sut.widthAnchor.constraint(equalToConstant: 390)
        widthConstraint.isActive = true
        layout()
    }

    override func tearDown() {
        sut.removeFromSuperview()
        sut = nil
        window = nil
        super.tearDown()
    }

    // MARK: - Pages show the right keys

    func test_initialPage_showsNormalKeys() {
        XCTAssertEqual(sut.page, .normal)
        XCTAssertEqual(inputLabels(), ["q", "w", "e", "a", "z"])
    }

    func test_shiftedPage_showsShiftedKeys() {
        sut.page = .shifted
        layout()
        XCTAssertEqual(inputLabels(), ["Q", "W", "E", "A", "Z"])
    }

    func test_capslockPage_showsShiftedKeys() {
        sut.page = .capslock
        layout()
        XCTAssertEqual(inputLabels(), ["Q", "W", "E", "A", "Z"])
    }

    func test_symbolPages_showSymbolKeys() {
        sut.page = .symbols1
        layout()
        XCTAssertEqual(inputLabels(), ["1", "2", "3"])

        sut.page = .symbols2
        layout()
        XCTAssertEqual(inputLabels(), ["[", "]", "{"])
    }

    func test_returningToNormalPage_showsNormalKeysAgain() {
        sut.page = .shifted
        layout()
        sut.page = .normal
        layout()
        XCTAssertEqual(inputLabels(), ["q", "w", "e", "a", "z"])
    }

    func test_changingPage_rebuildsKeys() {
        let before = keyViewIDs()
        sut.page = .shifted
        layout()
        XCTAssertTrue(Set(before).isDisjoint(with: keyViewIDs()))
    }

    // MARK: - Theme and size changes still apply

    func test_updateTheme_rebuildsKeysOnSamePage() {
        let before = keyViewIDs()
        sut.updateTheme(theme: Theme.current(for: traits))
        layout()
        XCTAssertEqual(sut.page, .normal)
        XCTAssertTrue(Set(before).isDisjoint(with: keyViewIDs()))
    }

    func test_resizing_relaysOutKeysToNewWidth() {
        widthConstraint.constant = 600
        layout()
        // The first row has three keys of width 1.
        let firstKey = collectionView.cellForItem(at: IndexPath(item: 0, section: 0))
        XCTAssertEqual(firstKey?.frame.width ?? 0, (600 - 1) / 3, accuracy: 0.5)
    }

    func test_resizing_rebuildsKeys() {
        let before = keyViewIDs()
        widthConstraint.constant = 600
        layout()
        XCTAssertTrue(Set(before).isDisjoint(with: keyViewIDs()))
    }

    // MARK: - Globe button

    func test_globeButton_coversKeyboardKey() {
        XCTAssertEqual(globeButtons().count, 1)
        XCTAssertEqual(globeButtons().first?.frame, keyboardKeyCell()?.frame)
    }

    func test_globeButton_survivesPageChanges() {
        for page: KeyboardPage in [.shifted, .shifted, .normal, .normal] {
            sut.page = page
            layout()
            XCTAssertEqual(globeButtons().count, 1, "after setting page to \(page)")
            XCTAssertEqual(globeButtons().first?.frame, keyboardKeyCell()?.frame)
        }
    }

    // MARK: - Redundant updates don't rebuild keys

    func test_settingSamePage_doesNotRebuildKeys() {
        let before = keyViewIDs()
        sut.page = .normal
        layout()
        XCTAssertEqual(keyViewIDs(), before)
    }

    func test_settingSameShiftedPage_doesNotRebuildKeys() {
        sut.page = .shifted
        layout()
        let before = keyViewIDs()
        sut.page = .shifted
        layout()
        XCTAssertEqual(keyViewIDs(), before)
        XCTAssertEqual(inputLabels(), ["Q", "W", "E", "A", "Z"])
    }

    func test_settingSameBounds_doesNotRebuildKeys() {
        let before = keyViewIDs()
        sut.bounds = sut.bounds
        layout()
        XCTAssertEqual(keyViewIDs(), before)
    }

    func test_movingWithoutResizing_doesNotRebuildKeys() {
        let before = keyViewIDs()
        sut.bounds = CGRect(origin: CGPoint(x: 0, y: 10), size: sut.bounds.size)
        layout()
        XCTAssertEqual(keyViewIDs(), before)
    }

    // MARK: - Helpers

    private var collectionView: UICollectionView {
        sut.subviews.compactMap { $0 as? UICollectionView }.first!
    }

    private func layout() {
        window.layoutIfNeeded()
        sut.layoutIfNeeded()
        collectionView.layoutIfNeeded()
    }

    private func keyViews() -> [KeyView] {
        collectionView.indexPathsForVisibleItems.sorted().compactMap {
            (collectionView.cellForItem(at: $0) as? KeyboardView.KeyCell)?.keyView
        }
    }

    private func keyViewIDs() -> [ObjectIdentifier] {
        keyViews().map(ObjectIdentifier.init)
    }

    /// Labels of the letter and symbol keys, excluding the system row.
    private func inputLabels() -> [String] {
        let inputSections = collectionView.numberOfSections - 1
        return collectionView.indexPathsForVisibleItems.sorted()
            .filter { $0.section < inputSections }
            .compactMap { (collectionView.cellForItem(at: $0) as? KeyboardView.KeyCell)?.keyView?.accessibilityLabel }
            .filter { $0.count == 1 }
    }

    private func globeButtons() -> [UIButton] {
        sut.subviews.compactMap { $0 as? UIButton }
    }

    private func keyboardKeyCell() -> UICollectionViewCell? {
        // `_keyboard` is the first key of the third row in the test layout.
        collectionView.cellForItem(at: IndexPath(item: 0, section: 2))
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
        return try KeyboardDefinition(fromRaw: raw, traits: traits)
    }
}
