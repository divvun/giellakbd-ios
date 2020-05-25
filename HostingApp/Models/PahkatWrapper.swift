import Foundation
import PahkatClient

final class PahkatWrapper {
    private let store: PrefixPackageStore
    private let storePath = KeyboardSettings.pahkatStoreURL.path
    private var downloadTask: URLSessionDownloadTask?
    private let ipc = IPC()
    private var currentDownloadId: String?
    private var installCompletion: ((Error?) -> Void) = { _ in () }

    private var enabledKeyboardPackageKeys: [PackageKey] {
        let enabledKeyboards = Bundle.enabledKeyboardBundles
        let packageKeyStrings = Set(enabledKeyboards.compactMap { $0.spellerPackageKey })
        return packageKeyStrings.compactMap { try? PackageKey.from(url: $0) }
    }

    private var notInstalledKeyboardPackageKeys: [PackageKey] {
        return enabledKeyboardPackageKeys.filter { tryToGetStatus(for: $0) == .notInstalled }
    }

    public var needsInstall: Bool {
        return notInstalledKeyboardPackageKeys.count != 0
    }

    init?() {
        do {
            store = try PrefixPackageStore.create(path: storePath)
        } catch {
            do {
                store = try PrefixPackageStore.open(path: storePath)
            } catch {
                print("Error opening Pahkat PrefixPackageStore: \(error)")
                return nil
            }
        }
    }

    func setBackgroundURLSessionCompletion(_ completion: @escaping (() -> Void)) {
        store.backgroundURLSessionCompletion = completion
    }

    func forceRefreshRepos() {
        do {
            try store.forceRefreshRepos()
        } catch {
            print("Error force refreshing repos: \(error)")
        }
    }

    func installSpellersForNewlyEnabledKeyboards(completion: @escaping ((Error?) -> Void)) {
        let packageKeys = enabledKeyboardPackageKeys

        // Set package repos correctly
        let repoUrls = Set(packageKeys.map { $0.repositoryURL })
        var repoMap = [URL: RepoRecord]()
        for key in repoUrls {
            repoMap[key] = RepoRecord(channel: "nightly")
        }

        do {
            print("Setting repos: \(repoMap)")
            try store.set(repos: repoMap)
            try store.refreshRepos()
        } catch let error {
            // TODO use Sentry to catch this error
            print(error)
            return
        }

        print("Try to get status")
        let notInstalled = packageKeys.filter { tryToGetStatus(for: $0) == .notInstalled }

        print("Not installed: \(notInstalled)")
        downloadAndInstallPackagesSequentially(packageKeys: notInstalled, completion: completion)
    }

    private func tryToGetStatus(for packageKey: PackageKey) -> PackageInstallStatus {
        do {
            return try store.status(for: packageKey)
        } catch {
            fatalError("Error getting status for pahkat package key: \(error)")
        }
    }

    private func packageKey(from packageKey: String) -> PackageKey? {
        guard let url = URL(string: packageKey) else { return nil }
        return try? PackageKey.from(url: url)
    }

    private func downloadAndInstallPackagesSequentially(packageKeys: [PackageKey], completion: @escaping ((Error?) -> Void)) {
        if packageKeys.isEmpty {
            print("Done")
            completion(nil)
            return
        }

        downloadAndInstallPackage(packageKey: packageKeys[0]) { error in
            if let error = error {
                completion(error)
                return
            }
            self.downloadAndInstallPackagesSequentially(packageKeys: Array(packageKeys.dropFirst()), completion: completion)
        }
    }

    private func downloadAndInstallPackage(packageKey: PackageKey, completion: @escaping ((Error?) -> Void)) {
        print("INSTALLING: \(packageKey)")
        do {
            downloadTask = try store.download(packageKey: packageKey) { (error, _) in
                if let error = error {
                    print(error)
                    completion(error)
                    return
                }

                self.installCompletion = completion
                let action = TransactionAction.install(packageKey)

                do {
                    let transaction = try self.store.transaction(actions: [action])
                    transaction.process(delegate: self)
                    completion(nil)
                } catch {
                    print("Pahkat transaction error: \(error)")
                    completion(error)
                    return
                }
                print("Done!")
            }
            ipc.startDownload(id: packageKey.id)
            currentDownloadId = packageKey.id
        } catch {
            print("Pahkat download error: \(error)")
            completion(error)
        }
    }
}

extension PahkatWrapper: PackageTransactionDelegate {
    func isTransactionCancelled(_ id: UInt32) -> Bool {
        return false
    }

    func transactionWillInstall(_ id: UInt32, packageKey: PackageKey?) {
        print(#function, "\(id)")
    }

    func transactionWillUninstall(_ id: UInt32, packageKey: PackageKey?) {
        print(#function, "\(id)")
    }

    func transactionDidComplete(_ id: UInt32) {
        if let currentDownloadId = currentDownloadId {
            ipc.finishDownload(id: currentDownloadId)
            self.currentDownloadId = nil
        }
        print(#function, "\(id)")
        installCompletion(nil)
    }

    func transactionDidCancel(_ id: UInt32) {
        print(#function, "\(id)")
        installCompletion(nil)
    }

    func transactionDidError(_ id: UInt32, packageKey: PackageKey?, error: Error?) {
        print(#function, "\(id) \(String(describing: error))")
        installCompletion(error)
    }

    func transactionDidUnknownEvent(_ id: UInt32, packageKey: PackageKey?, event: UInt32) {
        print(#function, "\(id)")
    }
}
