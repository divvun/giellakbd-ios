@testable import BaseKeyboard
import DeviceKit
import XCTest

final class KeyboardViewControllerTests: XCTestCase {
    // These tests cover the height table, which sets the keyboard's height before iOS 26 and on devices whose
    // system keyboard hasn't been measured.
    // MARK: - Landscape Height Tests

    func testLandscapeHeight_iPadMini_7_9Inch() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .pad),
            UITraitCollection(horizontalSizeClass: .regular)
        ])

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPadMini5, isLandscape: true),
            traitCollection: traitCollection,
            legacy: true
        )
        XCTAssertEqual(height, 404, "iPad Mini 7.9\" should return 404 in landscape")
    }

    func testLandscapeHeight_iPad_9_7Inch() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .pad),
            UITraitCollection(horizontalSizeClass: .regular)
        ])

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPadPro9Inch, isLandscape: true),
            traitCollection: traitCollection,
            legacy: true
        )
        XCTAssertEqual(height, 404, "iPad 9.7\" should return 404 in landscape")
    }

    func testLandscapeHeight_iPad_10_5Inch() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .pad),
            UITraitCollection(horizontalSizeClass: .regular)
        ])

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPadPro10Inch, isLandscape: true),
            traitCollection: traitCollection,
            legacy: true
        )
        XCTAssertEqual(height, 404, "iPad 10.5\" should return 404 in landscape")
    }

    func testLandscapeHeight_iPad_11Inch() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .pad),
            UITraitCollection(horizontalSizeClass: .regular)
        ])

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPadPro11Inch, isLandscape: true),
            traitCollection: traitCollection,
            legacy: true
        )
        XCTAssertEqual(height, 404, "iPad 11\" should return 404 in landscape")
    }

    func testLandscapeHeight_iPad_12_9Inch() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .pad),
            UITraitCollection(horizontalSizeClass: .regular)
        ])

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPadPro12Inch, isLandscape: true),
            traitCollection: traitCollection,
            legacy: true
        )
        XCTAssertEqual(height, 476, "iPad 12.9\" should return 476 in landscape")
    }

    func testLandscapeHeight_iPhone_4_7Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhone8, isLandscape: true),
            traitCollection: traitCollection,
            legacy: true
        )
        XCTAssertEqual(height, 208, "iPhone 4.7\" should return 208 in landscape")
    }

    func testLandscapeHeight_iPhone_5_5Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhone8Plus, isLandscape: true),
            traitCollection: traitCollection,
            legacy: true
        )
        XCTAssertEqual(height, 208, "iPhone 5.5\" should return 208 in landscape")
    }

    func testLandscapeHeight_iPhone_5_8Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhoneX, isLandscape: true),
            traitCollection: traitCollection,
            legacy: true
        )
        XCTAssertEqual(height, 196, "iPhone 5.8\" should return 196 in landscape")
    }

    func testLandscapeHeight_iPhone_6_1Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhone11, isLandscape: true),
            traitCollection: traitCollection,
            legacy: true
        )
        XCTAssertEqual(height, 206, "iPhone 6.1\" should return 206 in landscape")
    }

    func testLandscapeHeight_iPhoneXSMax() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhoneXSMax, isLandscape: true),
            traitCollection: traitCollection,
            legacy: true
        )
        XCTAssertEqual(height, 196, "iPhone XS Max should return 196 in landscape (device override)")
    }

    func testLandscapeHeight_iPhone11ProMax() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhone11ProMax, isLandscape: true),
            traitCollection: traitCollection,
            legacy: true
        )
        XCTAssertEqual(height, 196, "iPhone 11 Pro Max should return 196 in landscape (device override)")
    }

    // MARK: - Portrait Height Tests

    func testPortraitHeight_iPhone_4_7Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhone8, isLandscape: false),
            traitCollection: traitCollection,
            legacy: true
        )
        XCTAssertEqual(height, 262, "iPhone 4.7\" should return 262 in portrait")
    }

    func testPortraitHeight_iPhone_5_5Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhone8Plus, isLandscape: false),
            traitCollection: traitCollection,
            legacy: true
        )
        XCTAssertEqual(height, 272, "iPhone 5.5\" should return 272 in portrait")
    }

    func testPortraitHeight_iPhone_5_8Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhoneX, isLandscape: false),
            traitCollection: traitCollection,
            legacy: true
        )
        XCTAssertEqual(height, 262, "iPhone 5.8\" should return 262 in portrait")
    }

    func testPortraitHeight_iPhone_6_1Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhone11, isLandscape: false),
            traitCollection: traitCollection,
            legacy: true
        )
        XCTAssertEqual(height, 262, "iPhone 6.1\" should return 262 in portrait")
    }

    func testPortraitHeight_iPhoneXSMax() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhoneXSMax, isLandscape: false),
            traitCollection: traitCollection,
            legacy: true
        )
        XCTAssertEqual(height, 272, "iPhone XS Max should return 272 in portrait (device override)")
    }

    func testPortraitHeight_iPhone11ProMax() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhone11ProMax, isLandscape: false),
            traitCollection: traitCollection,
            legacy: true
        )
        XCTAssertEqual(height, 272, "iPhone 11 Pro Max should return 272 in portrait (device override)")
    }

    func testPortraitHeight_iPad_7_9Inch() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .pad),
            UITraitCollection(horizontalSizeClass: .regular)
        ])

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPadMini5, isLandscape: false),
            traitCollection: traitCollection,
            legacy: true
        )
        XCTAssertEqual(height, 318, "iPad 7.9\" should return 318 in portrait")
    }

    func testPortraitHeight_iPad_9_7Inch() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .pad),
            UITraitCollection(horizontalSizeClass: .regular)
        ])

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPadPro9Inch, isLandscape: false),
            traitCollection: traitCollection,
            legacy: true
        )
        XCTAssertEqual(height, 318, "iPad 9.7\" should return 318 in portrait")
    }

    func testPortraitHeight_iPad_11Inch() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .pad),
            UITraitCollection(horizontalSizeClass: .regular)
        ])

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPadPro11Inch, isLandscape: false),
            traitCollection: traitCollection,
            legacy: true
        )
        XCTAssertEqual(height, 318, "iPad 11\" should return 318 in portrait")
    }

    func testPortraitHeight_iPad_12_9Inch() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .pad),
            UITraitCollection(horizontalSizeClass: .regular)
        ])

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPadPro12Inch, isLandscape: false),
            traitCollection: traitCollection,
            legacy: true
        )
        XCTAssertEqual(height, 384, "iPad 12.9\" should return 384 in portrait")
    }

    // MARK: - iPad Compatibility Mode Tests

