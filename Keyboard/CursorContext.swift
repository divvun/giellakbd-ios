//
//  CursorContext.swift
//  BaseKeyboard
//
//  Created by Brendan Molloy on 2019-08-08.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation

public struct CursorContext {
    public let previousWord: String?
    public let currentWord: String
    public let currentOffset: Int
    public let nextWord: String?
    public let selectedText: String?
}

extension CursorContext {
    static func from(proxy: UITextDocumentProxy) -> CursorContext {
        var selectedText: String? = nil
        if #available(iOSApplicationExtension 11.0, *) {
            selectedText = proxy.selectedText
        }
        
        return resolveWordContext(before: proxy.documentContextBeforeInput ?? "",
                                  after: proxy.documentContextAfterInput ?? "",
                                  selectedText: selectedText)
    }
}

// Grabs the word before, current word, and next word from the proxy
fileprivate func resolveWordContext(before beforeInput: String, after afterInput: String, selectedText: String? = nil) -> CursorContext {
    let currentWord: String
    var previousWord: String? = nil
    var nextWord: String? = nil
    
    var leftCurrentChunk: String.SubSequence? = nil
    var rightCurrentChunk: String.SubSequence? = nil
    
    // Build current word
    let currentLeftIndex = beforeInput.lastIndex(of: " ")
    if let currentLeftIndex = currentLeftIndex {
        leftCurrentChunk = beforeInput.suffix(after: currentLeftIndex)
    } else {
        leftCurrentChunk = beforeInput.suffix(from: beforeInput.startIndex)
    }
    
    let currentRightIndex = afterInput.firstIndex(of: " ") ?? afterInput.endIndex
    rightCurrentChunk = afterInput.prefix(upTo: currentRightIndex)
    
    // Try left side
    if let currentLeftIndex = currentLeftIndex {
        let leftFullChunk = beforeInput.prefix(upTo: currentLeftIndex)
        let leftIndex = leftFullChunk.lastIndex(after: " ") ?? leftFullChunk.startIndex
        let leftChunk = beforeInput[leftIndex..<currentLeftIndex]
        
        if !leftChunk.isEmpty {
            previousWord = String(leftChunk)
        }
    }
    
    // Try right side
    if currentRightIndex != afterInput.endIndex {
        let rightFullChunk = afterInput.suffix(after: currentRightIndex)
        let rightIndex = rightFullChunk.firstIndex(of: " ") ?? rightFullChunk.endIndex
        let rightChunk = rightFullChunk.prefix(upTo: rightIndex)
        
        if !rightChunk.isEmpty {
            nextWord = String(rightChunk)
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
    
    return CursorContext(previousWord: previousWord,
                         currentWord: currentWord,
                         currentOffset: offset,
                         nextWord: nextWord,
                         selectedText: selectedText)
}
