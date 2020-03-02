import DivvunSpell

class UserDictionaryDaemon {
    private let speller: Speller
    private var previousContext: WordContext?
    private var currentContext: WordContext?
    private let userDictionary = UserDictionary()
    private let locale: KeyboardLocale

    init(speller: Speller, locale: KeyboardLocale) {
        self.speller = speller
        self.locale = locale
    }

    public func updateContext(_ context: WordContext) {
        guard currentContext != context else {
            return
        }

        previousContext = currentContext
        currentContext = context

        guard let previous = previousContext else {
            return
        }

        if context.isContinuation(of: previous) == false,
            speller.contains(word: previous.word) == false {
            userDictionary.add(context: previous, locale: locale)
            print("adding word: \(previous.word)")
        }
    }
}

extension Speller {
    public func contains(word: String) -> Bool {
        guard let contains = try? isCorrect(word: word) else {
            return false
        }
        return contains
    }
}
