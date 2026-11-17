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

        let words = userDictionary.getDetectedAndUserDefinedWords()
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

    // This test is currently invalid because, at the time of this writing, the se.bhfst speller will
    // always suggest a single typed character as the default selection.
    // To verify this, open the keyboard and type a letter. The spell banner should show that letter as
    // the **bolded** option.
//    func test_both_words_after_should_be_saved_when_typed_after_new_single_character_word() {
//        let sut = makeSUT()
//        let context1 = WordContext(word: "j")
//        let context2 = WordContext(firstBefore: "j", word: "ba")
//        let context3 = WordContext(secondBefore: "j", firstBefore: "ba", word: "de")
//        let context4 = WordContext(secondBefore: "ba", firstBefore: "de", word: "")
//
//        sut.updateContext(context1)
//        sut.updateContext(context2)
//        sut.updateContext(context3)
//        sut.updateContext(context4)
//
//        let contexts = userDictionary.getContexts(for: "j")
//        XCTAssertEqual(1, contexts.count)
//        XCTAssertNil(contexts.first?.secondBefore)
//        XCTAssertNil(contexts.first?.firstBefore)
//        XCTAssertEqual("j", contexts.first?.word)
//        XCTAssertEqual("ba", contexts.first?.firstAfter)
//        XCTAssertEqual("de", contexts.first?.secondAfter)
//    }

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

    // MARK: - Picking a suggestion

    func test_pickingASuggestion_oneDeletionAtATime_learnsTheSuggestionButNotTheTypo() {
        let sut = makeSUT()

        typeWord("zorb", into: sut)
        for word in ["zor", "zo", "z", ""] { // each deletion looks like the same word getting shorter
            sut.updateContext(WordContext(word: word))
        }
        sut.updateContext(WordContext(word: "zorp"))
        sut.updateContext(WordContext(firstBefore: "zorp", word: ""))

        XCTAssertFalse(userDictionary.containsWord("zorb"))
        XCTAssertTrue(userDictionary.containsWord("zorp"))
    }

    func test_replacingAWordInOneStep_learnsTheReplacedWord() {
        let sut = makeSUT()

        typeWord("zorb", into: sut)
        sut.updateContext(WordContext(word: "zorp"))

        // Without being told otherwise, a word changing into a different one looks like a finished word.
        XCTAssertTrue(userDictionary.containsWord("zorb"))
    }

    func test_discardingTheCurrentWord_thenReplacingIt_learnsOnlyTheSuggestion() {
        let sut = makeSUT()

        typeWord("zorb", into: sut)
        sut.discardCurrentWord()
        sut.updateContext(WordContext(word: "zorp"))
        sut.updateContext(WordContext(firstBefore: "zorp", word: ""))

        XCTAssertFalse(userDictionary.containsWord("zorb"))
        XCTAssertTrue(userDictionary.containsWord("zorp"))
        XCTAssertFalse(userDictionary.containsWord(""))
    }

    func test_discardingTheCurrentWord_keepsTheWordBefore_andAddsTheSuggestionAfterIt() {
        let sut = makeSUT()

        typeWord("xxx", into: sut)
        sut.updateContext(WordContext(firstBefore: "xxx", word: ""))
        typeWord("zorb", firstBefore: "xxx", into: sut)
        sut.discardCurrentWord()
        sut.updateContext(WordContext(firstBefore: "xxx", word: "zorp"))
        sut.updateContext(WordContext(secondBefore: "xxx", firstBefore: "zorp", word: ""))

        XCTAssertEqual(userDictionary.getContexts(for: "xxx").first?.firstAfter, "zorp")
        XCTAssertEqual(userDictionary.getContexts(for: "zorp").first?.firstBefore, "xxx")
        XCTAssertFalse(userDictionary.containsWord("zorb"))
    }

    func test_discardingTheCurrentWord_whenNothingIsTyped_doesNothing() {
        let sut = makeSUT()

        sut.discardCurrentWord()
        typeWord("hi", into: sut)
        sut.updateContext(WordContext(firstBefore: "hi", word: ""))

        XCTAssertTrue(userDictionary.containsWord("hi"))
    }

    /// Updates the context once per letter, the way typing does.
    private func typeWord(_ word: String, firstBefore: String? = nil, into sut: UserDictionaryService) {
        for length in 1...word.count {
            sut.updateContext(WordContext(firstBefore: firstBefore, word: String(word.prefix(length))))
        }
    }

    private func makeSUT() -> UserDictionaryService {
        let archive: SpellerArchive
        guard let bundle = Bundle(for: type(of: self)).url(forResource: "dicts", withExtension: "bundle") else {
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
            archive = try SpellerArchive.open(path: path.path)
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
