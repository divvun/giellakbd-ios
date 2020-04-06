@testable import HostingApp
import XCTest
import SQLite

private func makeSUT() -> UserDictionary {
    let locale = KeyboardLocale(identifier: "en", languageName: "English")
    return UserDictionary(locale: locale)
}

final class UserDictionaryTests: XCTestCase {
    var userDictionary = makeSUT()

    override func setUp() {
        userDictionary = makeSUT()
    }

    override func tearDown() {
        userDictionary.dropTables()
    }

    func test_drop_tables_should_remove_tables() {
        let sut = userDictionary

        sut.addWordManually("test")
        sut.addWordManually("hello")
        sut.dropTables()
        userDictionary = makeSUT() // re-create tables

        let words = sut.getUserWords()
        XCTAssertEqual(0, words.count)
    }

    func test_user_words_are_case_insensitive() {
        let sut = userDictionary

        sut.addCandidate(word: "test")
        sut.addCandidate(word: "TEST")
        sut.addCandidate(word: "Test")
        sut.addCandidate(word: "tEsT")

        let words = sut.getUserWords()
        XCTAssertEqual(1, words.count)
        XCTAssertEqual("test", words.first)
    }

    func test_word_added_once_does_not_count_as_user_word() {
        let sut = userDictionary

        sut.addCandidate(word: "test")

        let words = sut.getUserWords()
        XCTAssertEqual(0, words.count)
    }

    func test_word_added_twice_does_count_as_user_word() {
        let sut = userDictionary
        let word = "test"

        sut.addCandidate(word: word)
        sut.addCandidate(word: word)

        let words = sut.getUserWords()
        XCTAssertEqual(1, words.count)
        XCTAssertEqual(word, words.first)
    }

    func test_add_word_manually_should_add_word() {
        let sut = userDictionary
        let word = "test"

        sut.addWordManually(word)

        let words = sut.getUserWords()
        XCTAssertEqual(1, words.count)
        XCTAssertEqual(word, words.first)
    }

    func test_should_return_only_words_from_given_locale() {
        let englishLocale = KeyboardLocale(identifier: "en", languageName: "English")
        let spanishLocale = KeyboardLocale(identifier: "es", languageName: "Spanish")

        let englishDict = UserDictionary(locale: englishLocale)
        let spanishDict = UserDictionary(locale: spanishLocale)

        englishDict.addWordManually("test1")
        spanishDict.addWordManually("test2")

        let englishWords = englishDict.getUserWords()
        XCTAssertEqual(1, englishWords.count)
        XCTAssertEqual("test1", englishWords.first)

        let spanishWords = spanishDict.getUserWords()
        XCTAssertEqual(1, spanishWords.count)
        XCTAssertEqual("test2", spanishWords.first)
    }

    func test_add_word_manually_should_update_existing_word_if_already_in_dictionary() {
        let sut = userDictionary
        let word = "test"

        // First add the word normally
        sut.addCandidate(word: word) // candidate
        sut.addCandidate(word: word) // promoted to user word

        sut.addWordManually(word)

        let words = sut.getUserWords()
        XCTAssertEqual(1, words.count)
        XCTAssertEqual(word, words.first)
    }

    func test_get_words_should_return_words_alphabetically() {
        let sut = userDictionary

        sut.addWordManually("banana")
        sut.addWordManually("cantelope")
        sut.addWordManually("apple")

        let words = sut.getUserWords()
        XCTAssertEqual("apple", words[0])
        XCTAssertEqual("banana", words[1])
        XCTAssertEqual("cantelope", words[2])
    }

    func test_add_word_with_context_should_save_context() {
        let sut = userDictionary
        let word = "test"

        let context = WordContext(firstBefore: "before", word: word, firstAfter: "after")
        sut.addCandidate(context: context)

        let contexts = sut.getContexts(for: word)
        XCTAssertEqual(context, contexts.first)
    }

    func test_add_word_that_already_exists_as_user_word_should_not_add_new_word() {
        let sut = userDictionary
        let word = "test"

        sut.addCandidate(word: word) // candidate
        sut.addCandidate(word: word) // user word
        sut.addCandidate(word: word) // should have no effect

        let rows = sut.getWordDatabaseRows()
        XCTAssertEqual(1, rows.count)
    }

    func test_can_add_multiple_contexts_to_word() {
        let sut = userDictionary
        let word = "test"

        let context1 = WordContext(firstBefore: "before", word: word, firstAfter: "after")
        let context2 = WordContext(secondBefore: "secondbefore", firstBefore: "firstBefore", word: word)
        let context3 = WordContext(word: word, firstAfter: "firstAfter", secondAfter: "secondAfter")
        sut.addCandidate(context: context1)
        sut.addCandidate(context: context2)
        sut.addCandidate(context: context3)

        let contexts = sut.getContexts(for: word)
        XCTAssertEqual(3, contexts.count)
    }

