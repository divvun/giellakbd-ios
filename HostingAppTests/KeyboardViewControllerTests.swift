@testable import BaseKeyboard
import DeviceKit
import XCTest

final class KeyboardViewControllerTests: XCTestCase {
    // This test isn't accurate because textDocumentProxy.autocapitalizationType isn't .sentences.
    // Leaving as a reference for creating other KeyboardViewController tests

//    func test_keyboard_should_auto_shift_after_full_stop() {
//        let sut = KeyboardViewController(withBanner: true)
//        sut.viewDidLoad()
//
//        sut.insertText("H")
//        sut.insertText("i")
//        sut.insertText(" ")
//        sut.insertText(" ")
//
//        XCTAssertEqual("Hi. ", sut.textDocumentProxy.documentContextBeforeInput)
//        XCTAssertEqual(.shifted, sut.page)
//    }

    // MARK: - Landscape Height Tests

    func testLandscapeHeight_iPadMini() throws {
        // These tests verify the height calculation logic works correctly for specific devices
        // They can run on any device since they test the static helper methods
        let iPadMinis: [Device] = [.iPadMini2, .iPadMini3, .iPadMini4, .iPadMini5]
        let traitCollection = UITraitCollection(userInterfaceIdiom: .pad)

        for device in iPadMinis {
            let height = KeyboardViewController.landscapeHeight(
                for: device,
                traitCollection: traitCollection,
                portraitHeight: 0, // Not used for these devices
                landscapeDeviceHeight: 0, // Not used for these devices
                sizeInches: 7.9
            )
            XCTAssertEqual(height, 400.0, "iPad Mini (\(device)) should return 400.0 in landscape")
        }
    }

    func testLandscapeHeight_iPad9Inch() {
        // iPad 3, 4, 5, 6, Air, Air 2, Pro 9" should return 353.0
        let iPads: [Device] = [.iPad3, .iPad4, .iPad5, .iPad6, .iPadAir, .iPadAir2, .iPadPro9Inch]
        let traitCollection = UITraitCollection(userInterfaceIdiom: .pad)

        for device in iPads {
            let height = KeyboardViewController.landscapeHeight(
                for: device,
                traitCollection: traitCollection,
                portraitHeight: 0,
                landscapeDeviceHeight: 0,
                sizeInches: 9.7
            )
            XCTAssertEqual(height, 353.0, "\(device) should return 353.0 in landscape")
        }
    }

    func testLandscapeHeight_iPad10And11Inch() {
        // iPad Air 3, Pro 10.5", Pro 11" should return 405.0
        let iPads: [Device] = [.iPadAir3, .iPadPro10Inch, .iPadPro11Inch]
        let traitCollection = UITraitCollection(userInterfaceIdiom: .pad)

        for device in iPads {
            let height = KeyboardViewController.landscapeHeight(
                for: device,
                traitCollection: traitCollection,
                portraitHeight: 0,
                landscapeDeviceHeight: 0,
                sizeInches: 10.5
            )
            XCTAssertEqual(height, 405.0, "\(device) should return 405.0 in landscape")
        }
    }

    func testLandscapeHeight_iPad12Inch() {
        // All iPad Pro 12.9" models should return 426.0
        let iPads: [Device] = [
            .iPadPro12Inch, .iPadPro12Inch2, .iPadPro12Inch3,
            .iPadPro12Inch4, .iPadPro12Inch5, .iPadPro12Inch6
        ]
        let traitCollection = UITraitCollection(userInterfaceIdiom: .pad)

        for device in iPads {
            let height = KeyboardViewController.landscapeHeight(
                for: device,
                traitCollection: traitCollection,
                portraitHeight: 0,
                landscapeDeviceHeight: 0,
                sizeInches: 12.9
            )
            XCTAssertEqual(height, 426.0, "\(device) should return 426.0 in landscape")
        }
    }

