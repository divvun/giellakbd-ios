@testable import HostingApp
import DivvunSpell
import XCTest

private let defaultLocale = KeyboardLocale(identifier: "en", languageName: "English")
private func makeDict() -> UserDictionary {
    return UserDictionary(locale: defaultLocale)
}

final class UserDictionaryServiceTests: XCTestCase {
    var userDictionary = makeDict()

    override func setUp() {
        userDictionary = makeDict()
    }

    override func tearDown() {
        userDictionary.dropTables()
    }

    func test_updating_same_context_twice_should_add_user_word_to_dictionary() {
        let sut = makeSUT()

        sut.updateContext(WordContext(word: "hi"))
        sut.updateContext(WordContext(firstBefore: "hi", word: ""))

        sut.updateContext(WordContext(word: "hi"))
        sut.updateContext(WordContext(firstBefore: "hi", word: ""))

        let words = userDictionary.getUserWords()
        let contexts = userDictionary.getContexts(for: "hi")

        XCTAssertEqual(1, words.count)
        XCTAssertEqual("hi", words.first)
        XCTAssertEqual(2, contexts.count)
        XCTAssertEqual("hi", contexts.first?.word)
    }

    func test_adding_space_after_new_word_should_save_context_to_dictionary() {
        let sut = makeSUT()

        sut.updateContext(WordContext(word: "hi"))
        sut.updateContext(WordContext(firstBefore: "hi", word: ""))

        let contexts = userDictionary.getContexts(for: "hi")

        XCTAssertEqual(1, contexts.count)
        XCTAssertEqual("hi", contexts.first?.word)
    }

    func test_word_before_new_word_should_be_saved_in_context() {
        let sut = makeSUT()
        let initialContext = WordContext(firstBefore: "de", word: "hi")
        let finalContext = WordContext(secondBefore: "de", firstBefore: "hi", word: "")

        sut.updateContext(initialContext)
        sut.updateContext(finalContext)

        let contexts = userDictionary.getContexts(for: "hi")
        XCTAssertEqual("de", contexts.first?.firstBefore)
        XCTAssertEqual("hi", contexts.first?.word)
    }

    func test_both_words_before_new_word_should_be_saved_in_context() {
        let sut = makeSUT()
        let initialContext = WordContext(secondBefore: "de", firstBefore: "ge", word: "hi")
        let finalContext = WordContext(secondBefore: "ge", firstBefore: "hi", word: "")

        sut.updateContext(initialContext)
        sut.updateContext(finalContext)

        let contexts = userDictionary.getContexts(for: "hi")
        XCTAssertEqual("de", contexts.first?.secondBefore)
        XCTAssertEqual("ge", contexts.first?.firstBefore)
        XCTAssertEqual("hi", contexts.first?.word)
    }

    func test_word_before_and_after_context_should_replace_secondBefore_and_firstBefore_context() {
        let sut = makeSUT()
        let context1 = WordContext(secondBefore: "de", firstBefore: "ge", word: "hi")
        let context2 = WordContext(secondBefore: "ge", firstBefore: "hi", word: "")
        let context3 = WordContext(secondBefore: "ge", firstBefore: "hi", word: "ba")
        let context4 = WordContext(secondBefore: "hi", firstBefore: "ba", word: "")

        sut.updateContext(context1)
        sut.updateContext(context2)
        sut.updateContext(context3)
        sut.updateContext(context4)

        let contexts = userDictionary.getContexts(for: "hi")
        XCTAssertEqual(1, contexts.count)
        XCTAssertEqual("de", contexts.first?.secondBefore) // this could arguably be nil
        XCTAssertEqual("ge", contexts.first?.firstBefore)
        XCTAssertEqual("hi", contexts.first?.word)
        XCTAssertEqual("ba", contexts.first?.firstAfter)
        XCTAssertNil(contexts.first?.secondAfter)
    }

    func test_word_after_should_be_saved_when_typed_after_new_word() {
        let sut = makeSUT()
        let context1 = WordContext(word: "hi")
        let context2 = WordContext(firstBefore: "hi", word: "ba")
        let context3 = WordContext(secondBefore: "hi", firstBefore: "ba", word: "")

        sut.updateContext(context1)
        sut.updateContext(context2)
        sut.updateContext(context3)

        let contexts = userDictionary.getContexts(for: "hi")
        XCTAssertEqual(1, contexts.count)
        XCTAssertNil(contexts.first?.secondBefore)
        XCTAssertNil(contexts.first?.firstBefore)
        XCTAssertEqual("hi", contexts.first?.word)
        XCTAssertEqual("ba", contexts.first?.firstAfter)
        XCTAssertNil(contexts.first?.secondAfter)
    }

