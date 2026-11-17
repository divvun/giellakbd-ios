@testable import BaseKeyboard
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
                    Theme.current(for: traits).appearance,
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
}
