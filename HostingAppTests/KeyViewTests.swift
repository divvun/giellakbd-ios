@testable import BaseKeyboard
import XCTest

final class KeyViewTests: XCTestCase {
    private let theme = Theme.current(for: UITraitCollection(traitsFrom: [
        UITraitCollection(userInterfaceIdiom: .phone),
        UITraitCollection(userInterfaceStyle: .light)
    ]))
    private var window: UIWindow!
    private var heightConstraint: NSLayoutConstraint!

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.isHidden = false
    }

    override func tearDown() {
        window = nil
        super.tearDown()
    }

    // MARK: - Key shape

    func test_regularKey_hasThemeBorderAndCorners() {
        let sut = makeKey(.input(key: "a", alternate: nil))
        assertShape(of: sut, borderColor: theme.borderColor)
    }

    func test_specialKey_hasSpecialKeyBorder() {
        let sut = makeKey(.backspace)
        assertShape(of: sut, borderColor: theme.specialKeyBorderColor)
    }

    func test_eachKindOfKey_hasItsShape() {
        let types: [KeyType] = [.input(key: "a", alternate: "1"), .spacebar(name: "space"), .returnkey(name: "return"),
                                .shift, .symbols, .keyboard, .comma, .fullStop, .spacer]
        for type in types {
            let sut = makeKey(type)
            assertShape(of: sut, borderColor: type.isSpecialKeyStyle ? theme.specialKeyBorderColor : theme.borderColor,
                        "\(type)")
        }
    }

    func test_afterResizing_keyKeepsItsShape() {
        let sut = makeKey(.input(key: "a", alternate: nil))
        heightConstraint.constant = 80
        layout(sut)
        assertShape(of: sut, borderColor: theme.borderColor)
    }

    func test_layout_doesNotResetTheShape() {
        // The shape never changes, so laying out again (on every resize or touch) shouldn't redo it.
        let sut = makeKey(.input(key: "a", alternate: nil))
        sut.contentView.layer.borderWidth = 5
        heightConstraint.constant = 80
        layout(sut)
        XCTAssertEqual(sut.contentView.layer.borderWidth, 5)
    }

    // MARK: - Swipe keys

    func test_swipeKey_altLabelStartsAtTheThemePosition() throws {
        let sut = makeKey(.input(key: "a", alternate: "1"))
        XCTAssertEqual(try XCTUnwrap(sut.swipeLayoutConstraint).constant, theme.altLabelTopAnchorConstant)
    }

    func test_swipeKey_altLabelMovesWithTheSwipe() throws {
        let sut = makeKey(.input(key: "a", alternate: "1"))
        sut.percentageAlternative = 0.5
        XCTAssertEqual(try XCTUnwrap(sut.swipeLayoutConstraint).constant,
                       theme.altLabelTopAnchorConstant + sut.frame.height / 6.5 * 0.5, accuracy: 0.001)
    }

    func test_swipeKey_midSwipe_altLabelFollowsTheKeysNewHeight() throws {
        let sut = makeKey(.input(key: "a", alternate: "1"))
        sut.percentageAlternative = 0.5
        heightConstraint.constant = 80
        layout(sut)
        XCTAssertEqual(sut.frame.height, 80)
        XCTAssertEqual(try XCTUnwrap(sut.swipeLayoutConstraint).constant,
                       theme.altLabelTopAnchorConstant + 80 / 6.5 * 0.5, accuracy: 0.001)
    }

    func test_swipeKey_midSwipe_labelsKeepTheirSwipeStyleAfterLayout() throws {
        let sut = makeKey(.input(key: "a", alternate: "1"))
        sut.percentageAlternative = 0.5
        let before = labelStyles(in: sut)
        heightConstraint.constant = 80
        layout(sut)
        XCTAssertEqual(labelStyles(in: sut), before)
        XCTAssertNotEqual(before, labelStyles(in: makeKey(.input(key: "a", alternate: "1"))),
                          "test assumes swiping changes the labels")
    }

    // MARK: - Helpers

    private func makeKey(_ type: KeyType) -> KeyView {
        let sut = KeyView(page: .normal, key: KeyDefinition(type: type), theme: theme,
                          traits: UITraitCollection(userInterfaceIdiom: .phone))
        sut.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(sut)
        heightConstraint = sut.heightAnchor.constraint(equalToConstant: 54)
        NSLayoutConstraint.activate([
            sut.topAnchor.constraint(equalTo: window.topAnchor),
            sut.leftAnchor.constraint(equalTo: window.leftAnchor),
            sut.widthAnchor.constraint(equalToConstant: 40),
            heightConstraint
        ])
        layout(sut)
        return sut
    }

    private func layout(_ sut: KeyView) {
        window.layoutIfNeeded()
        sut.layoutIfNeeded()
    }

    private func assertShape(of sut: KeyView, borderColor: UIColor, _ message: String = "",
                             file: StaticString = #filePath, line: UInt = #line) {
        let layer = sut.contentView.layer
        XCTAssertEqual(layer.borderWidth, 1, message, file: file, line: line)
        XCTAssertEqual(layer.borderColor, borderColor.cgColor, message, file: file, line: line)
        XCTAssertEqual(layer.cornerRadius, theme.keyCornerRadius, message, file: file, line: line)
        XCTAssertTrue(sut.contentView.clipsToBounds, message, file: file, line: line)
    }

    private func labelStyles(in sut: KeyView) -> [String] {
        labels(in: sut).map { "\($0.text ?? "") \($0.font.pointSize) \($0.textColor.description)" }
    }

    private func labels(in view: UIView) -> [UILabel] {
        view.subviews.flatMap { subview -> [UILabel] in
            (subview as? UILabel).map { [$0] } ?? labels(in: subview)
        }
        .sorted { ($0.text ?? "") < ($1.text ?? "") }
    }
}