    func testLandscapeHeight_iPhone5sGeneration() {
        // iPhone 5s, 5c, SE, iPod Touch 7 should return 203.0
        let devices: [Device] = [.iPhone5s, .iPhone5c, .iPhoneSE, .iPodTouch7]
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        for device in devices {
            let height = KeyboardViewController.landscapeHeight(
                for: device,
                traitCollection: traitCollection,
                portraitHeight: 0,
                landscapeDeviceHeight: 0,
                sizeInches: 4.0
            )
            XCTAssertEqual(height, 203.0, "\(device) should return 203.0 in landscape")
        }
    }

    func testLandscapeHeight_iPhone6to8() {
        // iPhone 6, 6s, 7, 8 should return 203.0
        let devices: [Device] = [.iPhone6, .iPhone6s, .iPhone7, .iPhone8]
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        for device in devices {
            let height = KeyboardViewController.landscapeHeight(
                for: device,
                traitCollection: traitCollection,
                portraitHeight: 0,
                landscapeDeviceHeight: 0,
                sizeInches: 4.7
            )
            XCTAssertEqual(height, 203.0, "\(device) should return 203.0 in landscape")
        }
    }

    func testLandscapeHeight_iPhone6to8Plus() {
        // iPhone 6 Plus, 6s Plus, 7 Plus, 8 Plus should return 203.0
        let devices: [Device] = [.iPhone6Plus, .iPhone6sPlus, .iPhone7Plus, .iPhone8Plus]
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        for device in devices {
            let height = KeyboardViewController.landscapeHeight(
                for: device,
                traitCollection: traitCollection,
                portraitHeight: 0,
                landscapeDeviceHeight: 0,
                sizeInches: 5.5
            )
            XCTAssertEqual(height, 203.0, "\(device) should return 203.0 in landscape")
        }
    }

    func testLandscapeHeight_iPhone11AndXR() {
        // iPhone 11, XR should return 190.0
        let devices: [Device] = [.iPhone11, .iPhoneXR]
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        for device in devices {
            let height = KeyboardViewController.landscapeHeight(
                for: device,
                traitCollection: traitCollection,
                portraitHeight: 0,
                landscapeDeviceHeight: 0,
                sizeInches: 6.1
            )
            XCTAssertEqual(height, 190.0, "\(device) should return 190.0 in landscape")
        }
    }

    func testLandscapeHeight_iPhoneXAndXSAnd11Pro() {
        // iPhone X, XS, 11 Pro should return 190.0
        let devices: [Device] = [.iPhoneX, .iPhoneXS, .iPhone11Pro]
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        for device in devices {
            let height = KeyboardViewController.landscapeHeight(
                for: device,
                traitCollection: traitCollection,
                portraitHeight: 0,
                landscapeDeviceHeight: 0,
                sizeInches: 5.8
            )
            XCTAssertEqual(height, 190.0, "\(device) should return 190.0 in landscape")
        }
    }

    func testLandscapeHeight_iPhoneXSMaxAnd11ProMax() {
        // iPhone XS Max, 11 Pro Max should return 190.0
        let devices: [Device] = [.iPhoneXSMax, .iPhone11ProMax]
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        for device in devices {
            let height = KeyboardViewController.landscapeHeight(
                for: device,
                traitCollection: traitCollection,
                portraitHeight: 0,
                landscapeDeviceHeight: 0,
                sizeInches: 6.5
            )
            XCTAssertEqual(height, 190.0, "\(device) should return 190.0 in landscape")
        }
    }

    // MARK: - Portrait Height Tests

    func testPortraitHeight_iPhone5sGeneration() {
        // iPhone 5s, 5c, SE, iPod Touch 7 should return 254.0
        let devices: [Device] = [.iPhone5s, .iPhone5c, .iPhoneSE, .iPodTouch7]
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        for device in devices {
            let height = KeyboardViewController.portraitHeight(
                for: device,
                traitCollection: traitCollection,
                portraitDeviceHeight: 0,
                sizeInches: 4.0
            )
            XCTAssertEqual(height, 254.0, "\(device) should return 254.0 in portrait")
        }
    }

