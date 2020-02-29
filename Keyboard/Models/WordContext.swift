import Foundation
import DivvunSpell

public struct WordContext: Equatable {
    let secondBefore: String?
    let firstBefore: String?
    let word: String
    let firstAfter: String?
    let secondAfter: String?

    init(secondBefore: String? = nil,
         firstBefore: String? = nil,
         word: String,
         firstAfter: String? = nil,
         secondAfter: String? = nil) {
        self.secondBefore = secondBefore
        self.firstBefore = firstBefore
        self.word = word
        self.firstAfter = firstAfter
        self.secondAfter = secondAfter
    }

    init(cursorContext: CursorContext) {
        self.init(
            secondBefore: cursorContext.secondBefore?.1,
            firstBefore: cursorContext.firstBefore?.1,
            word: cursorContext.current.1,
            firstAfter: cursorContext.firstAfter?.1,
            secondAfter: cursorContext.secondAfter?.1
        )
    }

    public func isContinuation(of context: WordContext) -> Bool {
        guard context.secondBefore == self.secondBefore,
            context.firstBefore == self.firstBefore,
            context.firstAfter == self.firstAfter,
            context.secondAfter == self.secondAfter else {
                return false
        }

        let didAddSingleCharacter = self.word.dropLast() == context.word
        let didDeleteSingleCharacter = context.word.dropLast() == self.word
        return didAddSingleCharacter || didDeleteSingleCharacter
    }

    public func contextAttributedString() -> NSAttributedString {
        var contextString = word
        var boldOffset = 0
        if let firstBefore = firstBefore {
            let prefix = firstBefore + " "
            contextString = prefix + contextString
            boldOffset += prefix.count
        }
        if let secondBefore = secondBefore {
            let prefix = secondBefore + " "
            contextString = prefix + contextString
            boldOffset += prefix.count
        }
        if let firstAfter = firstAfter {
            contextString += " " + firstAfter
        }
        if let secondAfter = secondAfter {
            contextString += " " + secondAfter
        }

        let attr = NSMutableAttributedString(string: contextString)
        let boldRange = NSRange(location: boldOffset, length: word.count)
        attr.addAttribute(NSAttributedString.Key.font,
                          value: UIFont.boldSystemFont(ofSize: UIFont.labelFontSize),
                          range: boldRange)
        return attr
    }
}
