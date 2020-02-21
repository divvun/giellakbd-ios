import Foundation

public struct WordContext: Equatable {
    let secondBefore: String?
    let firstBefore: String?
    let firstAfter: String?
    let secondAfter: String?

    init(secondBefore: String? = nil,
         firstBefore: String? = nil,
         firstAfter: String? = nil,
         secondAfter: String? = nil) {
        self.secondBefore = secondBefore
        self.firstBefore = firstBefore
        self.firstAfter = firstAfter
        self.secondAfter = secondAfter
    }
    public func contextAttributedString() -> NSAttributedString {
        // IMPLEMENT ME
        return NSAttributedString()
    }
}
