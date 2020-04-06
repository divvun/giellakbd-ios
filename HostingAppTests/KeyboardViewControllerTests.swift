@testable import BaseKeyboard
import XCTest

final class KeyboardViewControllerTests: XCTestCase {
    // This test isn't accurate because textDocumentProxy.autocapitalizationType isn't .sentences.
    // Leaving as a reference for creating other KeyboardViewController tests

//    func test_keyboard_should_auto_shift_after_full_stop() {
//        let sut = KeyboardViewController(withBanner: true)
//        sut.viewDidLoad()

//        sut.insertText("H")
//        sut.insertText("i")
//        sut.insertText(" ")
//        sut.insertText(" ")

//        XCTAssertEqual("Hi. ", sut.textDocumentProxy.documentContextBeforeInput)
//        XCTAssertEqual(.shifted, sut.page)
//    }
}