//    func testCompatibilityMode_iPadRunningIPhoneApp_SmallIPad() {
//        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)
//
//        // Simulate iPad Mini running iPhone app
//        let height = KeyboardHeightProvider.height(
//            for: DeviceContext(device: .iPadMini5, isLandscape: true),
//            traitCollection: traitCollection,
//            isLandscape: false
//        )
//        XCTAssertEqual(height, 258, "iPad ≤11\" in compatibility mode should return 258 in portrait")
//    }
//
//    func testCompatibilityMode_iPadRunningIPhoneApp_LargeIPad() {
//        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)
//
//        // Simulate iPad Pro 12.9" running iPhone app
//        let height = KeyboardHeightProvider.height(
//            for: DeviceContext(device: .iPadPro12Inch, isLandscape: true),
//            traitCollection: traitCollection,
//            isLandscape: false
//        )
//        XCTAssertEqual(height, 328, "iPad >11\" in compatibility mode should return 328 in portrait")
//    }

    // MARK: - Row Count Adjustment Tests

    func testRowCountAdjustment_StandardKeyboard() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        // Standard 4-row keyboard
        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhone8, isLandscape: false),
            traitCollection: traitCollection,
            rowCount: 4,
            legacy: true
        )
        XCTAssertEqual(height, 262, "Standard 4-row keyboard should return base height")
    }

    func testRowCountAdjustment_ExtraRows() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        // 5-row keyboard should be taller
        let height4Row = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhone8, isLandscape: false),
            traitCollection: traitCollection,
            rowCount: 4,
            legacy: true
        )

        let height5Row = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhone8, isLandscape: false),
            traitCollection: traitCollection,
            rowCount: 5,
            legacy: true
        )

        XCTAssertGreaterThan(height5Row, height4Row, "5-row keyboard should be taller than 4-row")
    }

    func testRowCountAdjustment_iPad12Inch() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .pad),
            UITraitCollection(horizontalSizeClass: .regular)
        ])

        // iPad 12"+ uses 5 rows as normal
        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPadPro12Inch, isLandscape: false),
            traitCollection: traitCollection,
            rowCount: 5,
            legacy: true
        )
        XCTAssertEqual(height, 384, "iPad 12\" with 5 rows should return base height")
    }

    func testRowCountAdjustment_SmallIPadLandscape_ManyRows() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .pad),
            UITraitCollection(horizontalSizeClass: .regular)
        ])

        // Small iPad with >4 rows in landscape should have height reduction
        let height4Row = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPadMini5, isLandscape: true),
            traitCollection: traitCollection,
            rowCount: 4,
            legacy: true
        )

        let height5Row = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPadMini5, isLandscape: true),
            traitCollection: traitCollection,
            rowCount: 5,
            legacy: true
        )

        // The 5-row should be adjusted down by 40 pixels to prevent taking up too much screen
        let expectedDifference = (height4Row / 4.0) - 40
        XCTAssertEqual(height5Row - height4Row, expectedDifference, accuracy: 0.1,
                       "Small iPad with 5 rows in landscape should have 40px reduction")
    }
}

