import Foundation
import DivvunSpell

extension CursorContext {
    static func from(proxy: UITextDocumentProxy) throws -> CursorContext {
        return try CursorContext.from(leftPart: proxy.documentContextBeforeInput ?? "",
                                  rightPart: proxy.documentContextAfterInput ?? "")
    }
}
