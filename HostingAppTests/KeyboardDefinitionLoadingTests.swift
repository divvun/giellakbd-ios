@testable import BaseKeyboard
import XCTest

/// An app's `KeyboardDefinitions.json` holds every layout in the app, but each keyboard uses only one.
final class KeyboardDefinitionLoadingTests: XCTestCase {
    private let locales = ["aa", "bb", "cc"]

    func test_decodesTheChosenLayout_sameAsDecodingEveryLayout() throws {
        let data = makeJSON(locales: locales)
        let all = try JSONDecoder().decode([RawKeyboardDefinition].self, from: data)

        for index in locales.indices {
            let raw = try RawKeyboardDefinition.decodeOne(from: data) { _ in index }
            XCTAssertEqual(try fingerprint(raw), try fingerprint(all[index]), "layout \(index)")
        }
    }

    func test_chosenLayout_buildsTheSameKeyboard() throws {
        let data = makeJSON(locales: locales)
        let all = try JSONDecoder().decode([RawKeyboardDefinition].self, from: data)
        let traits = UITraitCollection(userInterfaceIdiom: .phone)

        let raw = try RawKeyboardDefinition.decodeOne(from: data) { _ in 2 }
        let built = try KeyboardDefinition(fromRaw: raw, traits: traits, needsInputModeSwitchKey: false)
        let expected = try KeyboardDefinition(fromRaw: all[2], traits: traits, needsInputModeSwitchKey: false)

        XCTAssertEqual(built.locale, "cc")
        XCTAssertEqual(built.name, expected.name)
        XCTAssertEqual(String(describing: built.currentDeviceLayout?.normal.map { $0.map(\.type) }),
                       String(describing: expected.currentDeviceLayout?.normal.map { $0.map(\.type) }))
    }

    func test_chooserIsGivenEveryLocaleInOrder() throws {
        var given: [String] = []
        _ = try RawKeyboardDefinition.decodeOne(from: makeJSON(locales: locales)) { locales in
            given = locales
            return 0
        }
        XCTAssertEqual(given, locales)
    }

    func test_indexOutOfRange_throws() {
        XCTAssertThrowsError(try RawKeyboardDefinition.decodeOne(from: makeJSON(locales: locales)) { _ in 3 })
    }

    func test_bundledDefinitions_decodeTheSameAsDecodingEveryLayout() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "KeyboardDefinitions", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let all = try JSONDecoder().decode([RawKeyboardDefinition].self, from: data)

        let raw = try RawKeyboardDefinition.decodeOne(from: data) { _ in all.count - 1 }
        XCTAssertEqual(try fingerprint(raw), try fingerprint(all[all.count - 1]))
    }

    // MARK: - Helpers

    /// Every field of a layout, in a stable order (dictionaries don't print in a stable order).
    private func fingerprint(_ raw: RawKeyboardDefinition) throws -> String {
        func rows(_ rows: [[RawKeyDefinition]]?) -> String {
            String(describing: rows?.map { $0.map { "\($0.id) \($0.width)x\($0.height)" } })
        }
        func mode(_ mode: RawKeyboardMode?) -> String {
            guard let mode else { return "nil" }
            return [mode.normal, mode.shifted, mode.alt, mode.altShift, mode.symbols1, mode.symbols2].map(rows)
                .joined(separator: " | ")
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let dictionaries = try encoder.encode(Dictionaries(deadKeys: raw.deadKeys, longPress: raw.longPress,
                                                           transforms: raw.transforms))
        return [raw.name, raw.locale, raw.spaceName, raw.returnName, String(decoding: dictionaries, as: UTF8.self),
                mode(raw.iphone), mode(raw.ipad9in), mode(raw.ipad12in)].joined(separator: "\n")
    }

    private struct Dictionaries: Encodable {
        let deadKeys: [String: [String: [String]]]?
        let longPress: [String: [String]]?
        let transforms: [String: TransformTree]?
    }

    /// Layouts that differ in every field, so decoding the wrong one shows.
    private func makeJSON(locales: [String]) -> Data {
        let layouts = locales.enumerated().map { index, locale in
            """
            {
                "name": "Layout \(index)",
                "locale": "\(locale)",
                "space": "space \(index)",
                "return": "return \(index)",
                "longPress": { "\(locale)": ["\(locale)\(index)"] },
                "iphone": {
                    "normal": [["\(locale)", "x\(index)"], ["_shift", "y\(index)", "_backspace"]],
                    "shifted": [["\(locale.uppercased())", "X\(index)"], ["_shift", "Y\(index)", "_backspace"]],
                    "symbols-1": [["\(index)"]],
                    "symbols-2": [["#\(index)"]]
                }
            }
            """
        }
        return Data("[\(layouts.joined(separator: ","))]".utf8)
    }
}
