import Foundation
import SQLite

extension UserDictionary {
    public func dropTables() {
        do {
            try database.run(WordTable.table.drop())
            try database.run(ContextTable.table.drop())
        } catch {
            fatalError("Error dropping database tables: \(error)")
        }
    }

    public func add(word: String) {
        add(context: WordContext(word: word))
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
            add(context: context)
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
