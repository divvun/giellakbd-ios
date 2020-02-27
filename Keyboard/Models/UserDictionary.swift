import Foundation
import SQLite

public class UserDictionary {
    private enum WordState: String {
        case candidate
        case userWord = "user_word"
        case manuallyAdded = "manually_added"
        case blacklisted
    }

    private struct WordTable {
        static let table = Table("user_word")
        static let id = Expression<Int64>("id")
        static let word = Expression<String>("word")
        static let locale = Expression<String>("locale")
        static let state = Expression<String>("state")
    }

    private struct ContextTable {
        static let table = Table("word_context")
        static let id = Expression<Int64>("id")
        static let wordId = Expression<Int64>("word_id")
        static let secondBefore = Expression<String?>("second_before")
        static let firstBefore = Expression<String?>("first_before")
        static let firstAfter = Expression<String?>("first_after")
        static let secondAfter = Expression<String?>("second_after")
    }

    private lazy var dbFilePath: String = {
        let groupId = "group.no.divvun.GiellaKeyboardDylan"
        let dbFileName = "userDictionary.sqlite3"

        guard let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId) else {
            fatalError("Error opening app group for group id: \(groupId)")
        }

        return "\(groupUrl)\(dbFileName)"
    }()

    private lazy var database: Connection = {
        guard let database = try? Connection(dbFilePath) else {
            fatalError("Unable to create or open user dictionary database")
        }
        try? database.execute("PRAGMA foreign_keys = ON;")
        createTablesIfNeeded(database: database)
        return database
    }()

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

    public func add(word: String, locale: KeyboardLocale) {
        add(context: WordContext(word: word), locale: locale)
    }

    public func add(context: WordContext, locale: KeyboardLocale) {
        validateContext(context)

        let word = context.word
        let wordId: Int64

        if let existingWord = fetchWord(word, locale: locale) {
            wordId = existingWord[WordTable.id]
            if wordIsCandidate(existingWord) {
                updateWordState(id: wordId, state: .userWord)
            }
        } else {
            wordId = insertWordCandidate(word: word, locale: locale)
        }

        insertContext(context, for: wordId)
    }

    public func removeWord(_ word: String, locale: KeyboardLocale) {
        do {
            let query = WordTable.table.filter(WordTable.word == word)
            try database.run(query.delete())
        } catch {
            fatalError("Error deleting word from UserDictionary \(error)")
        }
    }

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

    private func fetchWord(_ word: String, locale: KeyboardLocale) -> SQLite.Row? {
        var row: SQLite.Row?
        do {
            let query = WordTable.table.filter(WordTable.word == word)
            row = try database.pluck(query)
        } catch {
            fatalError("Error finding existsing word: \(error)")
        }
        return row
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
    private func insertWordCandidate(word: String, locale: KeyboardLocale) -> Int64 {
        return insertWord(word: word, locale: locale, state: .candidate)
    }

    public func addWordManually(_ word: String, locale: KeyboardLocale) {
        if let existingWord = fetchWord(word, locale: locale) {
            updateWordState(id: existingWord[WordTable.id], state: .manuallyAdded)
        } else {
            let wordId = insertWord(word: word, locale: locale, state: .manuallyAdded)
            insertContext(WordContext(word: word), for: wordId)
        }
    }

    @discardableResult
    private func insertWord(word: String, locale: KeyboardLocale, state: WordState) -> Int64 {
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

    private func insertContext(_ context: WordContext, for wordId: Int64) {
        let insert = ContextTable.table.insert(
            ContextTable.wordId <- wordId,
            ContextTable.secondBefore <- context.secondBefore,
            ContextTable.firstBefore <- context.firstBefore,
            ContextTable.firstAfter <- context.firstAfter,
            ContextTable.secondAfter <- context.secondAfter
        )
        do {
            try database.run(insert)
        } catch {
            fatalError("Error inserting context into database: \(error)")
        }
    }

    public func getUserWords(locale: KeyboardLocale) -> [String] {
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

    public func containsWord(_ word: String, locale: KeyboardLocale) -> Bool {
        return fetchWord(word, locale: locale) != nil
    }

    public func getContexts(for word: String, locale: KeyboardLocale) -> [WordContext] {
        guard let wordRow = fetchWord(word, locale: locale) else {
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
}

// Methods used for testing only
extension UserDictionary {
    public func dropTables() {
        do {
            try database.run(WordTable.table.drop())
            try database.run(ContextTable.table.drop())
        } catch {
            fatalError("Error dropping database tables: \(error)")
        }
    }

    public func addTestRows(locale: KeyboardLocale) {
        let contexts = [
            WordContext(secondBefore: "I", firstBefore: "said", word: "hello"),
            WordContext(firstBefore: "well", word: "hello", firstAfter: "there"),
            WordContext(word: "hello", firstAfter: "to", secondAfter: "you"),
            WordContext(secondBefore: "I", firstBefore: "said", word: "hi"),
            WordContext(firstBefore: "say", word: "hi", firstAfter: "to"),
            WordContext(word: "hi", firstAfter: "there", secondAfter: "Frank")
        ]

        for context in contexts {
            add(context: context, locale: locale)
        }
    }

    public func printDatabaseRows() {
        do {
            print("WORDS TABLE:")
            for row in try database.prepare(WordTable.table) {
                let rowData = "id: \(row[WordTable.id]), "
                    + "word: \(String(describing: row[WordTable.word])), "
                    + "locale: \(row[WordTable.locale]), "
                    + "state: \(String(describing: row[WordTable.state])), "
                print(rowData)
            }

            print("\n")
            print("CONTEXT TABLE:")
            for row in try database.prepare(ContextTable.table) {
                let rowData = "id: \(row[ContextTable.id]), "
                    + "wordId: \(row[ContextTable.wordId]), "
                    + "Contexts.secondBefore: \(String(describing: row[ContextTable.secondBefore])), "
                    + "Contexts.firstBefore: \(String(describing: row[ContextTable.firstBefore])), "
                    + "Contexts.firstAfter: \(String(describing: row[ContextTable.firstAfter])), "
                    + "Contexts.secondAfter: \(String(describing: row[ContextTable.secondAfter]))"
                print(rowData)
            }

        } catch {
            print("Error printing database: \(error)")
        }
    }

    public func getWordDatabaseRows() -> [SQLite.Row] {
        return getDatabaseRows(for: WordTable.table)
    }

    public func getContextDatabaseRows() -> [SQLite.Row] {
        return getDatabaseRows(for: ContextTable.table)
    }

    private func getDatabaseRows(for table: Table) -> [SQLite.Row] {
        do {
            return try Array(database.prepare(table))
        } catch {
            fatalError("Error getting word database Rows")
        }
    }
}
