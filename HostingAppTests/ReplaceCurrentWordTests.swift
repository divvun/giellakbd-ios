@testable import BaseKeyboard
import XCTest

final class ReplaceCurrentWordTests: XCTestCase {
    func test_cursorAtTheEndOfAWord_replacesIt() throws {
        XCTAssertEqual(try replace("hi helo|", with: "hello"), "hi hello|")
    }

    func test_cursorInsideAWord_replacesAllOfIt_andEndsUpAfterTheNewWord() throws {
        XCTAssertEqual(try replace("hi he|lo there", with: "hello"), "hi hello| there")
    }

    func test_cursorAtTheStartOfAWord_replacesIt() throws {
        XCTAssertEqual(try replace("hi |helo there", with: "hello"), "hi hello| there")
    }

    func test_onlyWord_isReplaced() throws {
        XCTAssertEqual(try replace("helo|", with: "hello"), "hello|")
    }

    func test_wordAfterANewLine_isReplaced() throws {
        XCTAssertEqual(try replace("hi\nhelo|", with: "hello"), "hi\nhello|")
    }

    func test_wordWithDiacritics_isReplaced() throws {
        XCTAssertEqual(try replace("mun čáhc|i", with: "čáhci"), "mun čáhci|")
    }

    func test_noCurrentWord_deletesNothing() throws {
        XCTAssertEqual(try replace("hi |", with: "hello"), "hi hello|")
    }

    func test_eachLetterIsDeletedSeparately() throws {
        // The text document proxy can only delete one character at a time.
        let proxy = FakeTextDocumentProxy("hi helo|")
        try proxy.deleteCurrentWord()
        proxy.insertText("hello")
        XCTAssertEqual(proxy.deleteCount, 4)
        XCTAssertEqual(proxy.insertedTexts, ["hello"])
    }

    /// `|` marks the cursor.
    private func replace(_ text: String, with input: String) throws -> String {
        let proxy = FakeTextDocumentProxy(text)
        // What the keyboard does: delete the word, then type the replacement.
        try proxy.deleteCurrentWord()
        proxy.insertText(input)
        return proxy.description
    }
}

private final class FakeTextDocumentProxy: NSObject, UITextDocumentProxy {
    private var before: [Character]
    private var after: [Character]
    private(set) var deleteCount = 0
    private(set) var insertedTexts: [String] = []

    /// `|` marks the cursor.
    init(_ text: String) {
        let parts = text.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
        before = Array(parts[0])
        after = parts.count > 1 ? Array(parts[1]) : []
    }

    override var description: String { String(before) + "|" + String(after) }

    var documentContextBeforeInput: String? { before.isEmpty ? nil : String(before) }
    var documentContextAfterInput: String? { after.isEmpty ? nil : String(after) }
    var selectedText: String? { nil }
    var documentInputMode: UITextInputMode? { nil }
    var documentIdentifier: UUID { UUID() }
    var hasText: Bool { !(before.isEmpty && after.isEmpty) }

    func adjustTextPosition(byCharacterOffset offset: Int) {
        if offset > 0 {
            before += after.prefix(offset)
            after.removeFirst(offset)
        } else if offset < 0 {
            after.insert(contentsOf: before.suffix(-offset), at: 0)
            before.removeLast(-offset)
        }
    }

    func insertText(_ text: String) {
        insertedTexts.append(text)
        before += Array(text)
    }

    func deleteBackward() {
        deleteCount += 1
        if !before.isEmpty { before.removeLast() }
    }

    func setMarkedText(_ markedText: String, selectedRange: NSRange) {}
    func unmarkText() {}
}
