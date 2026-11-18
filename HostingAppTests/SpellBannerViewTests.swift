@testable import BaseKeyboard
import XCTest

final class SpellBannerViewTests: XCTestCase {
    private var window: UIWindow!
    private var sut: SpellBannerView!
    private var widthConstraint: NSLayoutConstraint!
    private let lightTraits = UITraitCollection(traitsFrom: [
        UITraitCollection(userInterfaceIdiom: .phone),
        UITraitCollection(userInterfaceStyle: .light)
    ])

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.isHidden = false
        sut = SpellBannerView(theme: Theme.current(for: lightTraits, device: .current))
        window.addSubview(sut)
        sut.topAnchor.constraint(equalTo: window.topAnchor).isActive = true
        sut.leftAnchor.constraint(equalTo: window.leftAnchor).isActive = true
        widthConstraint = sut.widthAnchor.constraint(equalToConstant: 390)
        widthConstraint.isActive = true
        sut.heightAnchor.constraint(equalToConstant: 48).isActive = true
        layout()
    }

    override func tearDown() {
        sut.removeFromSuperview()
        sut = nil
        window = nil
        super.tearDown()
    }

    // MARK: - Content

    func test_fewerThanThreeItems_padsWithEmptyCells() {
        sut.setBannerItems([human("hi", false)])
        layout()
        XCTAssertEqual(texts(), ["\"hi\"", "", ""])
    }

    func test_moreThanThreeItems_showsFirstThree() {
        sut.setBannerItems([human("a", false), normal("b"), normal("c"), normal("d")])
        layout()
        XCTAssertEqual(texts(), ["\"a\"", "b", "c"])
    }

    func test_clearSuggestions_emptiesAllCells() {
        sut.setBannerItems([human("hi", false), normal("ho")])
        layout()
        sut.clearSuggestions()
        layout()
        XCTAssertEqual(texts(), ["", "", ""])
    }

    func test_itemStyles() {
        sut.setBannerItems([human("hi", true), correction("ho"), normal("hu")])
        layout()
        let labels = cells().map { label(in: $0)?.attributedText }
        XCTAssertEqual(labels[0], "\"hi\"".bolden(substring: "hi"))
        XCTAssertEqual(labels[1], "ho".bolden(substring: "ho"))
        XCTAssertEqual(labels[2], NSAttributedString(string: "hu"))

        sut.setBannerItems([human("hi", false)])
        layout()
        XCTAssertEqual(label(in: cells()[0])?.attributedText, NSAttributedString(string: "\"hi\""))
    }

    func test_labelsUseThemeFontAndColor() {
        let theme = Theme.current(for: lightTraits, device: .current)
        sut.setBannerItems([human("hi", false), normal("ho")])
        layout()
        for cell in cells() {
            XCTAssertEqual(label(in: cell)?.textColor, theme.bannerTextColor)
            XCTAssertEqual(label(in: cell)?.font, theme.bannerFont)
        }
    }

    func test_updateTheme_appliesNewColors() {
        let dark = Theme.current(for: UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .phone),
            UITraitCollection(userInterfaceStyle: .dark)
        ]), device: .current)
        sut.updateTheme(dark)
        sut.setBannerItems([human("hi", false), normal("ho")])
        layout()
        XCTAssertEqual(collectionView.backgroundColor, dark.bannerBackgroundColor)
        for cell in cells() {
            XCTAssertEqual(label(in: cell)?.textColor, dark.bannerTextColor)
        }
    }

    func test_selectingItem_notifiesDelegate() {
        let delegate = DelegateSpy()
        sut.delegate = delegate
        sut.setBannerItems([human("hi", false), correction("ho")])
        layout()

        collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: IndexPath(item: 1, section: 0))
        XCTAssertEqual(delegate.selected, ["ho"])

        // Empty padding cells do nothing.
        collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: IndexPath(item: 2, section: 0))
        XCTAssertEqual(delegate.selected, ["ho"])
    }

    // MARK: - Sizes

    func test_cellsAreAtLeastAThirdOfTheWidth() {
        sut.setBannerItems([human("hi", false), normal("ho")])
        layout()
        XCTAssertEqual(frames(), [
            CGRect(x: 0, y: 0, width: 130, height: 48),
            CGRect(x: 131, y: 0, width: 130, height: 48),
            CGRect(x: 262, y: 0, width: 130, height: 48)
        ])
    }

    func test_longSuggestionsGetWiderCells() {
        sut.setBannerItems([human("extraordinarily", false), correction("extraordinarily long words"), normal("x")])
        layout()
        // Wider than the banner in total, so the last one is scrolled out of view.
        XCTAssertEqual(itemFrames(), [
            CGRect(x: 0, y: 0, width: 156, height: 48),
            CGRect(x: 157, y: 0, width: 239, height: 48),
            CGRect(x: 397, y: 0, width: 130, height: 48)
        ])
    }

    func test_longSuggestions_fitTheirTextWithAMarginEachSide() {
        let long = "extraordinarily long words"
        let margin = Theme.current(for: lightTraits, device: .current).bannerHorizontalMargin
        for items in [
            [human(long, false), normal("x")],
            [human(long, true), normal("x")],
            [human("x", false), correction(long)],
            [human("x", false), normal("y"), normal(long)]
        ] {
            sut.setBannerItems(items)
            layout()
            for cell in cells() {
                let label = try! XCTUnwrap(label(in: cell))
                let text = label.attributedText?.string ?? ""
                XCTAssertGreaterThanOrEqual(cell.frame.width, ceil(label.intrinsicContentSize.width) + margin * 2,
                                            "\(text) doesn't fit")
            }
        }
    }

    func test_sizesFollowItemsAcrossUpdates() {
        sut.setBannerItems([human("extraordinarily", false), correction("extraordinarily long words"), normal("x")])
        layout()
        sut.setBannerItems([human("hi", false), normal("ho")])
        layout()
        XCTAssertEqual(frames().map(\.width), [130, 130, 130])
    }

    func test_resizing_relaysOutCells() {
        sut.setBannerItems([human("hi", false), normal("ho")])
        layout()
        widthConstraint.constant = 600
        layout()
        XCTAssertEqual(frames().map(\.width), [200, 200, 200])
    }

    // MARK: - Repeated updates

    func test_repeatedUpdates_doNotAddConstraints() {
        sut.setBannerItems([human("hi", false), normal("ho")])
        layout()
        let before = constraintCounts()

        for word in ["a", "ab", "abc", "abcd", "abcde"] {
            sut.setBannerItems([human(word, false), normal(word + "x")])
            layout()
        }

        XCTAssertEqual(constraintCounts(), before)
    }

    func test_repeatedUpdates_keepTheSameLayout() {
        sut.setBannerItems([human("hi", false)])
        layout()
        let before = collectionView.collectionViewLayout

        for word in ["a", "ab", "abc"] {
            sut.setBannerItems([human(word, false)])
            layout()
        }

        XCTAssertTrue(collectionView.collectionViewLayout === before)
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

    private func cells() -> [UICollectionViewCell] {
        collectionView.indexPathsForVisibleItems.sorted().compactMap { collectionView.cellForItem(at: $0) }
    }

    private func texts() -> [String] {
        cells().map { label(in: $0)?.attributedText?.string ?? "" }
    }

    private func frames() -> [CGRect] {
        cells().map(\.frame)
    }

    /// Frames of all three items, including any scrolled out of view.
    private func itemFrames() -> [CGRect] {
        (0..<3).compactMap {
            collectionView.collectionViewLayout.layoutAttributesForItem(at: IndexPath(item: $0, section: 0))?.frame
        }
    }

    private func constraintCounts() -> [Int] {
        cells().map { $0.constraints.count + $0.contentView.constraints.count }
    }

    private func label(in cell: UICollectionViewCell) -> UILabel? {
        cell.contentView.subviews.compactMap { $0 as? UILabel }.first
    }

    private func human(_ word: String, _ isCorrect: Bool) -> SpellBannerItem {
        SpellBannerItem(title: .humanInput(word, isCorrect: isCorrect), value: word)
    }

    private func correction(_ word: String) -> SpellBannerItem {
        SpellBannerItem(title: .correction(word), value: word)
    }

    private func normal(_ word: String) -> SpellBannerItem {
        SpellBannerItem(title: .normal(word), value: word)
    }
}

private final class DelegateSpy: SpellBannerViewDelegate {
    var selected: [String] = []

    func didSelectBannerItem(_ banner: SpellBannerView, item: SpellBannerItem) {
        selected.append(item.value)
    }
}