    func test_both_words_after_should_be_saved_when_typed_after_new_word() {
        let sut = makeSUT()
        let context1 = WordContext(word: "hi")
        let context2 = WordContext(firstBefore: "hi", word: "ba")
        let context3 = WordContext(secondBefore: "hi", firstBefore: "ba", word: "de")
        let context4 = WordContext(secondBefore: "ba", firstBefore: "de", word: "")

        sut.updateContext(context1)
        sut.updateContext(context2)
        sut.updateContext(context3)
        sut.updateContext(context4)

        let contexts = userDictionary.getContexts(for: "hi")
        XCTAssertEqual(1, contexts.count)
        XCTAssertNil(contexts.first?.secondBefore)
        XCTAssertNil(contexts.first?.firstBefore)
        XCTAssertEqual("hi", contexts.first?.word)
        XCTAssertEqual("ba", contexts.first?.firstAfter)
        XCTAssertEqual("de", contexts.first?.secondAfter)
    }

    func test_both_words_after_should_be_saved_when_typed_after_new_single_character_word() {
        let sut = makeSUT()
        let context1 = WordContext(word: "j")
        let context2 = WordContext(firstBefore: "j", word: "ba")
        let context3 = WordContext(secondBefore: "j", firstBefore: "ba", word: "de")
        let context4 = WordContext(secondBefore: "ba", firstBefore: "de", word: "")

        sut.updateContext(context1)
        sut.updateContext(context2)
        sut.updateContext(context3)
        sut.updateContext(context4)

        let contexts = userDictionary.getContexts(for: "j")
        XCTAssertEqual(1, contexts.count)
        XCTAssertNil(contexts.first?.secondBefore)
        XCTAssertNil(contexts.first?.firstBefore)
        XCTAssertEqual("j", contexts.first?.word)
        XCTAssertEqual("ba", contexts.first?.firstAfter)
        XCTAssertEqual("de", contexts.first?.secondAfter)
    }

    func test_word_before_and_after_should_remain_after_entering_second_after_word() {
        let sut = makeSUT()
        let context1 = WordContext(firstBefore: "ge", word: "hi")
        let context2 = WordContext(secondBefore: "ge", firstBefore: "hi", word: "ba")
        let context3 = WordContext(secondBefore: "hi", firstBefore: "ba", word: "de")
        let context4 = WordContext(secondBefore: "ba", firstBefore: "de", word: "")

        sut.updateContext(context1)
        sut.updateContext(context2)
        sut.updateContext(context3)
        sut.updateContext(context4)

        let contexts = userDictionary.getContexts(for: "hi")
        XCTAssertEqual(1, contexts.count)
        XCTAssertNil(contexts.first?.secondBefore)
        XCTAssertEqual("ge", contexts.first?.firstBefore)
        XCTAssertEqual("hi", contexts.first?.word)
        XCTAssertEqual("ba", contexts.first?.firstAfter)
        XCTAssertNil(contexts.first?.secondAfter)
    }

    func test_two_consecutive_unknown_words_should_both_be_saved() {
        let sut = makeSUT()

        let context1 = WordContext(word: "xxx")
        let context2 = WordContext(firstBefore: "xxx", word: "yyy")
        let context3 = WordContext(secondBefore: "xxx", firstBefore: "yyy", word: "") //zzz

        sut.updateContext(context1)
        sut.updateContext(context2)
        sut.updateContext(context3)

        var contexts = userDictionary.getContexts(for: "xxx")
        XCTAssertEqual(1, contexts.count)
        XCTAssertNil(contexts.first?.secondBefore)
        XCTAssertNil(contexts.first?.firstBefore)
        XCTAssertEqual("xxx", contexts.first?.word)
        XCTAssertEqual("yyy", contexts.first?.firstAfter)
        XCTAssertNil(contexts.first?.secondAfter)

        contexts = userDictionary.getContexts(for: "yyy")
        XCTAssertEqual(1, contexts.count)
        XCTAssertNil(contexts.first?.secondBefore)
        XCTAssertEqual("xxx", contexts.first?.firstBefore)
        XCTAssertEqual("yyy", contexts.first?.word)
        XCTAssertNil(contexts.first?.firstAfter)
        XCTAssertNil(contexts.first?.secondAfter)
    }

    private func makeSUT() -> UserDictionaryService {
        let archive: ThfstChunkedBoxSpellerArchive
        guard let bundle = Bundle.top.url(forResource: "dicts", withExtension: "bundle") else {
            fatalError("No dict bundle found; BHFST not loaded.")
        }

        let lang = "se"
        let path = bundle.appendingPathComponent("\(lang).bhfst")

        if !FileManager.default.fileExists(atPath: path.path) {
            let message = "No speller at: \(path)\n Important: In order to run tests,"
            + " you must have an 'se.bhfst' file installed in 'dicts.bundle'"
            fatalError(message)
        }

        do {
            archive = try ThfstChunkedBoxSpellerArchive.open(path: path.path)
            print("DivvunSpell loaded!")
        } catch {
            fatalError("Couldn't load archive")
        }

        do {
            let speller = try archive.speller()
            return UserDictionaryService(speller: speller, locale: defaultLocale)
        } catch {
            fatalError("DivvunSpell UserDictionaryService **not** loaded.")
        }
    }

}