/// Unrecognised screen sizes are reported to Sentry so new devices get noticed, but the height is worked out on
/// every layout, so reporting each time would send the same event over and over.
final class UnrecognizedScreenSizeReportingTests: XCTestCase {
    private let phone = UITraitCollection(userInterfaceIdiom: .phone)
    private var reported: [Double] = []
    private var originalReporter: ((Double) -> Void)!

    override func setUp() {
        super.setUp()
        originalReporter = KeyboardHeightProvider.reportUnrecognizedScreenSize
        KeyboardHeightProvider.reportUnrecognizedScreenSize = { [unowned self] in self.reported.append($0) }
        KeyboardHeightProvider.reportedScreenSizes = []
    }

    override func tearDown() {
        KeyboardHeightProvider.reportUnrecognizedScreenSize = originalReporter
        KeyboardHeightProvider.reportedScreenSizes = []
        super.tearDown()
    }

    func test_unknownDevice_isReportedOnce() {
        for isLandscape in [false, true, false, true] {
            _ = height(.unknown("iPhone99,1"), isLandscape: isLandscape)
        }
        XCTAssertEqual(reported, [-1])
    }

    func test_unknownDevice_stillGetsAHeightFromItsScreen_everyTime() {
        let first = height(.unknown("iPhone99,1"))
        XCTAssertGreaterThan(first, 0)
        XCTAssertEqual(height(.unknown("iPhone99,1")), first)
    }

    func test_knownDevice_isNotReported() {
        _ = height(.iPhone16)
        _ = height(.iPadMini5)
        XCTAssertEqual(reported, [])
    }

    private func height(_ device: Device, isLandscape: Bool = false) -> CGFloat {
        let screen = isLandscape ? CGSize(width: 874, height: 402) : CGSize(width: 402, height: 874)
        return KeyboardHeightProvider.height(for: DeviceContext(device: device, isLandscape: isLandscape, screenSize: screen),
                                             traitCollection: phone)
    }
}

final class CurrentDeviceContextTests: XCTestCase {
    func test_device_isTheSameOnEveryCall() {
        let first = DeviceContext.current
        for _ in 0..<5 {
            let context = DeviceContext.current
            XCTAssertEqual(context.screenInches, first.screenInches)
            XCTAssertEqual(context.isPad, first.isPad)
            XCTAssertEqual(context.isPhone, first.isPhone)
        }
    }

