import Foundation
import SQLite

public class UserDictionary {
    private let userDictionary = Table("UserDictionary")
    private let id = Expression<Int64>("id")
    private let word1Col = Expression<String>("word1")
    private let word2Col = Expression<String?>("word2")
    private let word3Col = Expression<String?>("word3")
    private let userWordIndexCol = Expression<Int64>("user_word_index")

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
                table.column(word1Col)
                table.column(word2Col)
                table.column(word3Col)
                table.column(userWordIndexCol)
            })
        } catch {
            fatalError("Error creating database table: \(error)")
        }
    }

    public func addTestRows() {
        let names = ["Captain", "Wishbone", "Salad", "Dirk"]
        for personName in names {
            add(word1: personName, word2: "other", userWordIndex: 1)
        }
    }

    public func add(word1: String, word2: String? = nil, word3: String? = nil, userWordIndex: Int = 0) {
        guard userWordIndex >= 0 else {
            fatalError("Attempted to add word to UserDictionary with below-zero index")
        }
        if word3 != nil && word2 == nil {
            let message = "Attempted to add non-nil word3 with nil word2 to UserDictionary."
                + " Ensure word2 is non-nil before adding a word3."
            fatalError(message)
        }
        if word3 == nil && userWordIndex > 1
            || word2 == nil && userWordIndex > 0 {
            fatalError("Attempted to add word to UserDictionary with invalid word index. userWordIndex: \(userWordIndex)")
        }

        let insert = userDictionary.insert(word1Col <- word1,
                                           word2Col <- word2,
                                           word3Col <- word3,
                                           userWordIndexCol <- Int64(userWordIndex))
        do {
            try database.run(insert)
        } catch {
            print("Error inserting into database: \(error)")
        }
    }

    public func printDatabaseRows() {
        do {
            for row in try database.prepare(userDictionary) {
                let rowData = "id: \(row[id]), "
                    + "word1: \(String(describing: row[word1Col])), "
                    + "word2: \(String(describing: row[word2Col])), "
                    + "word3: \(String(describing: row[word3Col])), "
                    + "index: \(row[userWordIndexCol])"
                print(rowData)
            }
        } catch {
            print("Error printing database: \(error)")
        }
    }
}
