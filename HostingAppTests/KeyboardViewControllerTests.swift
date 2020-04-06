@testable import BaseKeyboard
import XCTest

final class KeyboardViewControllerTests: XCTestCase {
    func test_keyboard_should_auto_shift_after_full_stop() {
        let sut = KeyboardViewController(withBanner: true)
        sut.viewDidLoad()

        sut.insertText("H")
        sut.insertText("i")
        sut.insertText(" ")
        sut.insertText(" ")

        XCTAssertEqual("Hi. ", sut.textDocumentProxy.documentContextBeforeInput)
        XCTAssertEqual(sut.page, .shifted)
    }
}
