import Foundation
import SQLite

private let tableName = "user_dictionary"

public class UserDictionary {
    private let userDictionary = Table(tableName)
    private let id = Expression<Int64>("id")
    private let word0Col = Expression<String>("word0")
    private let word1Col = Expression<String?>("word1")
    private let word2Col = Expression<String?>("word2")
    private let userWordIndexCol = Expression<Int64>("user_word_index")

    private let minOccurrencesToBeConsideredUserWord = 2

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
        createTableIfNeeded(database: database)
        return database
    }()

    private func createTableIfNeeded(database: Connection) {
        do {
            try database.run(userDictionary.create(ifNotExists: true) { table in
                table.column(id, primaryKey: true)
                table.column(word0Col)
                table.column(word1Col)
                table.column(word2Col)
                table.column(userWordIndexCol)
            })
        } catch {
            fatalError("Error creating database table: \(error)")
        }
    }

    public func addTestRows() {
        let names = ["Captain", "Wishbone", "Salad", "Dirk"]
        for personName in names {
            add(word0: personName, word1: "other", word2: "other2", userWordIndex: 0)
        }
    }

    public func deleteAllWords() {
        do {
            try database.run(userDictionary.delete())
        } catch {
            fatalError("Error deleting all words from database: \(error)")
        }
    }

    public func add(word0: String, word1: String? = nil, word2: String? = nil, userWordIndex: Int = 0) {
        guard userWordIndex >= 0 else {
            fatalError("Attempted to add word to UserDictionary with below-zero index")
        }
        if word2 != nil && word1 == nil {
            let message = "Attempted to add non-nil word3 with nil word2 to UserDictionary."
                + " Ensure word2 is non-nil before adding a word3."
            fatalError(message)
        }
        if word2 == nil && userWordIndex > 1
            || word1 == nil && userWordIndex > 0 {
            fatalError("Attempted to add word to UserDictionary with invalid word index. userWordIndex: \(userWordIndex)")
        }

        let insert = userDictionary.insert(word0Col <- word0,
                                           word1Col <- word1,
                                           word2Col <- word2,
                                           userWordIndexCol <- Int64(userWordIndex))
        do {
            try database.run(insert)
        } catch {
            print("Error inserting into database: \(error)")
        }
    }

    public func addUserWord(_ word: String, locale: KeyboardLocale) {
        for _ in 0 ..< minOccurrencesToBeConsideredUserWord {
            add(word0: word, locale: locale)
        }
    }

    public func printDatabaseRows() {
        do {
            for row in try database.prepare(userDictionary) {
                let rowData = "id: \(row[id]), "
                    + "word0: \(String(describing: row[word0Col])), "
                    + "word1: \(String(describing: row[word1Col])), "
                    + "word2: \(String(describing: row[word2Col])), "
                    + "index: \(row[userWordIndexCol])"
                print(rowData)
            }
        } catch {
            print("Error printing database: \(error)")
        }
    }

    public func getUserWords() -> [String] {
        var userWords: [String] = []
        let query = """
                    SELECT LOWER(user_word),
                           Count(user_word) AS COUNT
                    FROM
                      (SELECT CASE \(userWordIndexCol.template)
                                  WHEN 0 THEN \(word0Col.template)
                                  WHEN 1 THEN \(word1Col.template)
                                  WHEN 2 THEN \(word2Col.template)
                              END user_word
                       FROM \(tableName))
                    GROUP BY user_word COLLATE NOCASE
                    HAVING COUNT >= \(minOccurrencesToBeConsideredUserWord);
                    """
        do {
            let words = try database.prepare(query)
            for row in words {
                if let word = row[0] as? String {
                    userWords.append(word)
                }
            }
        } catch {
            print("Error getting user words: \(error)")
        }
        return userWords
    }

    public func getContexts(for word: String) -> [WordContext] {
        var contexts: [WordContext] = []

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
            FROM \(tableName)
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

        return contexts
    }
}
