@testable import HostingApp
import XCTest
import SQLite

class UserDictionaryTests: XCTestCase {
    var userDictionary = UserDictionary()
    let defaultLocale = KeyboardLocale(identifier: "en", languageName: "English")

    override func setUp() {
        userDictionary = UserDictionary()
    }

    override func tearDown() {
        userDictionary.dropTables()
    }

    func test_drop_tables_should_remove_tables() {
        let sut = userDictionary

        sut.addWordManually("test", locale: defaultLocale)
        sut.addWordManually("hello", locale: defaultLocale)
        sut.dropTables()
        userDictionary = UserDictionary() // re-create tables

        let words = sut.getUserWords(locale: defaultLocale)
        XCTAssertEqual(0, words.count)
    }

    func test_user_words_are_case_insensitive() {
        let sut = userDictionary

        sut.add(word: "test", locale: defaultLocale)
        sut.add(word: "TEST", locale: defaultLocale)
        sut.add(word: "Test", locale: defaultLocale)
        sut.add(word: "tEsT", locale: defaultLocale)

        let words = sut.getUserWords(locale: defaultLocale)
        XCTAssertEqual(1, words.count)
        XCTAssertEqual("test", words.first)
    }

    func test_word_added_once_does_not_count_as_user_word() {
        let sut = userDictionary

        sut.add(word: "test", locale: defaultLocale)

        let words = sut.getUserWords(locale: defaultLocale)
        XCTAssertEqual(0, words.count)
    }

    func test_word_added_twice_does_count_as_user_word() {
        let sut = userDictionary
        let word = "test"

        sut.add(word: word, locale: defaultLocale)
        sut.add(word: word, locale: defaultLocale)

        let words = sut.getUserWords(locale: defaultLocale)
        XCTAssertEqual(1, words.count)
        XCTAssertEqual(word, words.first)
    }

    func test_add_word_manually_should_add_word() {
        let sut = userDictionary
        let word = "test"

        sut.addWordManually(word, locale: defaultLocale)

        let words = sut.getUserWords(locale: defaultLocale)
        XCTAssertEqual(1, words.count)
        XCTAssertEqual(word, words.first)
    }

    func test_should_return_only_words_from_given_locale() {
        let sut = userDictionary
        let englishLocale = KeyboardLocale(identifier: "en", languageName: "English")
        let spanishLocale = KeyboardLocale(identifier: "es", languageName: "Spanish")

        sut.addWordManually("test1", locale: englishLocale)
        sut.addWordManually("test2", locale: spanishLocale)

        let englishWords = sut.getUserWords(locale: englishLocale)
        XCTAssertEqual(1, englishWords.count)
        XCTAssertEqual("test1", englishWords.first)
    }

    func test_add_word_manually_should_update_existing_word_if_already_in_dictionary() {
        let sut = userDictionary
        let word = "test"

        // First add the word normally
        sut.add(word: word, locale: defaultLocale) // candidate
        sut.add(word: word, locale: defaultLocale) // promoted to user word

        sut.addWordManually(word, locale: defaultLocale)

        let words = sut.getUserWords(locale: defaultLocale)
        XCTAssertEqual(1, words.count)
        XCTAssertEqual(word, words.first)
    }

    func test_get_words_should_return_words_alphabetically() {
        let sut = userDictionary

        sut.addWordManually("banana", locale: defaultLocale)
        sut.addWordManually("cantelope", locale: defaultLocale)
        sut.addWordManually("apple", locale: defaultLocale)

        let words = sut.getUserWords(locale: defaultLocale)
        XCTAssertEqual("apple", words[0])
        XCTAssertEqual("banana", words[1])
        XCTAssertEqual("cantelope", words[2])
    }

    func test_add_word_with_context_should_save_context() {
        let sut = userDictionary
        let word = "test"

        let context = WordContext(firstBefore: "before", word: word, firstAfter: "after")
        sut.add(context: context, locale: defaultLocale)

        let contexts = sut.getContexts(for: word, locale: defaultLocale)
        XCTAssertEqual(context, contexts.first)
    }

    func test_add_word_that_already_exists_as_user_word_should_not_add_new_word() {
        let sut = userDictionary
        let word = "test"

        sut.add(word: word, locale: defaultLocale) // candidate
        sut.add(word: word, locale: defaultLocale) // user word
        sut.add(word: word, locale: defaultLocale) // should have no effect

        let rows = sut.getWordDatabaseRows()
        XCTAssertEqual(1, rows.count)
    }

