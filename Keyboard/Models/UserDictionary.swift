import Foundation
import SQLite

public final class UserDictionary {
    public let locale: KeyboardLocale

    private enum WordState: String {
        case candidate
        case userWord = "user_word"
        case manuallyAdded = "manually_added"
        case blacklisted
    }

    internal struct WordTable {
        static let table = Table("user_word")
        static let id = Expression<Int64>("id")
        static let word = Expression<String>("word")
        static let locale = Expression<String>("locale")
        static let state = Expression<String>("state")
    }

    internal struct ContextTable {
        static let table = Table("word_context")
        static let id = Expression<Int64>("id")
        static let wordId = Expression<Int64>("word_id")
        static let secondBefore = Expression<String?>("second_before")
        static let firstBefore = Expression<String?>("first_before")
        static let firstAfter = Expression<String?>("first_after")
        static let secondAfter = Expression<String?>("second_after")
    }

    private lazy var dbFilePath: String = {
        let dbFileName = "userDictionary.sqlite3"
        return KeyboardSettings.groupContainerURL.appendingPathComponent(dbFileName).path
    }()

    internal lazy var database: Connection = {
        guard let database = try? Connection(dbFilePath) else {
            fatalError("Unable to create or open user dictionary database")
        }
        try? database.execute("PRAGMA foreign_keys = ON;")
        createTablesIfNeeded(database: database)
        return database
    }()

    init(locale: KeyboardLocale) {
        self.locale = locale
    }

    private func createTablesIfNeeded(database: Connection) {
        do {
            try createUserWordTable(database: database)
            try createWordContextTable(database: database)
        } catch {
            fatalError("Error creating database table: \(error)")
        }
    }

    private func createUserWordTable(database: Connection) throws {
        try database.run(WordTable.table.create(ifNotExists: true) { table in
            table.column(WordTable.id, primaryKey: true)
            table.column(WordTable.word, collate: .nocase)
            table.column(WordTable.locale)
            table.column(WordTable.state)
        })
    }

    private func createWordContextTable(database: Connection) throws {
        try database.run(ContextTable.table.create(ifNotExists: true) { table in
            table.column(ContextTable.id, primaryKey: true)
            table.column(ContextTable.wordId)
            table.column(ContextTable.secondBefore)
            table.column(ContextTable.firstBefore)
            table.column(ContextTable.firstAfter)
            table.column(ContextTable.secondAfter)
            table.foreignKey(ContextTable.wordId, references: WordTable.table, WordTable.id, delete: .cascade)
        })
    }

    // MARK: - Querying Dictionary

    public func getSuggestions(for input: String) -> [String] {
        return getUserWords()
            .map { (word: $0, score: $0.levenshtein(input) ) }
            .filter { $0.score < 4 }
            .sorted { $0.score < $1.score }
            .map { $0.word }
    }

    public func getUserWords() -> [String] {
        var words: [String] = []
        let query = WordTable.table.select(WordTable.word)
            .filter(WordTable.locale == locale.identifier)
            .filter(WordTable.state == WordState.userWord.rawValue || WordTable.state == WordState.manuallyAdded.rawValue)
            .order(WordTable.word)
        do {
            let rows = try database.prepare(query)
            for row in rows {
                let word = row[WordTable.word]
                words.append(word)
            }
        } catch {
            print("Error getting user words: \(error)")
        }
        return words
    }

    public func containsWord(_ word: String) -> Bool {
        return fetchWord(word) != nil
    }

    public func getContexts(for word: String) -> [WordContext] {
        guard let wordRow = fetchWord(word) else {
            return []
        }

        let wordId = wordRow[WordTable.id]
        let query = ContextTable.table.filter(ContextTable.wordId == wordId)
        do {
            let rows = try database.prepare(query)
            return rows.map({
                WordContext(secondBefore: $0[ContextTable.secondBefore],
                            firstBefore: $0[ContextTable.firstBefore],
                            word: word,
                            firstAfter: $0[ContextTable.firstAfter],
                            secondAfter: $0[ContextTable.secondAfter])
            })
        } catch {
            fatalError("Error getting user dictionary word contexts: \(error)")
        }
    }

    // MARK: - Adding/removing/updating Dictionary

