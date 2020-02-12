public struct WordContext {
    let word0: String
    let word1: String?
    let word2: String?
    let userWord: String

    private var userWordIsFirstWord: Bool {
        word0 == userWord
    }

    private var userWordIsLastWord: Bool {
        if let word2 = word2 {
            return word2 == userWord
        } else if let word1 = word1 {
            return word1 == word1
        }
        return true
    }

    public func contextString() -> String {
        var contextString = word0
        if let word1 = word1 {
            contextString += " \(word1)"
        }
        if let word2 = word2 {
            contextString += " \(word2)"
        }

        if !userWordIsFirstWord {
            contextString = "... " + contextString
        }

        if userWordIsLastWord {
            contextString += "."
        } else {
            contextString += " ..."
        }

        return contextString
    }
}
