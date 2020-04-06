@testable import HostingApp
import XCTest

final class WordContextTests: XCTestCase {

    func test_is_continuation_of_context_returns_true_when_is_continuation() {
        var initial = WordContext(word: "testin")
        var continuation = WordContext(word: "testing")
        XCTAssertTrue(continuation.isContinuation(of: initial))

        initial = WordContext(word: "testing")
        continuation = WordContext(word: "testin")
        XCTAssertTrue(continuation.isContinuation(of: initial))
    }

    func test_is_continuation_returns_false_when_context_words_differ() {
        // we're not testing all cases here, but i'm convinced
        var initial = WordContext(secondBefore: "hi", word: "test")
        var continuation = WordContext(secondBefore: "hey", word: "test")
        XCTAssertFalse(continuation.isContinuation(of: initial))

        initial = WordContext(secondBefore: "hi", word: "test")
        continuation = WordContext(word: "test", firstAfter: "hi")
        XCTAssertFalse(continuation.isContinuation(of: initial))

        initial = WordContext(word: "test")
        continuation = WordContext(word: "testing")
        XCTAssertFalse(continuation.isContinuation(of: initial))
    }

    func test_is_variation_of_should_return_true_when_contexts_are_same_but_shifted_plus_or_minus_word() {
        let context1 = WordContext(word: "hi")
        let context1Shifted = WordContext(firstBefore: "hi", word: "test")

        XCTAssertTrue(context1.isVariationOf(context1Shifted))
        XCTAssertTrue(context1Shifted.isVariationOf(context1))

        let context2 = WordContext(word: "hi", firstAfter: "ba")
        let context2Shifted = WordContext(secondBefore: "hi", firstBefore: "ba", word: "de")

        XCTAssertTrue(context2.isVariationOf(context2Shifted))
        XCTAssertTrue(context2Shifted.isVariationOf(context2))

        let context3 = WordContext(word: "hi", firstAfter: "ba", secondAfter: "de")
        let context3Shifted = WordContext(secondBefore: "hi", firstBefore: "ba", word: "de")

        XCTAssertTrue(context3.isVariationOf(context3Shifted))
        XCTAssertTrue(context3Shifted.isVariationOf(context3))
    }

    func test_is_left_shifted_variation_of_should_return_true_when_context_is_equal_but_shifted() {
        let context1 = WordContext(word: "hi")
        let context1Shifted = WordContext(firstBefore: "hi", word: "test")

        XCTAssertTrue(context1Shifted.isLeftShiftedVariationOf(context1))

        let context2 = WordContext(firstBefore: "hey", word: "hi")
        let context2Shifted = WordContext(secondBefore: "hey", firstBefore: "hi", word: "test")

        XCTAssertTrue(context2Shifted.isLeftShiftedVariationOf(context2))

        let context3 = WordContext(secondBefore: "hey", firstBefore: "hi", word: "test")
        let context3Shifted = WordContext(secondBefore: "hi", firstBefore: "test", word: "foo")

        XCTAssertTrue(context3Shifted.isLeftShiftedVariationOf(context3))

        let context4 = WordContext(word: "hi")
        let context4Shifted = WordContext(firstBefore: "hi", word: "")

        XCTAssertTrue(context4Shifted.isLeftShiftedVariationOf(context4))
    }

    func test_is_left_shifted_variation_of_should_return_false_when_context_not_equal_or_not_shifted() {
        let context1 = WordContext(word: "hi")
        let context1Shifted = WordContext(word: "hi")

        XCTAssertFalse(context1Shifted.isLeftShiftedVariationOf(context1))

        let context2 = WordContext(word: "hi")
        let context2Shifted = WordContext(firstBefore: "test", word: "hi")

        XCTAssertFalse(context2Shifted.isLeftShiftedVariationOf(context2))

        let context3 = WordContext(firstBefore: "hey", word: "hi")
        let context3Shifted = WordContext(secondBefore: "WRONG", firstBefore: "hi", word: "test")

        XCTAssertFalse(context3Shifted.isLeftShiftedVariationOf(context3))

        let context4 = WordContext(secondBefore: "hey", firstBefore: "hi", word: "test")
        let context4Shifted = WordContext(secondBefore: "hi", firstBefore: "WRONG", word: "foo")

        XCTAssertFalse(context4Shifted.isLeftShiftedVariationOf(context4))

        let context5 = WordContext(secondBefore: "hey", firstBefore: "hi", word: "test")
        let context5Shifted = WordContext(secondBefore: nil, firstBefore: "test", word: "foo")

        XCTAssertFalse(context5Shifted.isLeftShiftedVariationOf(context5))

        let context6 = WordContext(secondBefore: "hey", firstBefore: "hi", word: "test")
        let context6Shifted = WordContext(secondBefore: "hi", firstBefore: nil, word: "foo")

        XCTAssertFalse(context6Shifted.isLeftShiftedVariationOf(context6))
    }

    func test_combining_contexts_should_work() {
        let context1 = WordContext(secondBefore: "hi", firstBefore: "hello", word: "test")
        let context2 = WordContext(secondBefore: "hello", firstBefore: "test", word: "new")
        let expected = WordContext(secondBefore: "hi", firstBefore: "hello", word: "test", firstAfter: "new")
        XCTAssertEqual(expected, context1.adding(context: context2))
    }

}