    @discardableResult
    public func addCandidate(context: WordContext) -> Int64 {
        validateContext(context)

        let word = context.word
        let wordId: Int64

        if let existingWord = fetchWord(word) {
            wordId = existingWord[WordTable.id]
            if wordIsCandidate(existingWord) {
                updateWordState(id: wordId, state: .userWord)
            }
        } else {
            wordId = insertWordCandidate(word: word)
        }

        return insertContext(context, for: wordId)
    }

    public func addWordManually(_ word: String) {
        if let existingWord = fetchWord(word) {
            updateWordState(id: existingWord[WordTable.id], state: .manuallyAdded)
        } else {
            let wordId = insertWord(word: word, state: .manuallyAdded)
            insertContext(WordContext(word: word), for: wordId)
        }
    }

    public func removeWord(_ word: String) {
        do {
            let query = WordTable.table
                .filter(WordTable.word == word)
                .filter(WordTable.locale == locale.identifier)
            try database.run(query.delete())
        } catch {
            fatalError("Error deleting word from UserDictionary \(error)")
        }
    }

    @discardableResult
    public func updateContext(contextId: Int64, newContext: WordContext) -> Bool {
        guard let wordRow = fetchWord(newContext.word),
            let contextRow = fetchContext(contextId: contextId),
            contextRow[ContextTable.wordId] == wordRow[WordTable.id] else {
                return false
        }

        do {
            let oldContext = ContextTable.table.filter(ContextTable.id == contextId)
            let update = oldContext.update(
                ContextTable.secondBefore <- newContext.secondBefore,
                ContextTable.firstBefore <- newContext.firstBefore,
                ContextTable.firstAfter <- newContext.firstAfter,
                ContextTable.secondAfter <- newContext.secondAfter
            )
            return try database.run(update) > 0
        } catch {
            fatalError("Error updating context: \(error)")
        }
    }

    // MARK: - Private methods

    private func validateContext(_ context: WordContext) {
        if context.secondBefore != nil && context.firstBefore == nil {
            fatalError("Attempted to add word to UserDictionary with secondBefore word but no firstBefore word.")
        }
        if context.secondAfter != nil && context.firstAfter == nil {
            fatalError("Attempted to add word to UserDictionary with secondAfter word but no firstAfter word.")
        }
    }

    private func wordIsCandidate(_ row: SQLite.Row) -> Bool {
        let wordState = WordState(rawValue: row[WordTable.state])
        return wordState == .candidate
    }

    private func fetchWord(_ word: String) -> SQLite.Row? {
        var row: SQLite.Row?
        do {
            let query = WordTable.table
                .filter(WordTable.word == word)
                .filter(WordTable.locale == locale.identifier)
            row = try database.pluck(query)
        } catch {
            fatalError("Error finding existsing word: \(error)")
        }
        return row
    }

    private func fetchContext(contextId: Int64) -> SQLite.Row? {
        let query = ContextTable.table.filter(ContextTable.id == contextId)
        return try? database.pluck(query)
    }

    private func updateWordState(id: Int64, state: WordState) {
        do {
            let word = WordTable.table.filter(WordTable.id == id)
            try database.run(word.update(WordTable.state <- state.rawValue))
        } catch {
            fatalError("Error updating word state \(error)")
        }
    }

    @discardableResult
    private func insertWordCandidate(word: String) -> Int64 {
        return insertWord(word: word, state: .candidate)
    }

    @discardableResult
    private func insertWord(word: String, state: WordState) -> Int64 {
        let insert = WordTable.table.insert(
            WordTable.word <- word.lowercased(),
            WordTable.locale <- locale.identifier,
            WordTable.state <- state.rawValue
        )

        do {
            return try database.run(insert)
        } catch {
            fatalError("Error inserting into database: \(error)")
        }
    }

    @discardableResult
    private func insertContext(_ context: WordContext, for wordId: Int64) -> Int64 {
        let insert = ContextTable.table.insert(
            ContextTable.wordId <- wordId,
            ContextTable.secondBefore <- context.secondBefore,
            ContextTable.firstBefore <- context.firstBefore,
            ContextTable.firstAfter <- context.firstAfter,
            ContextTable.secondAfter <- context.secondAfter
        )
        do {
            return try database.run(insert)
        } catch {
            fatalError("Error inserting context into database: \(error)")
        }
    }
}
