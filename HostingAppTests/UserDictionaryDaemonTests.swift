@testable import HostingApp
import DivvunSpell
import XCTest

class UserDictionaryDaemonTests: XCTestCase {
    var userDictionary = UserDictionary()
    let defaultLocale = KeyboardLocale(identifier: "en", langaugeName: "English")

    override func setUp() {
        userDictionary = UserDictionary()
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

        let words = userDictionary.getUserWords(locale: defaultLocale)
        let contexts = userDictionary.getContexts(for: "hi", locale: defaultLocale)

        XCTAssertEqual(1, words.count)
        XCTAssertEqual("hi", words.first)
        XCTAssertEqual(2, contexts.count)
        XCTAssertEqual("hi", contexts.first?.word)
    }

    func test_adding_space_after_new_word_should_save_context_to_dictionary() {
        let sut = makeSUT()

        sut.updateContext(WordContext(word: "hi"))
        sut.updateContext(WordContext(firstBefore: "hi", word: ""))

        let contexts = userDictionary.getContexts(for: "hi", locale: defaultLocale)

        XCTAssertEqual(1, contexts.count)
        XCTAssertEqual("hi", contexts.first?.word)
    }

    func test_word_before_new_word_is_saved_in_context() {
        let sut = makeSUT()
        // "de" is a known word. It exists in the speller.
        let initialContext = tryMakingWordContext(leftPart: "de hi", rightPart: "")
        let finalContext = tryMakingWordContext(leftPart: "de hi ", rightPart: "")

        sut.updateContext(initialContext)
        sut.updateContext(finalContext)

        let contexts = userDictionary.getContexts(for: "hi", locale: defaultLocale)
        XCTAssertEqual("de", contexts.first?.firstBefore)
    }

    private func tryMakingWordContext(leftPart: String, rightPart: String) -> HostingApp.WordContext {
        do {
            let cursorContext = try CursorContext.from(leftPart: leftPart, rightPart: rightPart)
            return WordContext(cursorContext: cursorContext)
        } catch {
            fatalError("Error creating cursor context from leftPart: \(leftPart), rightPart: \(rightPart). Error: \(error)")
        }
    }

    private func makeSUT() -> UserDictionaryDaemon {
        let archive: ThfstChunkedBoxSpellerArchive
        guard let bundle = Bundle.top.url(forResource: "dicts", withExtension: "bundle") else {
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
            archive = try ThfstChunkedBoxSpellerArchive.open(path: path.path)
            print("DivvunSpell loaded!")
        } catch {
            fatalError("Couldn't load archive")
        }

        do {
            let speller = try archive.speller()
            return UserDictionaryDaemon(speller: speller, locale: defaultLocale)
        } catch {
            fatalError("DivvunSpell UserDictionaryDaemon **not** loaded.")
        }
    }

}