    func test_device_isThisDevice() {
        // The test host runs on the same hardware (or simulator) as the device it reports.
        XCTAssertEqual(DeviceContext.current.isPad, UIDevice.current.userInterfaceIdiom == .pad)
        XCTAssertEqual(DeviceContext.current.isPhone, UIDevice.current.userInterfaceIdiom == .phone)
    }

    func test_withoutAView_screenIsTheMainScreen() {
        let context = DeviceContext.current(in: nil)
        XCTAssertEqual(context.screenSize, UIScreen.main.bounds.size)
        XCTAssertEqual(context.isLandscape, UIScreen.main.bounds.width > UIScreen.main.bounds.height)
    }

    func test_viewInAWindow_screenIsItsWindowsScreen() throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.isHidden = false
        let view = UIView()
        window.addSubview(view)
        defer { window.isHidden = true }

        let context = DeviceContext.current(in: view)
        XCTAssertEqual(context.screenSize, scene.screen.bounds.size)
        XCTAssertEqual(context.screenInches, DeviceContext.current.screenInches)
        XCTAssertEqual(context.isPad, DeviceContext.current.isPad)
    }
}

/// Switching keyboard modes (normal, split, one-handed) replaces the keyboard view. The old views must be freed and
/// the banner kept, not duplicated, or every switch leaks a keyboard's worth of views.
final class KeyboardModeSwitchingTests: XCTestCase {
    private var window: UIWindow!
    private var sut: KeyboardViewController!

    override func setUp() {
        super.setUp()
        // In its own pool, so objects autoreleased while the first keyboard is built don't outlive it in the tests.
        autoreleasepool {
            window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            sut = KeyboardViewController()
            window.rootViewController = sut
            window.isHidden = false
            layout()
        }
    }

    override func tearDown() {
        window.isHidden = true
        window.rootViewController = nil
        sut = nil
        window = nil
        super.tearDown()
    }

    func test_switchingModes_keepsOneBanner() {
        XCTAssertEqual(count(SpellBannerView.self), 1)
        for mode in modeKeys + modeKeys {
            sut.didTriggerKey(KeyDefinition(type: mode))
            layout()
            XCTAssertEqual(count(SpellBannerView.self), 1, "after \(mode)")
        }
    }

    func test_switchingModes_freesTheOldKeyboardViews() {
        var replaced: [Weak] = []
        for mode in modeKeys + modeKeys {
            autoreleasepool {
                replaced += keyboardViews().map(Weak.init)
                sut.didTriggerKey(KeyDefinition(type: mode))
                layout()
            }
        }
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        XCTAssertEqual(replaced.count, 10) // 2 split halves + 3 single keyboards, twice
        XCTAssertEqual(replaced.filter { $0.view != nil }.count, 0, "keyboard views still alive after being replaced")
    }

    func test_switchingModes_showsOnlyTheCurrentKeyboard() {
        for (mode, expected) in zip(modeKeys, [2, 1, 1, 1]) {
            sut.didTriggerKey(KeyDefinition(type: mode))
            layout()
            XCTAssertEqual(keyboardViews().count, expected, "after \(mode)")
        }
    }

    func test_switchingModes_doesNotAddViews() {
        sut.didTriggerKey(KeyDefinition(type: .normalKeyboard))
        layout()
        let before = viewCount(sut.view)
        for mode in modeKeys + modeKeys {
            sut.didTriggerKey(KeyDefinition(type: mode))
            layout()
        }
        XCTAssertEqual(viewCount(sut.view), before)
    }

    // MARK: - Helpers

    /// Split, left, right, then back to normal.
    private let modeKeys: [KeyType] = [.splitKeyboard, .sideKeyboardLeft, .sideKeyboardRight, .normalKeyboard]

    private func layout() {
        window.layoutIfNeeded()
        sut.view.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))
    }

    private func keyboardViews() -> [KeyboardView] {
        all(in: sut.view).compactMap { $0 as? KeyboardView }
    }

    private func count<T: UIView>(_ type: T.Type) -> Int {
        all(in: sut.view).filter { $0 is T }.count
    }

    private func viewCount(_ view: UIView) -> Int {
        all(in: view).count
    }

    private func all(in view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap { all(in: $0) }
    }
}

