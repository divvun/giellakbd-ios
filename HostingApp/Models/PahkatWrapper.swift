import Foundation
import PahkatClient

final class PahkatWrapper {
    private let store: PrefixPackageStore
    private let storePath = KeyboardSettings.groupContainerURL.appendingPathComponent("pahkat").path
    private let repoURL = "https://x.brendan.so/divvun-pahkat-repo"
    private var downloadTask: URLSessionDownloadTask?

    init?() {
        do {
            store = try PrefixPackageStore.create(path: storePath)
        } catch {
            do {
                store = try PrefixPackageStore.open(path: storePath)
            } catch {
                print(error)
                return nil
            }
        }
    }

    func forceRefreshRepos() {
        do {
            try store.forceRefreshRepos()
        } catch {
            print("Error force refreshing repos: \(error)")
        }
    }

    func downloadPackage() {
        let path = "/packages/speller-sme?platform=ios"
        let pkgKey = PackageKey(from: URL(string: repoURL + path)!)

        do {
            downloadTask = try store.download(packageKey: pkgKey) { (error, path) in
                if let error = error {
                    print(error)
                    return
                }

                if let path = path {
                    print(path)
                }

                let action = TransactionAction.install(pkgKey)

                do {
                    let transaction = try self.store.transaction(actions: [action])
                    transaction.process(delegate: self)
                } catch {
                    print(error)
                }
                print("Done!")
            }
        } catch {
            print(error)
        }
    }
}

extension PahkatWrapper: PackageTransactionDelegate {
    func isTransactionCancelled(_ id: UInt32) -> Bool {
        return false
    }

    func transactionWillInstall(_ id: UInt32, packageKey: PackageKey) {
        print(#function, "\(id)")
    }

    func transactionWillUninstall(_ id: UInt32, packageKey: PackageKey) {
        print(#function, "\(id)")
    }

    func transactionDidComplete(_ id: UInt32) {
        print(#function, "\(id)")
    }

    func transactionDidCancel(_ id: UInt32) {
        print(#function, "\(id)")
    }

    func transactionDidError(_ id: UInt32, packageKey: PackageKey?, error: Error?) {
        print(#function, "\(id) \(String(describing: error))")
    }

    func transactionDidUnknownEvent(_ id: UInt32, packageKey: PackageKey, event: UInt32) {
        print(#function, "\(id)")
    }
}
