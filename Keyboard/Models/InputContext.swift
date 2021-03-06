// This class is much like CursorContext, but includes punctuation information
// and can be used for updating captalization

import Foundation

public struct InputContext {
    public let previousWord: String?
    public let currentWord: String
    public let currentOffset: Int
    public let nextWord: String?
    public let selectedText: String?
}

extension InputContext {
    static func from(proxy: UITextDocumentProxy) -> InputContext {
    return resolveWordContext(before: proxy.documentContextBeforeInput ?? "",
                              after: proxy.documentContextAfterInput ?? "",
                              selectedText: proxy.selectedText)
    }
}

// Grabs the word before, current word, and next word from the proxy
private func resolveWordContext(before beforeInput: String,
                                after afterInput: String,
                                selectedText: String? = nil) -> InputContext {
    let currentWord: String
    var previousWord: String?
    var nextWord: String?

    var leftCurrentChunk: String.SubSequence?
    var rightCurrentChunk: String.SubSequence?

    // Build current word
    let currentLeftIndex = beforeInput.lastIndex(where: { $0 == " " || $0 == "\n" })
    if let currentLeftIndex = currentLeftIndex {
        leftCurrentChunk = beforeInput.suffix(after: currentLeftIndex)
    } else {
        leftCurrentChunk = beforeInput.suffix(from: beforeInput.startIndex)
    }

    let currentRightIndex = afterInput.firstIndex(where: { $0 == " " || $0 == "\n" }) ?? afterInput.endIndex
    rightCurrentChunk = afterInput.prefix(upTo: currentRightIndex)

    // Try left side
    if let currentLeftIndex = currentLeftIndex, beforeInput[currentLeftIndex] != "\n" {
        let leftFullChunk = beforeInput.prefix(upTo: currentLeftIndex)
        let leftIndex = leftFullChunk.lastIndex(where: { $0 == " " || $0 == "\n" }) ?? leftFullChunk.startIndex
        let leftChunk = beforeInput[leftIndex..<currentLeftIndex]

        let candidate = leftChunk.trimmingCharacters(in: .whitespacesAndNewlines)
        if !candidate.isEmpty {
            previousWord = candidate
        }
    }

    // Try right side
    if currentRightIndex != afterInput.endIndex && afterInput[currentRightIndex] != "\n" {
        let rightFullChunk = afterInput.suffix(after: currentRightIndex)
        let rightIndex = rightFullChunk.firstIndex(where: { $0 == " " || $0 == "\n" }) ?? rightFullChunk.endIndex
        let rightChunk = rightFullChunk.prefix(upTo: rightIndex)

        let candidate = rightChunk.trimmingCharacters(in: .whitespacesAndNewlines)
        if !candidate.isEmpty {
            nextWord = candidate
        }
    }

    var offset: Int = 0
    if let left = leftCurrentChunk, let right = rightCurrentChunk {
        currentWord = "\(left)\(right)"
        offset = left.count
    } else if let left = leftCurrentChunk {
        currentWord = String(left)
        offset = currentWord.count
    } else if let right = rightCurrentChunk {
        currentWord = String(right)
    } else {
        currentWord = ""
    }

    return InputContext(previousWord: previousWord,
                         currentWord: currentWord,
                         currentOffset: offset,
                         nextWord: nextWord,
                         selectedText: selectedText)
}

extension String {
    func suffix(after index: String.Index) -> String.SubSequence {
        if index >= endIndex {
            return suffix(from: endIndex)
        }

        return suffix(from: self.index(after: index))
    }
}
