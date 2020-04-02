import Foundation
import DivvunSpell

public struct WordContext: Equatable {
    var secondBefore: String? { words[0] }
    var firstBefore: String? { words[1] }
    var word: String { words[2]! }
    var firstAfter: String? { words[3] }
    var secondAfter: String? { words[4] }

    private var words: [String?]

    private var nonNilWords: [String] {
        words.compactMap { $0 }
    }

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

    init(secondBefore: String? = nil,
         firstBefore: String? = nil,
         word: String,
         firstAfter: String? = nil,
         secondAfter: String? = nil) {
        words = [
            secondBefore,
            firstBefore,
            word,
            firstAfter,
            secondAfter
        ]
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

    public func isContinuation(of other: WordContext) -> Bool {
        guard other.secondBefore == self.secondBefore,
            other.firstBefore == self.firstBefore,
            other.firstAfter == self.firstAfter,
            other.secondAfter == self.secondAfter else {
                return false
        }

        let didAddSingleCharacter = self.word.dropLast() == other.word
        let didDeleteSingleCharacter = other.word.dropLast() == self.word
        return didAddSingleCharacter || didDeleteSingleCharacter
    }

    // This method is not currently used.
    // Leaving because it will be useful if we find that variation determination needs to be more dynamic.
    func isVariationOf(_ other: WordContext) -> Bool {
        let words = self.nonNilWords
        let otherWords = other.nonNilWords
        let numWordsDifference = abs(words.count - otherWords.count)
        guard numWordsDifference <= 1 else {
            return false
        }

        let loopLength = min(words.count, otherWords.count)
        var offset = 0
        var otherOffset = 0
        if otherWords.count > 1, words[0] == otherWords[1] {
            otherOffset = 1
        } else if words.count > 1, words[1] == otherWords[0] {
            offset = 1
        }

        for i in 0 ..< loopLength {
            // swiftlint:disable:next for_where
            if words[i + offset] != otherWords[i + otherOffset] {
                return false
            }
        }

        return true
    }

    func isLeftShiftedVariationOf(_ other: WordContext) -> Bool {
        return self.secondBefore == other.firstBefore && self.firstBefore == other.word
    }

    func isTwiceLeftShiftedVariationOf(_ other: WordContext) -> Bool {
        return self.secondBefore == other.word && self.firstBefore == other.firstAfter
    }

    public func isMoreDesirableThan(_ other: WordContext) -> Bool {
        return self.desirabilityScore > other.desirabilityScore
    }

    public func adding(context: WordContext) -> WordContext? {
        if context.isLeftShiftedVariationOf(self) {
            return WordContext(secondBefore: self.secondBefore,
                               firstBefore: self.firstBefore,
                               word: self.word,
                               firstAfter: nonEmptyStringOrNil(context.word),
                               secondAfter: nonEmptyStringOrNil(context.firstAfter))
        } else if context.isTwiceLeftShiftedVariationOf(self) {
            return WordContext(secondBefore: self.secondBefore,
                               firstBefore: self.firstBefore,
                               word: self.word,
                               firstAfter: nonEmptyStringOrNil(context.firstBefore),
                               secondAfter: nonEmptyStringOrNil(context.word))
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
