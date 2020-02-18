@testable import HostingApp
import XCTest

class UserDictionaryTests: XCTestCase {
    let userDictionary = UserDictionary()

    override func setUp() {
        userDictionary.deleteAllWords()
    }

    func test_delete_database_removes_all_words() {
        let sut = userDictionary

        for _ in 0...5 {
            // add multple times to be sure it becomes a "user word"
            // if the word only exists once in the db, it won't be returned as a word
            sut.add(word0: "test")
        }
        sut.deleteAllWords()

        let rows = sut.getUserWords()
        XCTAssertEqual(0, rows.count)
    }

    func test_user_words_are_case_insensitive() {
        let sut = userDictionary

        sut.add(word0: "test")
        sut.add(word0: "TEST")
        sut.add(word0: "Test")

        let words = sut.getUserWords()
        XCTAssertEqual(1, words.count)
        XCTAssertEqual("test", words.first)
    }

    func test_word_added_once_does_not_count_as_user_word() {
        let sut = userDictionary

        sut.add(word0: "test")

        let words = sut.getUserWords()
        XCTAssertEqual(0, words.count)
    }

    func test_word_added_twice_does_count_as_user_word() {
        let sut = userDictionary
        let word = "test"

        sut.add(word0: word)
        sut.add(word0: word)

        let words = sut.getUserWords()
        XCTAssertEqual(1, words.count)
        XCTAssertEqual(word, words.first)
    }
}
