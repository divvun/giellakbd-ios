@testable import BaseKeyboard
import XCTest
import DeviceKit

final class KeyboardViewControllerTests: XCTestCase {
    // MARK: - Landscape Height Tests

    func testLandscapeHeight_iPadMini_7_9Inch() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .pad),
            UITraitCollection(horizontalSizeClass: .regular)
        ])

        let height = KeyboardHeightProvider.height(
            for: .iPadMini5,
            traitCollection: traitCollection,
            isLandscape: true
        )
        XCTAssertEqual(height, 404, "iPad Mini 7.9\" should return 404 in landscape")
    }

    func testLandscapeHeight_iPad_9_7Inch() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .pad),
            UITraitCollection(horizontalSizeClass: .regular)
        ])

        let height = KeyboardHeightProvider.height(
            for: .iPadPro9Inch,
            traitCollection: traitCollection,
            isLandscape: true
        )
        XCTAssertEqual(height, 404, "iPad 9.7\" should return 404 in landscape")
    }

    func testLandscapeHeight_iPad_10_5Inch() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .pad),
            UITraitCollection(horizontalSizeClass: .regular)
        ])

        let height = KeyboardHeightProvider.height(
            for: .iPadPro10Inch,
            traitCollection: traitCollection,
            isLandscape: true
        )
        XCTAssertEqual(height, 404, "iPad 10.5\" should return 404 in landscape")
    }

    func testLandscapeHeight_iPad_11Inch() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .pad),
            UITraitCollection(horizontalSizeClass: .regular)
        ])

        let height = KeyboardHeightProvider.height(
            for: .iPadPro11Inch,
            traitCollection: traitCollection,
            isLandscape: true
        )
        XCTAssertEqual(height, 404, "iPad 11\" should return 404 in landscape")
    }

    func testLandscapeHeight_iPad_12_9Inch() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .pad),
            UITraitCollection(horizontalSizeClass: .regular)
        ])

        let height = KeyboardHeightProvider.height(
            for: .iPadPro12Inch,
            traitCollection: traitCollection,
            isLandscape: true
        )
        XCTAssertEqual(height, 476, "iPad 12.9\" should return 476 in landscape")
    }

    func testLandscapeHeight_iPhone_4_7Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: .iPhone8,
            traitCollection: traitCollection,
            isLandscape: true
        )
        XCTAssertEqual(height, 208, "iPhone 4.7\" should return 208 in landscape")
    }

    func testLandscapeHeight_iPhone_5_5Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: .iPhone8Plus,
            traitCollection: traitCollection,
            isLandscape: true
        )
        XCTAssertEqual(height, 208, "iPhone 5.5\" should return 208 in landscape")
    }

    func testLandscapeHeight_iPhone_5_8Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: .iPhoneX,
            traitCollection: traitCollection,
            isLandscape: true
        )
        XCTAssertEqual(height, 196, "iPhone 5.8\" should return 196 in landscape")
    }

    func testLandscapeHeight_iPhone_6_1Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: .iPhone11,
            traitCollection: traitCollection,
            isLandscape: true
        )
        XCTAssertEqual(height, 206, "iPhone 6.1\" should return 206 in landscape")
    }

    func testLandscapeHeight_iPhoneXSMax() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: .iPhoneXSMax,
            traitCollection: traitCollection,
            isLandscape: true
        )
        XCTAssertEqual(height, 196, "iPhone XS Max should return 196 in landscape (device override)")
    }

    func testLandscapeHeight_iPhone11ProMax() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: .iPhone11ProMax,
            traitCollection: traitCollection,
            isLandscape: true
        )
        XCTAssertEqual(height, 196, "iPhone 11 Pro Max should return 196 in landscape (device override)")
    }

    // MARK: - Portrait Height Tests

    func testPortraitHeight_iPhone_4_7Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: .iPhone8,
            traitCollection: traitCollection,
            isLandscape: false
        )
        XCTAssertEqual(height, 262, "iPhone 4.7\" should return 262 in portrait")
    }

    func testPortraitHeight_iPhone_5_5Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: .iPhone8Plus,
            traitCollection: traitCollection,
            isLandscape: false
        )
        XCTAssertEqual(height, 272, "iPhone 5.5\" should return 272 in portrait")
    }

    func testPortraitHeight_iPhone_5_8Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: .iPhoneX,
            traitCollection: traitCollection,
            isLandscape: false
        )
        XCTAssertEqual(height, 262, "iPhone 5.8\" should return 262 in portrait")
    }

    func testPortraitHeight_iPhone_6_1Inch() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: .iPhone11,
            traitCollection: traitCollection,
            isLandscape: false
        )
        XCTAssertEqual(height, 262, "iPhone 6.1\" should return 262 in portrait")
    }

    func testPortraitHeight_iPhoneXSMax() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: .iPhoneXSMax,
            traitCollection: traitCollection,
            isLandscape: false
        )
        XCTAssertEqual(height, 272, "iPhone XS Max should return 272 in portrait (device override)")
    }

    func testPortraitHeight_iPhone11ProMax() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        let height = KeyboardHeightProvider.height(
            for: .iPhone11ProMax,
            traitCollection: traitCollection,
            isLandscape: false
        )
        XCTAssertEqual(height, 272, "iPhone 11 Pro Max should return 272 in portrait (device override)")
    }

    func testPortraitHeight_iPad_7_9Inch() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .pad),
            UITraitCollection(horizontalSizeClass: .regular)
        ])

        let height = KeyboardHeightProvider.height(
            for: .iPadMini5,
            traitCollection: traitCollection,
            isLandscape: false
        )
        XCTAssertEqual(height, 318, "iPad 7.9\" should return 318 in portrait")
    }

    func testPortraitHeight_iPad_9_7Inch() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .pad),
            UITraitCollection(horizontalSizeClass: .regular)
        ])

        let height = KeyboardHeightProvider.height(
            for: .iPadPro9Inch,
            traitCollection: traitCollection,
            isLandscape: false
        )
        XCTAssertEqual(height, 318, "iPad 9.7\" should return 318 in portrait")
    }

    func testPortraitHeight_iPad_11Inch() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .pad),
            UITraitCollection(horizontalSizeClass: .regular)
        ])

        let height = KeyboardHeightProvider.height(
            for: .iPadPro11Inch,
            traitCollection: traitCollection,
            isLandscape: false
        )
        XCTAssertEqual(height, 318, "iPad 11\" should return 318 in portrait")
    }

    func testPortraitHeight_iPad_12_9Inch() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .pad),
            UITraitCollection(horizontalSizeClass: .regular)
        ])

        let height = KeyboardHeightProvider.height(
            for: .iPadPro12Inch,
            traitCollection: traitCollection,
            isLandscape: false
        )
        XCTAssertEqual(height, 384, "iPad 12.9\" should return 384 in portrait")
    }

    // MARK: - iPad Compatibility Mode Tests

