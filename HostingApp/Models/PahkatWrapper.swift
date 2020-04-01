import Foundation
import PahkatClient

final class PahkatWrapper {
    private let store: PrefixPackageStore
    private let storePath = KeyboardSettings.pahkatStoreURL.path
    private let repoURL = "https://x.brendan.so/divvun-pahkat-repo"
    private var downloadTask: URLSessionDownloadTask?
    private let ipc = IPC()

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

    func installSpellersForNewlyEnabledKeyboards() {
        let enabledKeyboards = Bundle.enabledKeyboardBundles
        let packageIds = enabledKeyboards.compactMap { $0.divvunPackageId }
        let packageKeys = packageIds.map { packageKey(from: $0) }
        let notInstalled = packageKeys.filter { tryToGetStatus(for: $0) == .notInstalled }
        downloadAndInstallPackagesOneByOne(packageKeys: notInstalled)
    }

    private func tryToGetStatus(for packageKey: PackageKey) -> PackageInstallStatus {
        do {
            return try store.status(for: packageKey)
        } catch {
            fatalError("Error getting status for pahkat package key: \(error)")
        }
    }

    private func packageKey(from packageId: String) -> PackageKey {
        let path = "/packages/\(packageId)?platform=ios"
        return PackageKey(from: URL(string: repoURL + path)!)
    }

    private func downloadAndInstallPackagesOneByOne(packageKeys: [PackageKey]) {
        guard let firstPackage = packageKeys.first else {
            return
        }

        downloadAndInstallPackage(packageKey: firstPackage) {
            self.downloadAndInstallPackagesOneByOne(packageKeys: Array(packageKeys.dropFirst()))
        }
    }

    private func downloadAndInstallPackage(packageKey: PackageKey, completion: (() -> Void)?) {
        ipc.isDownloading = true
        print("INSTALLING: \(packageKey)")
        do {
            downloadTask = try store.download(packageKey: packageKey) { (error, path) in
                completion?()
                if let error = error {
                    print(error)
                    return
                }

                let action = TransactionAction.install(packageKey)

                do {
                    let transaction = try self.store.transaction(actions: [action])
                    transaction.process(delegate: self)
                } catch {
                    print(error)
                }
                self.ipc.isDownloading = false
                print("Done!")
            }
        } catch {
            ipc.isDownloading = false
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
