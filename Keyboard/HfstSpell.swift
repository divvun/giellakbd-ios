//
//  HfstSpell.swift
//  Keyboard
//
//  Created by Brendan Molloy on 2018-11-01.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

fileprivate extension URL {
    func asStringPointer() -> UnsafePointer<Int8>? {
        return (self.absoluteURL.path as NSString?)?.fileSystemRepresentation
    }
}

struct SpellerInitError: Error {
    let code: UInt8
    let message: String
}

public enum TokenType: UInt8 {
    case other = 0
    case word = 1
    case punctuation = 2
    case whitespace = 3
}

public struct Token {
    let type: TokenType
    let start: UInt64
    let end: UInt64
    let value: String
}

extension Token {
    fileprivate static func from(c record: token_record_t) -> Token {
        return Token(
            type: TokenType(rawValue: record.type) ?? .other,
            start: record.start,
            end: record.end,
            value: String(cString: record.value))
    }
}

public class TokenizerSequence: Sequence {
    public struct Iterator: IteratorProtocol {
        private let handle: UnsafeMutableRawPointer
        private let record: UnsafeMutablePointer<UnsafeMutablePointer<token_record_t>?>
        
        init(_ handle: UnsafeMutableRawPointer) {
            self.handle = handle
            self.record = UnsafeMutablePointer<UnsafeMutablePointer<token_record_t>?>.allocate(capacity: 1)
        }
        
        mutating public func next() -> Token? {
            if !speller_token_next(handle, record) {
                return nil
            }
            
            guard let record = record.pointee else {
                return nil
            }
            
            return Token.from(c: record.pointee)
        }
    }
    
    private let handle: UnsafeMutableRawPointer
    
    fileprivate init(handle: UnsafeMutableRawPointer) {
        self.handle = handle
    }
    
    public func makeIterator() -> TokenizerSequence.Iterator {
        return TokenizerSequence.Iterator(handle)
    }
    
    deinit {
        speller_tokenizer_free(handle)
    }
}

public extension String {
    func tokenize() -> TokenizerSequence {
        let handle = speller_tokenize(self.cString(using: .utf8))!
        return TokenizerSequence(handle: handle)
    }
}

class SuggestionSequence: Sequence {
    struct Iterator: IteratorProtocol {
        private var i = 0
        private let size: Int
        private let handle: UnsafeMutableRawPointer
        
        init(_ handle: UnsafeMutableRawPointer) {
            self.handle = handle
            self.size = suggest_vec_len(handle)
        }
        
        mutating func next() -> String? {
            if i >= size {
                return nil
            }
            
            let rawString = suggest_vec_get_value(handle, i)!
            defer { suggest_vec_value_free(rawString) }
            
            let value = String(cString: rawString)
            i += 1
            return value
        }
    }
    
    private let handle: UnsafeMutableRawPointer
    
    fileprivate init(handle: UnsafeMutableRawPointer) {
        self.handle = handle
    }
    
    func makeIterator() -> SuggestionSequence.Iterator {
        return SuggestionSequence.Iterator(handle)
    }
    
    deinit {
        suggest_vec_free(handle)
    }
}

class Speller {
    private let handle: UnsafeMutableRawPointer
    
    lazy var locale: String = {
        let ptr = speller_meta_get_locale(handle)!
        defer { speller_str_free(ptr) }
        return String(cString: ptr)
    }()
    
    init(path: URL) throws {
        var errorPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
        guard let handle = speller_archive_new(path.asStringPointer(), errorPtr) else {
            let errMsgPtr = speller_get_error(errorPtr.pointee)!
            defer { speller_str_free(errMsgPtr) }
            
            throw SpellerInitError(code: errorPtr.pointee, message: String(cString: errMsgPtr))
        }
        
        self.handle = handle
    }
    
    func suggest(word: String, count: Int = 3) -> SuggestionSequence {
        let rawSuggestions = speller_suggest(handle, word.cString(using: .utf8), count, 0.0)!
        return SuggestionSequence(handle: rawSuggestions)
    }
    
    func isCorrect(word: String) -> Bool {
        return speller_is_correct(handle, word.cString(using: .utf8))
    }
    
    deinit {
        speller_archive_free(handle)
    }
}