    func testPortraitHeight_iPhone6to8() {
        // iPhone 6, 6s, 7, 8 should return 262.0
        let devices: [Device] = [.iPhone6, .iPhone6s, .iPhone7, .iPhone8]
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        for device in devices {
            let height = KeyboardViewController.portraitHeight(
                for: device,
                traitCollection: traitCollection,
                portraitDeviceHeight: 0,
                sizeInches: 4.7
            )
            XCTAssertEqual(height, 262.0, "\(device) should return 262.0 in portrait")
        }
    }

    func testPortraitHeight_iPhone6to8Plus() {
        // iPhone 6 Plus, 6s Plus, 7 Plus, 8 Plus should return 272.0
        let devices: [Device] = [.iPhone6Plus, .iPhone6sPlus, .iPhone7Plus, .iPhone8Plus]
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        for device in devices {
            let height = KeyboardViewController.portraitHeight(
                for: device,
                traitCollection: traitCollection,
                portraitDeviceHeight: 0,
                sizeInches: 5.5
            )
            XCTAssertEqual(height, 272.0, "\(device) should return 272.0 in portrait")
        }
    }

    func testPortraitHeight_iPhone11AndXR() {
        // iPhone 11, XR should return 272.0
        let devices: [Device] = [.iPhone11, .iPhoneXR]
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        for device in devices {
            let height = KeyboardViewController.portraitHeight(
                for: device,
                traitCollection: traitCollection,
                portraitDeviceHeight: 0,
                sizeInches: 6.1
            )
            XCTAssertEqual(height, 272.0, "\(device) should return 272.0 in portrait")
        }
    }

    func testPortraitHeight_iPhoneXAndXSAnd11Pro() {
        // iPhone X, XS, 11 Pro should return 262.0
        let devices: [Device] = [.iPhoneX, .iPhoneXS, .iPhone11Pro]
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        for device in devices {
            let height = KeyboardViewController.portraitHeight(
                for: device,
                traitCollection: traitCollection,
                portraitDeviceHeight: 0,
                sizeInches: 5.8
            )
            XCTAssertEqual(height, 262.0, "\(device) should return 262.0 in portrait")
        }
    }

    func testPortraitHeight_iPhoneXSMaxAnd11ProMax() {
        // iPhone XS Max, 11 Pro Max should return 272.0
        let devices: [Device] = [.iPhoneXSMax, .iPhone11ProMax]
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)

        for device in devices {
            let height = KeyboardViewController.portraitHeight(
                for: device,
                traitCollection: traitCollection,
                portraitDeviceHeight: 0,
                sizeInches: 6.5
            )
            XCTAssertEqual(height, 272.0, "\(device) should return 272.0 in portrait")
        }
    }

    func testPortraitHeight_iPadSizeBased() {
        // iPad portrait heights are size-based, not device-specific
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .pad),
            UITraitCollection(horizontalSizeClass: .regular)
        ])

        // Test 9" iPad
        let height9 = KeyboardViewController.portraitHeight(
            for: .iPadPro9Inch,
            traitCollection: traitCollection,
            portraitDeviceHeight: 2048,
            sizeInches: 9.7
        )
        XCTAssertEqual(height9, 314.0, "9-inch iPad should return 314.0 in portrait")

        // Test 11" iPad
        let height11 = KeyboardViewController.portraitHeight(
            for: .iPadPro11Inch,
            traitCollection: traitCollection,
            portraitDeviceHeight: 2388,
            sizeInches: 11.0
        )
        XCTAssertEqual(height11, 384.0, "11-inch iPad should return 384.0 in portrait")

        // Test 12.9" iPad
        let height12 = KeyboardViewController.portraitHeight(
            for: .iPadPro12Inch,
            traitCollection: traitCollection,
            portraitDeviceHeight: 2732,
            sizeInches: 12.9
        )
        XCTAssertEqual(height12, 2732.0 / 4.0, "12.9-inch iPad should return portraitDeviceHeight / 4.0 in portrait")
    }
}
