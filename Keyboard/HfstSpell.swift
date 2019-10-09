//import Foundation
//
//private extension URL {
//    func asStringPointer() -> UnsafePointer<Int8>? {
//        return (absoluteURL.path as NSString?)?.fileSystemRepresentation
//    }
//}
//
//struct SpellerInitError: Error {
//    let code: UInt8
//    let message: String
//}
//
//public enum TokenType: UInt8 {
//    case other = 0
//    case word = 1
//    case punctuation = 2
//    case whitespace = 3
//}
//
//public struct Token {
//    let type: TokenType
//    let start: UInt32
//    let end: UInt32
//    let value: String
//}
//
//// extension Token {
////    fileprivate static func from(c record: token_record_t) -> Token {
////        return Token(
////            type: TokenType(rawValue: record.type) ?? .other,
////            start: record.start,
////            end: record.end,
////            value: String(cString: record.value))
////    }
//// }
////
//// public class TokenizerSequence: Sequence {
////    public class Iterator: IteratorProtocol {
////        private let handle: UnsafeMutableRawPointer
////        private let record: UnsafeMutablePointer<UnsafeMutablePointer<token_record_t>?>
////        private let value: [CChar]
////
////        init(_ value: String) {
////            self.value = value.cString(using: .utf8)!
////            self.handle = speller_tokenize(self.value)!
////            self.record = UnsafeMutablePointer<UnsafeMutablePointer<token_record_t>?>.allocate(capacity: 1)
////
////            self.record.pointee = nil
////        }
////
////        public func next() -> Token? {
////            if !speller_token_next(handle, record) {
////                return nil
////            }
////
////            guard let record = record.pointee else {
////                return nil
////            }
////
////            return Token.from(c: record.pointee)
////        }
////
////        deinit {
////            speller_tokenizer_free(handle)
////        }
////    }
////
////    private let value: String
////
////    fileprivate init(string: String) {
////        self.value = string
////    }
////
////    public func makeIterator() -> TokenizerSequence.Iterator {
////        return TokenizerSequence.Iterator(value)
////    }
//// }
////
//// public extension String {
////    func tokenize() -> TokenizerSequence {
////        return TokenizerSequence(string: self)
////    }
//// }
//
//public class SuggestionSequence: Sequence {
//    public class Iterator: IteratorProtocol {
//        private var i = 0
//        private let size: Int
//        private let spellerHandle: UnsafeMutableRawPointer
//        private let handle: UnsafeMutableRawPointer
//
//        init(_ value: String, count: Int, maxWeight: Float, speller: UnsafeMutableRawPointer) {
//            spellerHandle = speller
//            handle = speller_suggest(speller, value.cString(using: .utf8)!, count, maxWeight, 0.0)
//            size = suggest_vec_len(handle)
//        }
//
//        public func next() -> String? {
//            if i >= size {
//                return nil
//            }
//
//            let rawString = suggest_vec_get_value(handle, i)
//            defer { suggest_vec_value_free(rawString) }
//
//            let value = String(cString: rawString)
//            i += 1
//            return value
//        }
//
//        deinit {
//            suggest_vec_free(handle)
//        }
//    }
//
//    private let spellerHandle: UnsafeMutableRawPointer
//    private let value: String
//    private let suggestionCount: Int
//    private let maxWeight: Float
//
//    fileprivate init(handle: UnsafeMutableRawPointer, word: String, count: Int = 10, maxWeight: Float = 4999.99) {
//        spellerHandle = handle
//        value = word
//        suggestionCount = count
//        self.maxWeight = maxWeight
//    }
//
//    public func makeIterator() -> SuggestionSequence.Iterator {
//        return SuggestionSequence.Iterator(value, count: suggestionCount, maxWeight: maxWeight, speller: spellerHandle)
//    }
//}
//
//public class ChfstSuggestionSequence: Sequence {
//    public class Iterator: IteratorProtocol {
//        private var i = 0
//        private let size: Int
//        private let spellerHandle: UnsafeMutableRawPointer
//        private let handle: UnsafeMutableRawPointer
//
//        init(_ value: String, count: Int, maxWeight: Float, speller: UnsafeMutableRawPointer) {
//            spellerHandle = speller
//            handle = chfst_suggest(speller, value.cString(using: .utf8)!, count, maxWeight, 0.0)
//            size = suggest_vec_len(handle)
//        }
//
//        public func next() -> String? {
//            if i >= size {
//                return nil
//            }
//
//            let rawString = suggest_vec_get_value(handle, i)
//            defer { suggest_vec_value_free(rawString) }
//
//            let value = String(cString: rawString)
//            i += 1
//            return value
//        }
//
//        deinit {
//            suggest_vec_free(handle)
//        }
//    }
//
//    private let spellerHandle: UnsafeMutableRawPointer
//    private let value: String
//    private let suggestionCount: Int
//    private let maxWeight: Float
//
//    fileprivate init(handle: UnsafeMutableRawPointer, word: String, count: Int = 10, maxWeight: Float = 4999.99) {
//        spellerHandle = handle
//        value = word
//        suggestionCount = count
//        self.maxWeight = maxWeight
//    }
//
//    public func makeIterator() -> ChfstSuggestionSequence.Iterator {
//        return ChfstSuggestionSequence.Iterator(value, count: suggestionCount, maxWeight: maxWeight, speller: spellerHandle)
//    }
//}
//
//public struct Suggestion: Decodable {
//    let value: String
//    let weight: Float
//}
//
//public class ZhfstSpeller {
//    private let handle: UnsafeMutableRawPointer
//
//    lazy var locale: String = {
//        let ptr = speller_meta_get_locale(handle)
//        defer { speller_str_free(ptr) }
//        return String(cString: ptr)
//    }()
//
//    init(path: URL) throws {
//        var errorPtr: UnsafeMutablePointer<CChar>?
//
//        guard let handle = speller_archive_new(path.asStringPointer()!, &errorPtr) else {
//            if let errorPtr = errorPtr {
//                defer { speller_str_free(errorPtr) }
//                throw SpellerInitError(code: 0, message: String(cString: errorPtr))
//            }
//            throw SpellerInitError(code: 255, message: "Unknown error")
//        }
//        self.handle = handle
//    }
//
//    func suggest(word: String, count: Int = 10, maxWeight: Float = 0.0) -> SuggestionSequence {
//        return SuggestionSequence(handle: handle, word: word, count: count, maxWeight: maxWeight)
//    }
//
//    func isCorrect(word: String) -> Bool {
//        return speller_is_correct(handle, word.cString(using: .utf8)!)
//    }
//
//    deinit {
//        speller_archive_free(handle)
//    }
//}
//
//public class ChfstSpeller {
//    private let handle: UnsafeMutableRawPointer
//
//    lazy var locale: String = {
//        let ptr = chfst_meta_get_locale(handle)
//        defer { speller_str_free(ptr) }
//        return String(cString: ptr)
//    }()
//
//    init(path: URL) throws {
//        var errorPtr: UnsafeMutablePointer<CChar>?
//
//        guard let handle = chfst_new(path.asStringPointer()!, &errorPtr) else {
//            if let errorPtr = errorPtr {
//                defer { speller_str_free(errorPtr) }
//                throw SpellerInitError(code: 0, message: String(cString: errorPtr))
//            }
//            throw SpellerInitError(code: 255, message: "Unknown error")
//        }
//        self.handle = handle
//    }
//
//    func suggest(word: String, count: Int = 10, maxWeight: Float = 0.0) -> ChfstSuggestionSequence {
//        return ChfstSuggestionSequence(handle: handle, word: word, count: count, maxWeight: maxWeight)
//    }
//
//    func isCorrect(word: String) -> Bool {
//        return chfst_is_correct(handle, word.cString(using: .utf8)!)
//    }
//
//    deinit {
//        chfst_free(handle)
//    }
//}
//
//public class ThfstSpeller {
//    private init(handle: UnsafeRawPointer) {
//        self.handle = handle
//    }
//    
//    func isCorrect(word: String) -> Bool {
//        
//    }
//    
//    func suggest(word: String) {
//        
//    }
//    
//    
//    
//    deinit {
//        // TODO: cleanup
//    }
//}
//
//public class BhfstSpellerArchive {
//    public static func open(path: String) throws -> BhfstSpellerArchive {
//        
//    }
//    
//    private init(handle: UnsafeRawPointer) {
//        self.handle = handle
//    }
//    
//    private func speller() -> ThfstSpeller {
//        
//    }
//    
//    deinit {
//        // TODO: cleanup
//    }
//}
