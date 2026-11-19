@testable import BaseKeyboard
import DeviceKit
import XCTest

final class ThemeTests: XCTestCase {
    private let idioms: [UIUserInterfaceIdiom] = [.phone, .pad]
    private let styles: [UIUserInterfaceStyle] = [.unspecified, .light, .dark]

    func test_appearance_matchesTheThemeBuiltForTheSameTraits() {
        for idiom in idioms {
            for style in styles {
                let traits = UITraitCollection(traitsFrom: [
                    UITraitCollection(userInterfaceIdiom: idiom),
                    UITraitCollection(userInterfaceStyle: style)
                ])
                XCTAssertEqual(
                    Theme.appearance(for: traits),
                    Theme.current(for: traits, device: .current).appearance,
                    "idiom \(idiom.rawValue), style \(style.rawValue)"
                )
            }
        }
    }

    func test_appearance_isDarkOnlyForTheDarkStyle() {
        XCTAssertEqual(Theme.appearance(for: UITraitCollection(userInterfaceStyle: .dark)), .dark)
        XCTAssertEqual(Theme.appearance(for: UITraitCollection(userInterfaceStyle: .light)), .light)
        XCTAssertEqual(Theme.appearance(for: UITraitCollection(userInterfaceStyle: .unspecified)), .light)
    }

    // MARK: - Key area insets

    // The tests link DeviceKit's enum cases but not its type metadata, so they build DeviceContexts directly rather
    // than keeping arrays of devices.
    private let phoneTraits = UITraitCollection(userInterfaceIdiom: .phone)
    private let padTraits = UITraitCollection(userInterfaceIdiom: .pad)

    private func theme(_ context: DeviceContext, traits: UITraitCollection? = nil) -> Theme {
        Theme.current(for: traits ?? (context.isPad ? padTraits : phoneTraits), device: context)
    }

    /// Home button and Face ID iPhones of each size, iPhone Duo, iPads of each size and an unrecognised device.
    private func everyKindOfDevice(landscape: Bool) -> [(String, DeviceContext)] {
        [
            ("iPhone 8", DeviceContext(device: .iPhone8, isLandscape: landscape)),
            ("iPhone 8 Plus", DeviceContext(device: .iPhone8Plus, isLandscape: landscape)),
            ("iPhone SE 3", DeviceContext(device: .iPhoneSE3, isLandscape: landscape)),
            ("iPhone X", DeviceContext(device: .iPhoneX, isLandscape: landscape)),
            ("iPhone 11 Pro Max", DeviceContext(device: .iPhone11ProMax, isLandscape: landscape)),
            ("iPhone 12 mini", DeviceContext(device: .iPhone12Mini, isLandscape: landscape)),
            ("iPhone 14 Pro", DeviceContext(device: .iPhone14Pro, isLandscape: landscape)),
            ("iPhone 15 Plus", DeviceContext(device: .iPhone15Plus, isLandscape: landscape)),
            ("iPhone 16e", DeviceContext(device: .iPhone16e, isLandscape: landscape)),
            ("iPhone 17 Pro Max", DeviceContext(device: .iPhone17ProMax, isLandscape: landscape)),
            ("iPhone Air", DeviceContext(device: .iPhoneAir, isLandscape: landscape)),
            ("iPhone Duo", DeviceContext(device: .iPhoneDuo, isLandscape: landscape)),
            ("iPad 10", DeviceContext(device: .iPad10, isLandscape: landscape)),
            ("iPad mini 6", DeviceContext(device: .iPadMini6, isLandscape: landscape)),
            ("iPad Pro 11 M4", DeviceContext(device: .iPadPro11M4, isLandscape: landscape)),
            ("iPad Pro 13 M4", DeviceContext(device: .iPadPro13M4, isLandscape: landscape)),
            ("unrecognised device", DeviceContext(device: .unknown("iPhone99,1"), isLandscape: landscape))
        ]
    }

    func test_keyAreaInsets_keepKeySizesOnEveryDevice() {
        // The insets only move margin from one end of the key area to the other, so every row keeps the height it had
        // when both ends had one margin.
        for landscape in [false, true] {
            for (name, context) in everyKindOfDevice(landscape: landscape) {
                let sut = theme(context)
                XCTAssertEqual(sut.keyAreaTopInset + sut.keyAreaBottomInset, 2 * sut.keyVerticalMargin, accuracy: 0.001,
                               "\(name), landscape \(landscape)")
            }
        }
    }

    func test_keyAreaInsets_dropTheMarginAboveTheSystemBar_onIPhonesWithoutAHomeButton() throws {
        try XCTSkipUnless(iOSVersion.isIOS26OrNewer, "Only iOS 26 and later move the bottom row")
        let cases: [(String, DeviceContext)] = [
            ("iPhone 14 Pro", DeviceContext(device: .iPhone14Pro, isLandscape: false)),
            ("iPhone 17 Pro Max", DeviceContext(device: .iPhone17ProMax, isLandscape: false)),
            ("iPhone 13 mini", DeviceContext(device: .iPhone13Mini, isLandscape: false)),
            ("iPhone Duo", DeviceContext(device: .iPhoneDuo, isLandscape: false)),
        ]
        for (name, context) in cases {
            let sut = theme(context)
            XCTAssertEqual(sut.keyAreaBottomInset, 0, name)
            XCTAssertEqual(sut.keyAreaTopInset, 2 * sut.keyVerticalMargin, name)
        }
    }

    func test_keyAreaInsets_areUnchanged_whereTheKeyboardReachesTheBottomOfTheScreen() {
        let iPad = DeviceContext(device: .iPadPro11M4, isLandscape: false)
        let cases: [(String, Theme)] = [
            ("iPhone SE 3", theme(DeviceContext(device: .iPhoneSE3, isLandscape: false))),
            ("iPhone 8", theme(DeviceContext(device: .iPhone8, isLandscape: false))),
            ("iPhone 14 Pro, landscape", theme(DeviceContext(device: .iPhone14Pro, isLandscape: true))),
            ("iPad", theme(iPad)),
            ("iPad, landscape", theme(DeviceContext(device: .iPadPro11M4, isLandscape: true))),
            ("iPhone app on iPad", theme(iPad, traits: phoneTraits)),
            ("unrecognised device", theme(DeviceContext(device: .unknown("iPhone99,1"), isLandscape: false)))
        ]
        for (name, sut) in cases {
            XCTAssertEqual(sut.keyAreaTopInset, sut.keyVerticalMargin, name)
            XCTAssertEqual(sut.keyAreaBottomInset, sut.keyVerticalMargin, name)
        }
    }
}