    func test_word_contexts_should_come_out_of_database_in_same_form_they_went_in() {
        let sut = userDictionary
        let word1 = "test"
        let word2 = "hello"
        let word3 = "hi"

        let context1 = WordContext(firstBefore: "before", word: word1, firstAfter: "after")
        sut.addCandidate(context: context1)
        XCTAssertEqual(context1, sut.getContexts(for: word1).first)

        let context2 = WordContext(secondBefore: "secondBefore", firstBefore: "before", word: word2)
        sut.addCandidate(context: context2)
        XCTAssertEqual(context2, sut.getContexts(for: word2).first)

        let context3 = WordContext(word: word3, firstAfter: "after", secondAfter: "secondAfter")
        sut.addCandidate(context: context3)
        XCTAssertEqual(context3, sut.getContexts(for: word3).first)
    }

    func test_delete_word_should_delete_word_and_associated_contexts() {
        let sut = userDictionary
        let word = "test"
        let context1 = WordContext(firstBefore: "before", word: word, firstAfter: "after")
        let context2 = WordContext(secondBefore: "secondBefore", firstBefore: "before", word: word)

        sut.addCandidate(context: context1)
        sut.addCandidate(context: context2)
        sut.removeWord(word)

        let wordRows = sut.getWordDatabaseRows()
        let contextRows = sut.getContextDatabaseRows()

        XCTAssertEqual(0, wordRows.count)
        XCTAssertEqual(0, contextRows.count)
    }

    func test_delete_word_should_delete_only_for_current_context() {
        let englishLocale = KeyboardLocale(identifier: "en", languageName: "English")
        let spanishLocale = KeyboardLocale(identifier: "es", languageName: "Spanish")

        let englishDict = UserDictionary(locale: englishLocale)
        let spanishDict = UserDictionary(locale: spanishLocale)

        englishDict.addWordManually("test")
        spanishDict.addWordManually("test")

        let englishWords = englishDict.getUserWords()
        XCTAssertEqual(1, englishWords.count)
        XCTAssertEqual("test", englishWords.first)

        let spanishWords = spanishDict.getUserWords()
        XCTAssertEqual(1, spanishWords.count)
        XCTAssertEqual("test", spanishWords.first)

        englishDict.removeWord("test")
        XCTAssertEqual(0, englishDict.getUserWords().count)
        XCTAssertEqual(1, spanishDict.getUserWords().count)

        spanishDict.removeWord("test")
        XCTAssertEqual(0, englishDict.getUserWords().count)
        XCTAssertEqual(0, spanishDict.getUserWords().count)
    }

    func test_insert_word_manually_should_insert_word_context() {
        let sut = userDictionary
        let word = "test"

        sut.addWordManually(word)

        let contexts = sut.getContexts(for: word)
        XCTAssertEqual(1, contexts.count)
    }

    func test_contains_word_should_return_false_if_word_not_in_dicitonary() {
        let sut = userDictionary
        let word = "test"

        let containsWord = sut.containsWord(word)

        XCTAssertFalse(containsWord)
    }

    func test_contains_word_should_return_true_if_word_exists_in_dictionary() {
        let sut = userDictionary
        let word = "test"

        sut.addWordManually(word)
        let containsWord = sut.containsWord(word)

        XCTAssertTrue(containsWord)
    }

    func test_update_context_should_update_context() {
        let sut = userDictionary

        let context1 = WordContext(secondBefore: "hi", firstBefore: "hello", word: "test")
        let context2 = WordContext(word: "test", firstAfter: "foo", secondAfter: "bar")
        let contextId = sut.addCandidate(context: context1)
        let success = sut.updateContext(contextId: contextId, newContext: context2)

        let contexts = sut.getContexts(for: "test")
        XCTAssertTrue(success)
        XCTAssertEqual(1, contexts.count)
        XCTAssertEqual(context2, contexts.first)
    }

    func test_upate_context_should_do_nothing_if_user_words_do_not_match() {
        let sut = userDictionary

        let context1 = WordContext(secondBefore: "hi", firstBefore: "hello", word: "test")
        let context2 = WordContext(word: "OTHERWORD", firstAfter: "foo", secondAfter: "bar")
        let contextId = sut.addCandidate(context: context1)
        let success = sut.updateContext(contextId: contextId, newContext: context2)

        let contexts = sut.getContexts(for: "test")
        XCTAssertFalse(success)
        XCTAssertEqual(1, contexts.count)
        XCTAssertEqual(context1, contexts.first)
    }
}
