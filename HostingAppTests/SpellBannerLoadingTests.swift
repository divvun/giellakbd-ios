@testable import BaseKeyboard
import DivvunSpell
import XCTest

final class SpellBannerLoadingTests: XCTestCase {
    private let locale = KeyboardLocale(identifier: "se", languageName: "North Sámi")
    private var window: UIWindow!
    private var sut: SpellBanner!

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.isHidden = false
        // The test host has no speller configured, so this initial load finds nothing.
        sut = SpellBanner(theme: Theme.current(for: UITraitCollection(userInterfaceIdiom: .phone)))
    }

    override func tearDown() {
        sut.view.removeFromSuperview()
        sut = nil
        window = nil
        super.tearDown()
    }

    func test_loadedSpeller_isPutInUseOnTheMainThread() throws {
        let loaded = expectation(description: "loaded")
        sut.spellerDidLoad = {
            XCTAssertTrue(Thread.isMainThread)
            loaded.fulfill()
        }
        sut.loadSpeller(from: try spellerURL(), locale: { self.locale })
        wait(for: [loaded], timeout: 10)
    }

    func test_afterLoading_suggestionsAppear() throws {
        try loadSpeller()
        showBanner()

        sut.updateSuggestions(try CursorContext.from(leftPart: "xqzwv", rightPart: ""))

        let shown = expectation(for: NSPredicate { _, _ in self.texts().first == "\"xqzwv\"" }, evaluatedWith: nil)
        wait(for: [shown], timeout: 5)
    }

    func test_missingSpeller_isNotLoaded() {
        let loaded = expectation(description: "loaded")
        loaded.isInverted = true
        sut.spellerDidLoad = { loaded.fulfill() }
        sut.loadSpeller(from: URL(fileURLWithPath: "/nonexistent/se.bhfst"), locale: { self.locale })
        wait(for: [loaded], timeout: 1)
    }

    // MARK: - Helpers

    private func spellerURL() throws -> URL {
        let bundle = try XCTUnwrap(Bundle(for: type(of: self)).url(forResource: "dicts", withExtension: "bundle"))
        return bundle.appendingPathComponent("se.bhfst")
    }

    private func loadSpeller() throws {
        let loaded = expectation(description: "loaded")
        sut.spellerDidLoad = { loaded.fulfill() }
        sut.loadSpeller(from: try spellerURL(), locale: { self.locale })
        wait(for: [loaded], timeout: 10)
    }

    private func showBanner() {
        let view = sut.view
        view.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: window.topAnchor),
            view.leftAnchor.constraint(equalTo: window.leftAnchor),
            view.widthAnchor.constraint(equalToConstant: 390),
            view.heightAnchor.constraint(equalToConstant: 48)
        ])
        window.layoutIfNeeded()
    }

    private func texts() -> [String] {
        window.layoutIfNeeded()
        guard let collectionView = sut.view.subviews.compactMap({ $0 as? UICollectionView }).first else {
            return []
        }
        collectionView.layoutIfNeeded()
        return collectionView.indexPathsForVisibleItems.sorted().compactMap {
            collectionView.cellForItem(at: $0)?.contentView.subviews.compactMap { $0 as? UILabel }.first?.attributedText?.string
        }
    }
}
