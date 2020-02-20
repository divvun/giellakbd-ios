import Foundation
import SQLite

public struct UserWordContext {
    let secondBefore: String?
    let firstBefore: String?
    let firstAfter: String?
    let secondAfter: String?
}

private let userWordsTableName = "user_word"
private let wordContextTableName = "word_context"

public class UserDictionary {
    private enum WordState: String {
        case candidate
        case userWord = "user_word"
        case manuallyAdded = "manually_added"
        case blacklisted
    }

    private let userWords = Table(userWordsTableName)
    private let wordIdCol = Expression<Int64>("id")
    private let wordCol = Expression<String>("word")
    private let localeCol = Expression<String>("locale")
    private let stateCol = Expression<String>("state")

    private let wordContext = Table(wordContextTableName)
    private let contextId = Expression<Int64>("id")
    private let secondBefore = Expression<String?>("second_before")
    private let firstBefore = Expression<String?>("first_before")
    private let firstAfter = Expression<String?>("first_after")
    private let secondAfter = Expression<String?>("second_after")

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
        try database.run(userWords.create(ifNotExists: true) { table in
            table.column(wordIdCol, primaryKey: true)
            table.column(wordCol, collate: .nocase)
            table.column(localeCol)
            table.column(stateCol)
        })
    }

    private func createWordContextTable(database: Connection) throws {
        try database.run(wordContext.create(ifNotExists: true) { table in
            table.column(contextId, primaryKey: true)
            table.column(secondBefore)
            table.column(firstBefore)
            table.column(firstAfter)
            table.column(secondAfter)
        })
    }

    public func add(word: String, locale: KeyboardLocale, context: UserWordContext? = nil) {
        if let context = context {
            validateContext(context)
        }

        let wordId: Int64

        if let existingWord = fetchExistingWord(word: word, locale: locale) {
            promoteExistingWordIfNeeded(row: existingWord)
            wordId = existingWord[wordIdCol]
        } else {
            wordId = insertWordCandidate(word: word, locale: locale)
        }

        if let context = context {
            insertContext(context, for: wordId)
        }
    }

    private func fetchExistingWord(word: String, locale: KeyboardLocale) -> SQLite.Row? {
        var row: SQLite.Row?
        do {
            let query = userWords.filter(wordCol == word)
            row = try database.pluck(query)
        } catch {
            fatalError("Error finding existsing word: \(error)")
        }
        return row
    }

    private func promoteExistingWordIfNeeded(row: SQLite.Row) {
        let id = row[wordIdCol]
        switch WordState(rawValue: row[stateCol]) {
        case .candidate:
            updateWordState(id: id, state: .userWord)
        default:
            break
        }
    }

    @discardableResult
    private func insertWordCandidate(word: String, locale: KeyboardLocale) -> Int64 {
        return insertWord(word: word, locale: locale, state: .candidate)
    }

    public func addWordManually(_ word: String, locale: KeyboardLocale) {
        if let existingWord = fetchExistingWord(word: word, locale: locale) {
            updateWordState(id: existingWord[wordIdCol], state: .manuallyAdded)
        } else {
            insertWord(word: word, locale: locale, state: .manuallyAdded)
        }
    }

    @discardableResult
    private func insertWord(word: String, locale: KeyboardLocale, state: WordState) -> Int64 {
        let insert = userWords.insert(
            wordCol <- word.lowercased(),
            localeCol <- locale.identifier,
            stateCol <- state.rawValue
        )

        do {
            return try database.run(insert)
        } catch {
            fatalError("Error inserting into database: \(error)")
        }
    }

    private func updateWordState(id: Int64, state: WordState) {
        do {
            let word = userWords.filter(wordIdCol == id)
            try database.run(word.update(stateCol <- state.rawValue))
        } catch {
            fatalError("Error updating word state \(error)")
        }
    }

    private func validateContext(_ context: UserWordContext) {
        if context.secondBefore != nil && context.firstBefore == nil {
            fatalError("Attempted to add word to UserDictionary with secondBefore word but no firstBefore word.")
        }
        if context.secondAfter != nil && context.firstAfter == nil {
            fatalError("Attempted to add word to UserDictionary with secondAfter word but no firstAfter word.")
        }
    }

    private func insertContext(_ context: UserWordContext, for wordId: Int64) {
        let insert = wordContext.insert(
            secondBefore <- context.secondBefore,
            firstBefore <- context.firstBefore,
            firstAfter <- context.firstAfter,
            secondAfter <- context.secondAfter
        )
        do {
            try database.run(insert)
        } catch {
            fatalError("Error inserting context into database: \(error)")
        }
    }

    public func dropTables() {
        do {
            try database.run(userWords.drop())
            try database.run(wordContext.drop())
        } catch {
            fatalError("Error dropping database tables: \(error)")
        }
    }

    public func printDatabaseRows() {
        do {
            for row in try database.prepare(userWords) {
                let rowData = "id: \(row[wordIdCol]), "
                    + "word: \(String(describing: row[wordCol])), "
                    + "locale: \(row[localeCol]), "
                    + "state: \(String(describing: row[stateCol])), "
                print(rowData)
            }
        } catch {
            print("Error printing database: \(error)")
        }
    }

    public func getUserWords(locale: KeyboardLocale) -> [String] {
        var words: [String] = []
        let query = userWords.select(wordCol)
            .filter(localeCol == locale.identifier)
            .filter(stateCol == WordState.userWord.rawValue || stateCol == WordState.manuallyAdded.rawValue)
        do {
            let rows = try database.prepare(query)
            for row in rows {
                let word = row[wordCol]
                words.append(word)
            }
        } catch {
            print("Error getting user words: \(error)")
        }
        return words
    }

    public func getContexts(for word: String) -> [WordContext] {
        var contexts: [WordContext] = []

    /*
        let word0 = word0Col.template
        let word1 = word1Col.template
        let word2 = word2Col.template

        let query = """
        SELECT \(word0),
               \(word1),
               \(word2)
        FROM
            (SELECT \(word0),
                    \(word1),
                    \(word2),
            CASE \(userWordIndexCol.template)
                WHEN 0 THEN \(word0)
                WHEN 1 THEN \(word1)
                WHEN 2 THEN \(word2)
            END user_word
            FROM \(userWordsTableName)
            WHERE user_word = '\(word)' COLLATE NOCASE)
        """

        do {
            let rows = try database.prepare(query)
            for row in rows {
                guard let word0 = row[0] as? String else {
                    fatalError("UserDictionary: Unexpectedly found nil in word0 column.")
                }
                let word1 = row[1] as? String ?? nil
                let word2 = row[2] as? String ?? nil

                let context = WordContext(word0: word0,
                                          word1: word1,
                                          word2: word2,
                                          userWord: word)
                contexts.append(context)
            }
        } catch {
            print("Error getting user word contexts: \(error)")
        }

         */
        return contexts
    }
}
