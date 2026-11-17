@testable import BaseKeyboard
import DeviceKit
import XCTest

final class KeyboardViewControllerTests: XCTestCase {
    // MARK: - Landscape Height Tests

    func testLandscapeHeight_iPadMini_7_9Inch() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .pad),
            UITraitCollection(horizontalSizeClass: .regular)
        ])

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPadMini5, isLandscape: true),
            traitCollection: traitCollection
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
            traitCollection: traitCollection
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
            traitCollection: traitCollection
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
            traitCollection: traitCollection
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
            traitCollection: traitCollection
        )
        XCTAssertEqual(height, 476, "iPad 12.9\" should return 476 in landscape")
    }

    func testLandscapeHeight_iPhone_4_7Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhone8, isLandscape: true),
            traitCollection: traitCollection
        )
        XCTAssertEqual(height, 208, "iPhone 4.7\" should return 208 in landscape")
    }

    func testLandscapeHeight_iPhone_5_5Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhone8Plus, isLandscape: true),
            traitCollection: traitCollection
        )
        XCTAssertEqual(height, 208, "iPhone 5.5\" should return 208 in landscape")
    }

    func testLandscapeHeight_iPhone_5_8Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhoneX, isLandscape: true),
            traitCollection: traitCollection
        )
        XCTAssertEqual(height, 196, "iPhone 5.8\" should return 196 in landscape")
    }

    func testLandscapeHeight_iPhone_6_1Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhone11, isLandscape: true),
            traitCollection: traitCollection
        )
        XCTAssertEqual(height, 206, "iPhone 6.1\" should return 206 in landscape")
    }

    func testLandscapeHeight_iPhoneXSMax() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhoneXSMax, isLandscape: true),
            traitCollection: traitCollection
        )
        XCTAssertEqual(height, 196, "iPhone XS Max should return 196 in landscape (device override)")
    }

    func testLandscapeHeight_iPhone11ProMax() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhone11ProMax, isLandscape: true),
            traitCollection: traitCollection
        )
        XCTAssertEqual(height, 196, "iPhone 11 Pro Max should return 196 in landscape (device override)")
    }

    // MARK: - Portrait Height Tests

    func testPortraitHeight_iPhone_4_7Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhone8, isLandscape: false),
            traitCollection: traitCollection
        )
        XCTAssertEqual(height, 262, "iPhone 4.7\" should return 262 in portrait")
    }

    func testPortraitHeight_iPhone_5_5Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhone8Plus, isLandscape: false),
            traitCollection: traitCollection
        )
        XCTAssertEqual(height, 272, "iPhone 5.5\" should return 272 in portrait")
    }

    func testPortraitHeight_iPhone_5_8Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhoneX, isLandscape: false),
            traitCollection: traitCollection
        )
        XCTAssertEqual(height, 262, "iPhone 5.8\" should return 262 in portrait")
    }

    func testPortraitHeight_iPhone_6_1Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhone11, isLandscape: false),
            traitCollection: traitCollection
        )
        XCTAssertEqual(height, 262, "iPhone 6.1\" should return 262 in portrait")
    }

    func testPortraitHeight_iPhoneXSMax() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhoneXSMax, isLandscape: false),
            traitCollection: traitCollection
        )
        XCTAssertEqual(height, 272, "iPhone XS Max should return 272 in portrait (device override)")
    }

    func testPortraitHeight_iPhone11ProMax() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhone11ProMax, isLandscape: false),
            traitCollection: traitCollection
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
            traitCollection: traitCollection
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
            traitCollection: traitCollection
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
            traitCollection: traitCollection
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
            traitCollection: traitCollection
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
            rowCount: 4
        )
        XCTAssertEqual(height, 262, "Standard 4-row keyboard should return base height")
    }

    func testRowCountAdjustment_ExtraRows() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        // 5-row keyboard should be taller
        let height4Row = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhone8, isLandscape: false),
            traitCollection: traitCollection,
            rowCount: 4
        )

        let height5Row = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPhone8, isLandscape: false),
            traitCollection: traitCollection,
            rowCount: 5
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
            rowCount: 5
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
            rowCount: 4
        )

        let height5Row = KeyboardHeightProvider.height(
            for: DeviceContext(device: .iPadMini5, isLandscape: true),
            traitCollection: traitCollection,
            rowCount: 5
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
