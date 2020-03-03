import DivvunSpell

class UserDictionaryDaemon {
    private let speller: Speller
    private var previousContext: WordContext?
    private var currentContext: WordContext?
    private var lastSavedContext: WordContext?
    private var lastSavedContextId: Int64?
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

        saveOrUpdateContextIfNeeded()
    }

    private func saveOrUpdateContextIfNeeded() {
        guard let saveCandidateContext = previousContext,
            let context = currentContext else {
            return
        }

        guard context.isContinuation(of: saveCandidateContext) == false else {
            return
        }

        let didUpdateLastContext = updateLastContextIfNeeded(with: saveCandidateContext)
        guard didUpdateLastContext == false else {
            return
        }

        if speller.contains(word: saveCandidateContext.word) == false {
            lastSavedContextId = userDictionary.add(context: saveCandidateContext, locale: locale)
            lastSavedContext = saveCandidateContext
        }
    }

    private func updateLastContextIfNeeded(with saveCandidate: WordContext) -> Bool {
        guard let lastSavedContext = lastSavedContext,
            saveCandidate.isLeftShiftedVariationOf(lastSavedContext),
            let combinedContext = lastSavedContext.adding(context: saveCandidate),
            combinedContext.isMoreDesirableThan(lastSavedContext),
            let lastSavedContextId = lastSavedContextId else {
                return false
        }

        userDictionary.updateContext(contextId: lastSavedContextId, newContext: combinedContext, locale: locale)
        self.lastSavedContext = combinedContext

        return true
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
