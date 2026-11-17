import DivvunSpell

final class UserDictionaryService {
    public let dictionary: UserDictionary
    private let speller: Speller
    private var previousContext: WordContext?
    private var currentContext: WordContext?
    private var lastSavedContext: WordContext?
    private var lastSavedContextId: Int64?

    init(speller: Speller, locale: KeyboardLocale) {
        self.dictionary = UserDictionary(locale: locale)
        self.speller = speller
        // Open the database now, while nothing else can see this service. It opens lazily, and context updates
        // and suggestion lookups run on different background queues, so they could otherwise race to open it.
        _ = dictionary.database
    }

    public func updateContext(_ context: WordContext) {
        guard currentContext != context else {
            return
        }

        previousContext = currentContext
        currentContext = context

        saveOrUpdateContextIfNeeded()
    }

    /// The word being typed is about to be replaced, as when a suggestion is picked, so don't learn it. Otherwise
    /// it changing into the replacement in one step would look like a finished word.
    func discardCurrentWord() {
        currentContext = nil
    }

    private func saveOrUpdateContextIfNeeded() {
        guard let saveCandidateContext = previousContext,
            let context = currentContext else {
            return
        }

        guard context.isContinuation(of: saveCandidateContext) == false else {
            return
        }

        updateLastContextIfNeeded(with: saveCandidateContext)

        if speller.contains(word: saveCandidateContext.word) == false {
            lastSavedContextId = dictionary.addCandidate(context: saveCandidateContext)
            lastSavedContext = saveCandidateContext
        }
    }

    private func updateLastContextIfNeeded(with saveCandidate: WordContext) {
        guard let lastSavedContext = lastSavedContext,
            let lastSavedContextId = lastSavedContextId else {
                return
        }

        guard let combinedContext = lastSavedContext.adding(context: saveCandidate),
            combinedContext.isMoreDesirableThan(lastSavedContext) else {
                return
        }

        dictionary.updateContext(contextId: lastSavedContextId, newContext: combinedContext)
        self.lastSavedContext = combinedContext

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