    func test_can_add_multiple_contexts_to_word() {
        let sut = userDictionary
        let word = "test"

        let context1 = WordContext(firstBefore: "before", word: word, firstAfter: "after")
        let context2 = WordContext(secondBefore: "secondbefore", firstBefore: "firstBefore", word: word)
        let context3 = WordContext(word: word, firstAfter: "firstAfter", secondAfter: "secondAfter")
        sut.add(context: context1, locale: defaultLocale)
        sut.add(context: context2, locale: defaultLocale)
        sut.add(context: context3, locale: defaultLocale)

        let contexts = sut.getContexts(for: word, locale: defaultLocale)
        XCTAssertEqual(3, contexts.count)
    }

    func test_word_contexts_should_come_out_of_database_in_same_form_they_went_in() {
        let sut = userDictionary
        let word1 = "test"
        let word2 = "hello"
        let word3 = "hi"

        let context1 = WordContext(firstBefore: "before", word: word1, firstAfter: "after")
        sut.add(context: context1, locale: defaultLocale)
        XCTAssertEqual(context1, sut.getContexts(for: word1, locale: defaultLocale).first)

        let context2 = WordContext(secondBefore: "secondBefore", firstBefore: "before", word: word2)
        sut.add(context: context2, locale: defaultLocale)
        XCTAssertEqual(context2, sut.getContexts(for: word2, locale: defaultLocale).first)

        let context3 = WordContext(word: word3, firstAfter: "after", secondAfter: "secondAfter")
        sut.add(context: context3, locale: defaultLocale)
        XCTAssertEqual(context3, sut.getContexts(for: word3, locale: defaultLocale).first)
    }

    func test_delete_word_should_delete_word_and_associated_contexts() {
        let sut = userDictionary
        let word = "test"
        let context1 = WordContext(firstBefore: "before", word: word, firstAfter: "after")
        let context2 = WordContext(secondBefore: "secondBefore", firstBefore: "before", word: word)

        sut.add(context: context1, locale: defaultLocale)
        sut.add(context: context2, locale: defaultLocale)
        sut.removeWord(word, locale: defaultLocale)

        let wordRows = sut.getWordDatabaseRows()
        let contextRows = sut.getContextDatabaseRows()

        XCTAssertEqual(0, wordRows.count)
        XCTAssertEqual(0, contextRows.count)
    }

    func test_insert_word_manually_should_insert_word_context() {
        let sut = userDictionary
        let word = "test"

        sut.addWordManually(word, locale: defaultLocale)

        let contexts = sut.getContexts(for: word, locale: defaultLocale)
        XCTAssertEqual(1, contexts.count)
    }

    func test_contains_word_should_return_false_if_word_not_in_dicitonary() {
        let sut = userDictionary
        let word = "test"

        let containsWord = sut.containsWord(word, locale: defaultLocale)

        XCTAssertFalse(containsWord)
    }

    func test_contains_word_should_return_true_if_word_exists_in_dictionary() {
        let sut = userDictionary
        let word = "test"

        sut.addWordManually(word, locale: defaultLocale)
        let containsWord = sut.containsWord(word, locale: defaultLocale)

        XCTAssertTrue(containsWord)
    }

    func test_update_context_should_update_context() {
        let sut = userDictionary

        let context1 = WordContext(secondBefore: "hi", firstBefore: "hello", word: "test")
        let context2 = WordContext(word: "test", firstAfter: "foo", secondAfter: "bar")
        let contextId = sut.add(context: context1, locale: defaultLocale)
        let success = sut.updateContext(contextId: contextId, newContext: context2, locale: defaultLocale)

        let contexts = sut.getContexts(for: "test", locale: defaultLocale)
        XCTAssertTrue(success)
        XCTAssertEqual(1, contexts.count)
        XCTAssertEqual(context2, contexts.first)
    }

    func test_upate_context_should_do_nothing_if_user_words_do_not_match() {
        let sut = userDictionary

        let context1 = WordContext(secondBefore: "hi", firstBefore: "hello", word: "test")
        let context2 = WordContext(word: "OTHERWORD", firstAfter: "foo", secondAfter: "bar")
        let contextId = sut.add(context: context1, locale: defaultLocale)
        let success = sut.updateContext(contextId: contextId, newContext: context2, locale: defaultLocale)

        let contexts = sut.getContexts(for: "test", locale: defaultLocale)
        XCTAssertFalse(success)
        XCTAssertEqual(1, contexts.count)
        XCTAssertEqual(context1, contexts.first)
    }
}
