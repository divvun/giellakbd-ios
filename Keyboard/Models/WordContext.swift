import Foundation

public struct WordContext {
    let word0: String
    let word1: String?
    let word2: String?
    let userWord: String

    public func contextAttributedString() -> NSAttributedString {
        var contextString = word0
        if let word1 = word1 {
            contextString += " \(word1)"
        }
        if let word2 = word2 {
            contextString += " \(word2)"
        }

        return contextString.bolden(substring: userWord, caseInsensitive: true)
    }
}
