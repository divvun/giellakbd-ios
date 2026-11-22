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
        sut = KeyboardView(definition: try makeDefinition(), theme: Theme.current(for: traits, device: .current))
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
        sut.updateTheme(theme: Theme.current(for: traits, device: .current))
        layout()
        XCTAssertEqual(sut.page, .normal)
        XCTAssertTrue(Set(before).isDisjoint(with: keyViewIDs()))
    }

    func test_resizing_relaysOutKeysToNewWidth() {
        widthConstraint.constant = 600
        layout()
        // The first row has three keys of width 1. The first key's cell also takes the side inset.
        let sideInset = Theme.current(for: traits, device: .current).keyArea.sideInset
        let firstKey = collectionView.cellForItem(at: IndexPath(item: 0, section: 0))
        XCTAssertEqual(firstKey?.frame.width ?? 0, (600 - 2 * sideInset) / 3 + sideInset, accuracy: 0.5)
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

    // MARK: - Row layout

    private let phoneKeys = KeyAreaMetrics(keyHeight: 43, rowGap: 11, topInset: 8, bottomInset: 0)
    private let numberRowKeys = KeyAreaMetrics(keyHeight: 61, numberRowKeyHeight: 45.5, rowGap: 7, topInset: 8,
                                               bottomInset: 4)

    func test_rowLayout_rowsFillTheKeyArea_forEveryRowCount() {
        for rowCount in [3, 4, 5, 6] {
            let height = phoneKeys.height(rowCount: rowCount)
            let sut = KeyRowLayout(metrics: phoneKeys, rowCount: rowCount, height: height, scale: 3)
            XCTAssertEqual(totalHeight(sut, rowCount: rowCount), height, accuracy: 0.001, "\(rowCount) rows")
            XCTAssertEqual(sut.keyHeights, Array(repeating: 43, count: rowCount), "\(rowCount) rows")
        }
    }

    func test_rowLayout_keyEdgesAreOnWholePixels() {
        // Fitted key areas share a height between the rows, which gives fractional key heights.
        let fitted = KeyAreaMetrics(keyHeight: 42.25, rowGap: 11, topInset: 5.5, bottomInset: 5.5)
        for scale: CGFloat in [2, 3] {
            let sut = KeyRowLayout(metrics: fitted, rowCount: 4, height: 214, scale: scale)
            for edge in keyEdges(sut, rowCount: 4) {
                XCTAssertEqual((edge * scale).rounded(), edge * scale, accuracy: 0.0001, "edge \(edge) at \(scale)x")
            }
            XCTAssertLessThanOrEqual(totalHeight(sut, rowCount: 4), 214 + 0.001)
        }
    }

    func test_rowLayout_putsSpareHeightAboveTheTopRow() {
        let sut = KeyRowLayout(metrics: phoneKeys, rowCount: 4, height: 220, scale: 3)
        XCTAssertEqual(sut.keyHeights, [43, 43, 43, 43])
        XCTAssertEqual(sut.topInset, 15)
        XCTAssertEqual(sut.bottomInset, 0)
    }

    func test_rowLayout_shrinksKeysToFit_whenTheAreaIsTooShort() {
        let sut = KeyRowLayout(metrics: phoneKeys, rowCount: 5, height: 200, scale: 3)
        XCTAssertEqual(Set(sut.keyHeights).count, 1, "rows keep equal heights")
        XCTAssertLessThan(sut.keyHeights[0], 43)
        XCTAssertLessThanOrEqual(totalHeight(sut, rowCount: 5), 200 + 0.001)
        XCTAssertEqual(sut.bottomInset, 0)
    }

    func test_rowLayout_numberRowIsShorter_onLayoutsWithANumberRow() {
        let height = numberRowKeys.height(rowCount: 5, startsWithNumberRow: true)
        let sut = KeyRowLayout(metrics: numberRowKeys, rowCount: 5, startsWithNumberRow: true, height: height, scale: 2)
        XCTAssertEqual(sut.keyHeights, [45.5, 61, 61, 61, 61])
        XCTAssertEqual(sut.topInset, 8)
        XCTAssertTrue(sut.hasShortNumberRow)
    }

    func test_rowLayout_numberRowStaysShorter_whenKeysShrink() {
        let sut = KeyRowLayout(metrics: numberRowKeys, rowCount: 6, startsWithNumberRow: true, height: 380, scale: 2)
        XCTAssertLessThan(sut.keyHeights[0], sut.keyHeights[1])
        XCTAssertEqual(Set(sut.keyHeights.dropFirst()).count, 1)
        XCTAssertLessThanOrEqual(totalHeight(sut, rowCount: 6), 380 + 0.001)
    }

    func test_rowLayout_aNumberRowOnItsOwn_isFullHeight() {
        // Neither the short keys nor, through hasShortNumberRow, the number row's font.
        let height = numberRowKeys.height(rowCount: 1, startsWithNumberRow: true)
        let sut = KeyRowLayout(metrics: numberRowKeys, rowCount: 1, startsWithNumberRow: true, height: height, scale: 2)
        XCTAssertEqual(sut.keyHeights, [61])
        XCTAssertFalse(sut.hasShortNumberRow)
    }

    func test_rowLayout_everyRowIsFullHeight_withoutANumberRow() {
        // Some 13-inch iPad layouts, such as Kildin Sami's, put letters where the number row usually is.
        let sut = KeyRowLayout(metrics: numberRowKeys, rowCount: 5, height: numberRowKeys.height(rowCount: 5), scale: 2)
        XCTAssertEqual(sut.keyHeights, [61, 61, 61, 61, 61])
        XCTAssertFalse(sut.hasShortNumberRow)
    }

    func test_startsWithNumberRow_whenMostOfTheFirstRowIsDigits() {
        func rows(_ first: [String]) -> [[KeyDefinition]] {
            [first.map { KeyDefinition(type: .input(key: $0, alternate: nil)) } + [KeyDefinition(type: .backspace)],
             [KeyDefinition(type: .input(key: "q", alternate: nil))]]
        }
        XCTAssertTrue(rows(["'", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "+", "´"]).startsWithNumberRow)
        XCTAssertFalse(rows(["а̄", "я̄", "ӯ", "ю̄", "е̄", "о̄", "ӣ", "э̄", "ӭ", "ӓ", "ҍ", "ъ"]).startsWithNumberRow)
        XCTAssertFalse(rows(["q", "w", "e", "1"]).startsWithNumberRow)
    }

    func test_bottomRowKeys_endAtTheKeyAreaInset() {
        let theme = Theme.current(for: traits, device: .current)
        let lastRow = collectionView.numberOfSections - 1
        let frame = keyFrame(at: IndexPath(item: 1, section: lastRow))
        XCTAssertEqual(frame.maxY, sut.bounds.maxY - theme.keyArea.bottomInset, accuracy: 0.5)
    }

    func test_keys_areOnWholePixels() {
        let scale = sut.traitCollection.displayScale
        for section in 0..<collectionView.numberOfSections {
            let frame = keyFrame(at: IndexPath(item: 0, section: section))
            for edge in [frame.minY, frame.maxY] {
                XCTAssertEqual((edge * scale).rounded(), edge * scale, accuracy: 0.01, "row \(section) edge \(edge)")
            }
        }
    }

    func test_outerKeys_areInsetFromTheEdges_butTheirCellsReachThem() throws {
        let theme = Theme.current(for: traits, device: .current)
        let row = collectionView.numberOfItems(inSection: 0)
        let first = try XCTUnwrap(collectionView.cellForItem(at: IndexPath(item: 0, section: 0)))
        let last = try XCTUnwrap(collectionView.cellForItem(at: IndexPath(item: row - 1, section: 0)))

        XCTAssertEqual(first.frame.minX, 0, accuracy: 0.5)
        XCTAssertEqual(keyFrame(at: IndexPath(item: 0, section: 0)).minX,
                       theme.keyHorizontalMargin + theme.keyArea.sideInset, accuracy: 0.5)
        XCTAssertEqual(last.frame.maxX, sut.bounds.maxX, accuracy: 1)
        XCTAssertEqual(keyFrame(at: IndexPath(item: row - 1, section: 0)).maxX,
                       last.frame.maxX - theme.keyHorizontalMargin - theme.keyArea.sideInset, accuracy: 0.5)
    }

    private func keyFrame(at indexPath: IndexPath) -> CGRect {
        let cell = collectionView.cellForItem(at: indexPath) as? KeyboardView.KeyCell
        let key = cell?.keyView?.contentView
        return key.map { $0.convert($0.bounds, to: sut) } ?? .null
    }

    private func totalHeight(_ layout: KeyRowLayout, rowCount: Int) -> CGFloat {
        (0..<rowCount).map { layout.height(ofRow: $0) }.reduce(0, +)
    }

    /// The top and bottom edge of every row's keys, measured from the top of the key area.
    private func keyEdges(_ layout: KeyRowLayout, rowCount: Int) -> [CGFloat] {
        var rowTop: CGFloat = 0
        var edges: [CGFloat] = []
        for row in 0..<rowCount {
            let keyTop = rowTop + layout.keyMargins(forRow: row).top
            edges += [keyTop, keyTop + layout.keyHeights[row]]
            rowTop += layout.height(ofRow: row)
        }
        return edges
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
        return try KeyboardDefinition(fromRaw: raw, traits: traits, needsInputModeSwitchKey: false)
    }
}
