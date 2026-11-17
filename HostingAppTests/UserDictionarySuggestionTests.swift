@testable import HostingApp
import XCTest

final class LevenshteinTests: XCTestCase {
    /// Distances from the original implementation, which these must keep matching.
    private let cases: [(String, String, Int)] = [
        ("kitten", "sitting", 3),
        ("", "abc", 3),
        ("abc", "", 3),
        ("", "", 0),
        ("flaw", "lawn", 2),
        ("same", "same", 0),
        ("čáhci", "cahci", 2),
        ("e\u{301}", "\u{e9}", 0), // decomposed and precomposed é are the same Character
        ("👍🏽", "👍", 1),
        ("helo", "hello", 1),
        ("helo", "help", 1),
        ("helo", "yellow", 3),
        ("helo", "world", 4),
        ("helo", "helicopter", 6),
        ("helo", "hi", 3),
        ("Helo", "hello", 2),
        ("ab", "ba", 2)
    ]

    func test_distances() {
        for (a, b, expected) in cases {
            XCTAssertEqual(a.levenshtein(b), expected, "\(a) → \(b)")
            XCTAssertEqual(b.levenshtein(a), expected, "\(b) → \(a)")
        }
    }

    func test_boundedDistance_isTheDistanceWithinTheLimit_otherwiseNil() {
        for (a, b, expected) in cases {
            for limit in 0...7 {
                XCTAssertEqual(a.levenshtein(b, maxDistance: limit), expected <= limit ? expected : nil,
                               "\(a) → \(b), limit \(limit)")
            }
        }
    }
}

final class UserDictionarySuggestionTests: XCTestCase {
    private var sut: UserDictionary!

    override func setUp() {
        super.setUp()
        sut = UserDictionary(locale: KeyboardLocale(identifier: "en", languageName: "English"))
    }

    override func tearDown() {
        sut.dropTables()
        sut = nil
        super.tearDown()
    }

    func test_suggestions_areWordsWithinThreeEdits_closestFirst() {
        for word in ["yellow", "world", "help", "helicopter", "hi", "hello"] {
            sut.addWordManually(word)
        }
        XCTAssertEqual(sut.getSuggestions(for: "helo"), ["hello", "help", "hi", "yellow"])
    }

    func test_suggestions_includeDetectedWords() {
        sut.addCandidate(word: "hello")
        sut.addCandidate(word: "hello") // seen twice, so detected
        XCTAssertEqual(sut.getSuggestions(for: "helo"), ["hello"])
    }

    func test_suggestions_excludeCandidatesAndBlacklistedWords() {
        sut.addCandidate(word: "hello") // seen once, still a candidate
        sut.addWordManually("help")
        sut.blacklistWord("help")
        XCTAssertEqual(sut.getSuggestions(for: "helo"), [])
    }

    func test_noWords_noSuggestions() {
        XCTAssertEqual(sut.getSuggestions(for: "helo"), [])
    }
}