private final class Weak {
    weak var view: UIView?
    init(_ view: UIView) { self.view = view }
}

/// Switching between light and dark mode while the keyboard is open.
final class KeyboardAppearanceTests: XCTestCase {
    private var window: UIWindow!
    private var sut: KeyboardViewController!

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        sut = KeyboardViewController()
        sut.overrideUserInterfaceStyle = .light
        window.rootViewController = sut
        window.isHidden = false
        layout()
    }

    override func tearDown() {
        window.isHidden = true
        window.rootViewController = nil
        sut = nil
        window = nil
        super.tearDown()
    }

    func test_startsWithTheLightTheme() {
        XCTAssertEqual(sut.theme.appearance, .light)
        assertViewsUseTheCurrentTheme()
    }

    func test_switchingToDark_appliesTheDarkThemeEverywhere() {
        let lightKeys = keyViewIDs()
        setStyle(.dark)
        XCTAssertEqual(sut.theme.appearance, .dark)
        XCTAssertTrue(Set(lightKeys).isDisjoint(with: keyViewIDs()), "keys should be rebuilt in the new theme")
        // Only set on a theme change: every theme's background is transparent, so the first load leaves it unset.
        XCTAssertEqual(sut.view.backgroundColor, sut.theme.backgroundColor)
        assertViewsUseTheCurrentTheme()
    }

    func test_switchingBackToLight_appliesTheLightThemeAgain() {
        setStyle(.dark)
        setStyle(.light)
        XCTAssertEqual(sut.theme.appearance, .light)
        XCTAssertEqual(sut.view.backgroundColor, sut.theme.backgroundColor)
        assertViewsUseTheCurrentTheme()
    }

    func test_traitChangeWithTheSameStyle_keepsTheThemeAndKeys() {
        let keys = keyViewIDs()
        let background = sut.theme.backgroundColor
        sut.traitCollectionDidChange(sut.traitCollection)
        layout()
        XCTAssertEqual(keyViewIDs(), keys)
        XCTAssertEqual(sut.theme.backgroundColor, background)
    }

    func test_typing_keepsTheThemeAndKeys() {
        // The appearance is checked on every keystroke, so this must not rebuild anything.
        let keys = keyViewIDs()
        for _ in 0..<3 {
            sut.textDidChange(nil)
            layout()
        }
        XCTAssertEqual(keyViewIDs(), keys)
    }

    // MARK: - Helpers

    private func setStyle(_ style: UIUserInterfaceStyle) {
        sut.overrideUserInterfaceStyle = style
        layout()
    }

    private func layout() {
        window.layoutIfNeeded()
        sut.view.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        sut.view.layoutIfNeeded()
    }

    private func assertViewsUseTheCurrentTheme(file: StaticString = #filePath, line: UInt = #line) {
        let theme = sut.theme
        let banner = all(in: sut.view).compactMap { $0 as? SpellBannerView }.first
        let bannerList = banner.flatMap { all(in: $0).compactMap { $0 as? UICollectionView }.first }
        XCTAssertNotNil(bannerList, "spell banner", file: file, line: line)
        XCTAssertEqual(bannerList?.backgroundColor, theme.bannerBackgroundColor, "banner background", file: file, line: line)

        let letterLabels = all(in: sut.view).compactMap { $0 as? KeyView }
            .flatMap { all(in: $0).compactMap { $0 as? UILabel } }
            .filter { $0.text?.count == 1 && $0.text?.first?.isLetter == true }
        XCTAssertFalse(letterLabels.isEmpty, "letter keys", file: file, line: line)
        for label in letterLabels where label.textColor != theme.textColor {
            XCTFail("key \(label.text ?? "") has the other theme's text colour", file: file, line: line)
            break
        }
    }

    private func keyViewIDs() -> [ObjectIdentifier] {
        all(in: sut.view).compactMap { $0 as? KeyView }.map(ObjectIdentifier.init)
    }

    private func all(in view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap { all(in: $0) }
    }
}
