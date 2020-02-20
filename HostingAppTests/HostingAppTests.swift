@testable import HostingApp
import XCTest

class UserDictionaryTests: XCTestCase {
    var userDictionary = UserDictionary()
    let defaultLocale = KeyboardLocale(identifier: "en", langaugeName: "English")

    override func setUp() {
        userDictionary.dropTables()

        // Create new connection so tables are re-created
        userDictionary = UserDictionary()
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
        let englishLocale = KeyboardLocale(identifier: "en", langaugeName: "English")
        let spanishLocale = KeyboardLocale(identifier: "es", langaugeName: "Spanish")

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
}
