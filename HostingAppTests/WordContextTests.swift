@testable import HostingApp
import XCTest

class WordContextTests: XCTestCase {

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
}
