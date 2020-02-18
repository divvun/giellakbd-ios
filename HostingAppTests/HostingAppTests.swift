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

    func test_delete_database_removes_all_words() {
        let sut = userDictionary

        for _ in 0...5 {
            // add multple times to be sure it becomes a "user word"
            // if the word only exists once in the db, it won't be returned as a word
            sut.add(word0: "test", locale: defaultLocale)
        }
        sut.deleteAllWords()

        let rows = sut.getUserWords(locale: defaultLocale)
        XCTAssertEqual(0, rows.count)
    }

    func test_user_words_are_case_insensitive() {
        let sut = userDictionary

        sut.add(word0: "test", locale: defaultLocale)
        sut.add(word0: "TEST", locale: defaultLocale)
        sut.add(word0: "Test", locale: defaultLocale)

        let words = sut.getUserWords(locale: defaultLocale)
        XCTAssertEqual(1, words.count)
        XCTAssertEqual("test", words.first)
    }

    func test_word_added_once_does_not_count_as_user_word() {
        let sut = userDictionary

        sut.add(word0: "test", locale: defaultLocale)

        let words = sut.getUserWords(locale: defaultLocale)
        XCTAssertEqual(0, words.count)
    }

    func test_word_added_twice_does_count_as_user_word() {
        let sut = userDictionary
        let word = "test"

        sut.add(word0: word, locale: defaultLocale)
        sut.add(word0: word, locale: defaultLocale)

        let words = sut.getUserWords(locale: defaultLocale)
        XCTAssertEqual(1, words.count)
        XCTAssertEqual(word, words.first)
    }

    func test_add_user_word_should_add_user_word() {
        let sut = userDictionary
        let word = "test"

        sut.addUserWord(word, locale: defaultLocale)

        let words = sut.getUserWords(locale: defaultLocale)
        XCTAssertEqual(1, words.count)
        XCTAssertEqual(word, words.first)
    }

    func test_should_return_only_words_from_given_locale() {
        let sut = userDictionary
        let englishLocale = KeyboardLocale(identifier: "en", langaugeName: "English")
        let spanishLocale = KeyboardLocale(identifier: "es", langaugeName: "Spanish")

        sut.addUserWord("test1", locale: englishLocale)
        sut.addUserWord("test2", locale: spanishLocale)

        let englishWords = sut.getUserWords(locale: englishLocale)
        XCTAssertEqual(1, englishWords.count)
        XCTAssertEqual("test1", englishWords.first)
    }
}
