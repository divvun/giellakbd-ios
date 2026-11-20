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

    // MARK: - Key area

    // The tests link DeviceKit's enum cases but not its type metadata, so they build DeviceContexts directly rather
    // than keeping arrays of devices.
    private let phoneTraits = UITraitCollection(userInterfaceIdiom: .phone)
    private let padTraits = UITraitCollection(userInterfaceIdiom: .pad)

    private func traits(for context: DeviceContext) -> UITraitCollection {
        context.isPad ? padTraits : phoneTraits
    }

    private func keyArea(_ context: DeviceContext, traits: UITraitCollection? = nil,
                         legacy: Bool = false) -> KeyAreaMetrics {
        KeyboardHeightProvider.keyArea(for: context, traitCollection: traits ?? self.traits(for: context), legacy: legacy)
    }

    private func height(_ context: DeviceContext, traits: UITraitCollection? = nil, rowCount: Int? = nil,
                        legacy: Bool = false) -> CGFloat {
        KeyboardHeightProvider.height(for: context, traitCollection: traits ?? self.traits(for: context),
                                      rowCount: rowCount, legacy: legacy)
    }

    private static let duoInner = CGSize(width: 669, height: 951)
    private static let duoOuter = CGSize(width: 466, height: 678)

    /// Devices whose system keyboard has been measured, in both orientations, with their screen's pixels per point.
    private var measuredDevices: [(String, DeviceContext, CGFloat)] {
        [false, true].flatMap { landscape -> [(String, DeviceContext, CGFloat)] in
            let duoInner = landscape ? CGSize(width: Self.duoInner.height, height: Self.duoInner.width) : Self.duoInner
            return [
                ("iPhone 17 Pro", DeviceContext(device: .iPhone17Pro, isLandscape: landscape), 3),
                ("iPhone 17 Pro Max", DeviceContext(device: .iPhone17ProMax, isLandscape: landscape), 3),
                ("iPhone Air", DeviceContext(device: .iPhoneAir, isLandscape: landscape), 3),
                ("iPhone 11", DeviceContext(device: .iPhone11, isLandscape: landscape,
                                            screenSize: landscape ? CGSize(width: 896, height: 414)
                                                                  : CGSize(width: 414, height: 896)), 2),
                ("iPhone Duo inner display", DeviceContext(device: .iPhoneDuo, isLandscape: landscape,
                                                           screenSize: duoInner), 3),
                ("iPad mini 6", DeviceContext(device: .iPadMini6, isLandscape: landscape), 2),
                ("iPad Pro 11 M4", DeviceContext(device: .iPadPro11M4, isLandscape: landscape), 2),
                ("iPad Pro 13 M4", DeviceContext(device: .iPadPro13M4, isLandscape: landscape), 2)
            ].map { ($0.0 + (landscape ? ", landscape" : ""), $0.1, $0.2) }
        }
    }

    func test_keyArea_matchesTheSystemKeyboard() {
        let iPhone = DeviceContext(device: .iPhone17Pro, isLandscape: false)
        XCTAssertEqual(keyArea(iPhone), KeyAreaMetrics(keyHeight: 43, rowGap: 11, topInset: 8, bottomInset: 0,
                                                     sideInset: 3.5))
        let largeIPhone = DeviceContext(device: .iPhone17ProMax, isLandscape: false)
        XCTAssertEqual(keyArea(largeIPhone), KeyAreaMetrics(keyHeight: 45, rowGap: 11, topInset: 8,
                                                          bottomInset: 7, sideInset: 3.5))
        let landscape = DeviceContext(device: .iPhone17Pro, isLandscape: true)
        XCTAssertEqual(keyArea(landscape), KeyAreaMetrics(keyHeight: 32, rowGap: 8, topInset: 6, bottomInset: 2,
                                                        sideInset: 1))
        let largeIPad = DeviceContext(device: .iPadPro13M4, isLandscape: false)
        XCTAssertEqual(keyArea(largeIPad).numberRowKeyHeight, 45.5)
        let homeButtonIPhone = DeviceContext(device: .iPhoneSE3, isLandscape: false)
        XCTAssertEqual(keyArea(homeButtonIPhone), KeyAreaMetrics(keyHeight: 42, rowGap: 12, topInset: 8,
                                                                 bottomInset: 4, sideInset: 3.5))
        let homeButtonIPhoneLandscape = DeviceContext(device: .iPhoneSE3, isLandscape: true)
        XCTAssertEqual(keyArea(homeButtonIPhoneLandscape).sideInset, 69)
        let duoOuter = DeviceContext(device: .iPhoneDuo, isLandscape: false, screenSize: Self.duoOuter)
        XCTAssertEqual(keyArea(duoOuter).keyHeight, 45)
    }

    func test_keyHeight_followsTheScreenWidth_onIPhones() {
        // iPhone 11 is a 6.1-inch iPhone like iPhone 17, but 414 pt wide, and its system keyboard has the taller keys.
        let iPhone11 = DeviceContext(device: .iPhone11, isLandscape: false, screenSize: CGSize(width: 414, height: 896))
        let iPhone17 = DeviceContext(device: .iPhone17, isLandscape: false, screenSize: CGSize(width: 402, height: 874))
        XCTAssertEqual(keyArea(iPhone11).keyHeight, 45)
        XCTAssertEqual(keyArea(iPhone17).keyHeight, 43)
    }

    func test_measuredKeyAreas_areWholePixels() {
        for (name, context, scale) in measuredDevices {
            let sut = keyArea(context)
            // Only the vertical sizes: key widths are shared out across each row, so they are fractional anyway.
            for value in [sut.keyHeight, sut.numberRowKeyHeight ?? 0, sut.rowGap, sut.topInset, sut.bottomInset] {
                XCTAssertEqual((value * scale).rounded(), value * scale, "\(name): \(value)")
            }
        }
    }

    func test_height_isTheBannerPlusTheKeyArea() {
        for (name, context, _) in measuredDevices {
            let banner = KeyboardHeightProvider.bannerHeight(for: context, traitCollection: traits(for: context))
            let rows = context.isLargeIPad ? 5 : 4
            let keys = keyArea(context).height(rowCount: rows, startsWithNumberRow: context.isLargeIPad)
            XCTAssertEqual(height(context), banner + keys, name)
        }
    }

    func test_height_isUnchanged_onDevicesThatHaveNotBeenMeasured() {
        let iPad = DeviceContext(device: .iPadPro11M4, isLandscape: false)
        let cases: [(String, DeviceContext, UITraitCollection?)] = [
            ("iPhone 8 Plus", DeviceContext(device: .iPhone8Plus, isLandscape: false), nil),
            ("iPhone 8 Plus, landscape", DeviceContext(device: .iPhone8Plus, isLandscape: true), nil),
            ("iPhone app on iPad", iPad, phoneTraits),
            ("unrecognised device", DeviceContext(device: .unknown("iPhone99,1"), isLandscape: false), nil)
        ]
        for (name, context, traits) in cases {
            XCTAssertEqual(height(context, traits: traits), height(context, traits: traits, legacy: true), name)
        }
    }

    func test_keyArea_beforeIOS26_hasTheKeyMarginAboveAndBelowTheRows() {
        let sut = keyArea(DeviceContext(device: .iPhone17Pro, isLandscape: false), legacy: true)
        XCTAssertEqual(sut.topInset, 6)
        XCTAssertEqual(sut.bottomInset, 6)
        XCTAssertEqual(sut.rowGap, 12)
        XCTAssertEqual(48 + sut.height(rowCount: 4), 262, accuracy: 0.001)
    }

    func test_extraRows_addOneRowEach() {
        let iPhone = DeviceContext(device: .iPhone17Pro, isLandscape: false)
        XCTAssertEqual(height(iPhone, rowCount: 5) - height(iPhone, rowCount: 4), 43 + 11)
        XCTAssertEqual(height(iPhone, rowCount: 4) - height(iPhone, rowCount: 3), 43 + 11)
        let largeIPad = DeviceContext(device: .iPadPro13M4, isLandscape: false)
        XCTAssertEqual(height(largeIPad, rowCount: 6) - height(largeIPad, rowCount: 5), 61 + 7)
    }

    func test_largeIPadLayoutsWithoutANumberRow_haveFullHeightRows() {
        let largeIPad = DeviceContext(device: .iPadPro13M4, isLandscape: false)
        let withNumberRow = KeyboardHeightProvider.height(for: largeIPad, traitCollection: padTraits, rowCount: 5,
                                                          startsWithNumberRow: true, legacy: false)
        let withoutNumberRow = KeyboardHeightProvider.height(for: largeIPad, traitCollection: padTraits, rowCount: 5,
                                                             startsWithNumberRow: false, legacy: false)
        XCTAssertEqual(withoutNumberRow - withNumberRow, 61 - 45.5)
    }

    func test_extraRows_stopGrowingTheKeyboard_onSmallIPadsInLandscape() {
        // Five full-height rows would cover most of the screen, so the keyboard is capped and the keys shrink to fit.
        let iPad = DeviceContext(device: .iPadMini6, isLandscape: true)
        let banner = KeyboardHeightProvider.bannerHeight(for: iPad, traitCollection: padTraits)
        XCTAssertLessThan(height(iPad, rowCount: 5), banner + keyArea(iPad).height(rowCount: 5))
        XCTAssertGreaterThan(height(iPad, rowCount: 5), height(iPad, rowCount: 4))
    }
}
