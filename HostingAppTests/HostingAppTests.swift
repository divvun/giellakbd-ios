@testable import HostingApp
import XCTest

class UserDictionaryTests: XCTestCase {

    func test_delete_database_removes_all_words() {
        let sut = UserDictionary()

        for _ in 0...5 {
            // add multple times to be sure it becomes a "user word"
            // if the word only exists once in the db, it won't be returned as a word
            sut.add(word0: "test")
        }
        sut.deleteAllWords()

        let rows = sut.getUserWords()
        XCTAssertEqual(0, rows.count)
    }

}