//    func testCompatibilityMode_iPadRunningIPhoneApp_SmallIPad() {
//        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)
//
//        // Simulate iPad Mini running iPhone app
//        let height = KeyboardHeightProvider.height(
//            for: .iPadMini5,
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
//            for: .iPadPro12Inch,
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
            for: .iPhone8,
            traitCollection: traitCollection,
            isLandscape: false,
            rowCount: 4
        )
        XCTAssertEqual(height, 262, "Standard 4-row keyboard should return base height")
    }

    func testRowCountAdjustment_ExtraRows() {
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        // 5-row keyboard should be taller
        let height4Row = KeyboardHeightProvider.height(
            for: .iPhone8,
            traitCollection: traitCollection,
            isLandscape: false,
            rowCount: 4
        )

        let height5Row = KeyboardHeightProvider.height(
            for: .iPhone8,
            traitCollection: traitCollection,
            isLandscape: false,
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
            for: .iPadPro12Inch,
            traitCollection: traitCollection,
            isLandscape: false,
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
            for: .iPadMini5,
            traitCollection: traitCollection,
            isLandscape: true,
            rowCount: 4
        )

        let height5Row = KeyboardHeightProvider.height(
            for: .iPadMini5,
            traitCollection: traitCollection,
            isLandscape: true,
            rowCount: 5
        )

        // The 5-row should be adjusted down by 40 pixels to prevent taking up too much screen
        let expectedDifference = (height4Row / 4.0) - 40
        XCTAssertEqual(height5Row - height4Row, expectedDifference, accuracy: 0.1,
                       "Small iPad with 5 rows in landscape should have 40px reduction")
    }
}
