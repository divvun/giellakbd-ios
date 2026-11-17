@testable import BaseKeyboard
import DivvunSpell
import XCTest

final class SpellBannerSuggestionsTests: XCTestCase {
    // MARK: - Banner items

    func test_incorrectWord_firstSuggestionIsACorrection() {
        let items = SpellBanner.makeSuggestionBannerItems(
            currentWord: "helo", suggestions: ["hello", "help"], isWordCorrect: false
        )
        XCTAssertEqual(items.map(describe), ["human:helo:false=helo", "correction:hello=hello", "normal:help=help"])
    }

    func test_correctWord_hasNoCorrection() {
        let items = SpellBanner.makeSuggestionBannerItems(
            currentWord: "help", suggestions: ["hello", "held"], isWordCorrect: true
        )
        XCTAssertEqual(items.map(describe), ["human:help:true=help", "normal:hello=hello", "normal:held=held"])
    }

    func test_currentWordIsNotSuggestedTwice() {
        let items = SpellBanner.makeSuggestionBannerItems(
            currentWord: "help", suggestions: ["help", "hello", "help"], isWordCorrect: false
        )
        XCTAssertEqual(items.map(describe), ["human:help:false=help", "correction:hello=hello"])
    }

    func test_userDictionaryMarker_isKeptInTitleButNotValue() {
        let items = SpellBanner.makeSuggestionBannerItems(
            currentWord: "helo", suggestions: ["*heloo", "hello"], isWordCorrect: false
        )
        XCTAssertEqual(items.map(describe), ["human:helo:false=helo", "correction:*heloo=heloo", "normal:hello=hello"])
    }

    func test_noSuggestions_showsOnlyTheCurrentWord() {
        let items = SpellBanner.makeSuggestionBannerItems(currentWord: "helo", suggestions: [], isWordCorrect: false)
        XCTAssertEqual(items.map(describe), ["human:helo:false=helo"])
    }

    // MARK: - Suggestion operation

    func test_operation_checksTheWordWithTheSpeller() throws {
        let speller = try makeSpeller()
        let misspelt = "xqzwv"
        // Common North Sámi words, so the loop covers both answers.
        let known = try XCTUnwrap(["ja", "mun", "son", "sámegiella"].first { (try? speller.isCorrect(word: $0)) == true })

        for word in [misspelt, known] {
            let outcome = try XCTUnwrap(result(for: word, speller: speller))
            XCTAssertEqual(outcome.isWordCorrect, try speller.isCorrect(word: word), word)
            XCTAssertEqual(outcome.suggestions, Array(try speller.suggest(word: word).prefix(3)), word)
        }
    }

    func test_operation_withoutASpeller_givesNoResult() {
        XCTAssertNil(result(for: "helo", speller: nil))
    }

    func test_operation_cancelled_doesNotComplete() throws {
        let completed = expectation(description: "completion")
        completed.isInverted = true
        let op = SuggestionOperation(userDictionary: nil, speller: try makeSpeller(), word: "helo") { _ in
            completed.fulfill()
        }
        op.cancel()
        op.start()
        wait(for: [completed], timeout: 0.2)
    }

    func test_operation_completesOnTheMainThread() throws {
        let speller = try makeSpeller()
        let done = expectation(description: "completion")
        let op = SuggestionOperation(userDictionary: nil, speller: speller, word: "helo") { _ in
            XCTAssertTrue(Thread.isMainThread)
            done.fulfill()
        }
        let queue = OperationQueue()
        queue.addOperation(op)
        wait(for: [done], timeout: 5)
    }

    // MARK: - Helpers

    private func result(for word: String, speller: Speller?) -> SuggestionResult? {
        let done = expectation(description: "completion")
        var result: SuggestionResult?
        let op = SuggestionOperation(userDictionary: nil, speller: speller, word: word) {
            result = $0
            done.fulfill()
        }
        op.start()
        wait(for: [done], timeout: 5)
        return result
    }

    private func describe(_ item: SpellBannerItem) -> String {
        switch item.title {
        case .humanInput(let word, let isCorrect):
            return "human:\(word):\(isCorrect)=\(item.value)"
        case .correction(let word):
            return "correction:\(word)=\(item.value)"
        case .normal(let word):
            return "normal:\(word)=\(item.value)"
        }
    }

    private func makeSpeller() throws -> Speller {
        let bundle = try XCTUnwrap(Bundle(for: type(of: self)).url(forResource: "dicts", withExtension: "bundle"))
        let path = bundle.appendingPathComponent("se.bhfst").path
        return try SpellerArchive.open(path: path).speller()
    }
}
