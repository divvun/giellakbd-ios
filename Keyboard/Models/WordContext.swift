import Foundation
import DivvunSpell

public struct WordContext: Equatable {
    let secondBefore: String?
    let firstBefore: String?
    let word: String
    let firstAfter: String?
    let secondAfter: String?

    private var desirabilityScore: UInt {
        if firstBefore != nil && firstAfter != nil {
            return 3
        } else if firstBefore != nil && secondBefore != nil
            || firstAfter != nil && secondAfter != nil {
            return 2
        } else if firstBefore != nil || firstAfter != nil {
            return 1
        } else {
            return 0
        }
    }

    private var wordsArray: [String] {
        var words: [String] = []
        if let secondBefore = secondBefore {
            words.append(secondBefore)
        }
        if let firstBefore = firstBefore {
            words.append(firstBefore)
        }

        words.append(word)

        if let firstAfter = firstAfter {
            words.append(firstAfter)
        }
        if let secondAfter = secondAfter {
            words.append(secondAfter)
        }

        return words
    }

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

    func isVariationOf(_ context: WordContext) -> Bool {
        let words = wordsArray
        let otherWords = context.wordsArray
        let numWordsDifference = abs(words.count - otherWords.count)
        guard numWordsDifference <= 1 else {
            return false
        }

        let loopLength = min(words.count, otherWords.count)
        var offset = 0
        var otherOffset = 0
        if words[0] == otherWords[1] {
            offset = 1
        } else if words[1] == otherWords[0] {
            otherOffset = 1
        }

        for i in 0..<loopLength {
            // swiftlint:disable:next for_where
            if words[i + offset] != otherWords[i + otherOffset] {
                return false
            }
        }

        return true
    }

    func isLeftShiftedVariationOf(_ context: WordContext) -> Bool {
        return self.secondBefore == context.firstBefore && self.firstBefore == context.word
    }

    public func isMoreDesirableThan(_ context: WordContext) -> Bool {
        return self.desirabilityScore > context.desirabilityScore
    }

    public func adding(context: WordContext) -> WordContext? {
        // Currently only support left-shifted contexts
        if context.isLeftShiftedVariationOf(self) {
            return WordContext(secondBefore: self.secondBefore,
                               firstBefore: self.firstBefore,
                               word: self.word,
                               firstAfter: nonEmptyStringOrNil(context.word),
                               secondAfter: nonEmptyStringOrNil(context.firstAfter))
        }

        return nil
    }

    private func nonEmptyStringOrNil(_ string: String?) -> String? {
        guard let string = string else {
            return nil
        }
        return string.isEmpty ? nil : string
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
