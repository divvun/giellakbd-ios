import Foundation
import PahkatClient
import Sentry
import RxSwift

final class PahkatWrapper {
    private let store: PrefixPackageStore
    private let storePath = KeyboardSettings.pahkatStoreURL.path
    private var downloadTask: URLSessionDownloadTask?
    let ipc = IPC()
    let bag = DisposeBag()

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

//    func setBackgroundURLSessionCompletion(_ completion: @escaping (() -> Void)) {
//        store.backgroundURLSessionCompletion = completion
//    }

    func forceRefreshRepos() {
        do {
            try store.forceRefreshRepos()
        } catch {
            print("Error force refreshing repos: \(error)")
        }
    }

    func checkForSpellerUpdates(logger: @escaping (String) -> Void) -> Single<Void> {
        let packageKeys = enabledKeyboardPackageKeys

        // Set package repos correctly
        let repoUrls = Set(packageKeys.map { $0.repositoryURL })
        var repoMap = [URL: RepoRecord]()
        for key in repoUrls {
            repoMap[key] = RepoRecord(channel: "nightly")
        }

        do {
            logger("Setting repos: \(repoMap)")
            try store.set(repos: repoMap)
            try store.refreshRepos()
        } catch let error {
            // TODO use Sentry to catch this error
            return Single.error(error)
        }

        logger("Try to get status")
        let updates = packageKeys.filter { tryToGetStatus(for: $0) != .upToDate }

        return Observable.from(updates)
            .flatMap { key -> Single<Void> in
                logger("Downloading \(key.id)...")
                return self.downloadPackage(packageKey: key)
            }
            .toArray()
            .flatMap { _ -> Single<Void> in
                logger("Installing packages...")
                return self.install(packageKeys: updates)
            }
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

    private func install(packageKeys: [PackageKey]) -> Single<Void> {
        let actions = packageKeys.map { TransactionAction.install($0) }

        return Single<Void>.create(subscribe: { emitter in
            let delegate = TxDelegate(callback: { error in
                if let error = error {
                    print(error)
                    emitter(.error(error))
                } else {
                    emitter(.success(()))
                }
            })

            do {
                let transaction = try self.store.transaction(actions: actions)
                transaction.process(delegate: delegate)
            } catch {
                print(error)
                emitter(.error(error))
            }
            return Disposables.create()
        })
    }

    private func downloadPackage(packageKey: PackageKey) -> Single<Void> {
        return Single<Void>.create(subscribe: { emitter in
            do {
                print("!!!!!!!! Starting download for \(packageKey.id)")
                self.downloadTask = try self.store.download(packageKey: packageKey) { (error, _) in
                    print("!!!!!!!! DOWNLOAD CALLBACK DID HAPPEN for \(packageKey.id)")
                    self.ipc.finishDownload(id: packageKey.id)
                    if let error = error {
                        print("!!!!!!!! \(error)")
                        emitter(.error(error))
                        return
                    }
                    emitter(.success(()))
                }
                self.ipc.startDownload(id: packageKey.id)
            } catch {
                print("!!!!!!!! Pahkat download error: \(error)")
                emitter(.error(error))
            }

            return Disposables.create()
        })
    }
}

class TxDelegate: PackageTransactionDelegate {
    private let callback: (Error?) -> Void

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
        print(#function, "\(id)")
//        installCompletion(nil)
        callback(nil)
    }

    func transactionDidCancel(_ id: UInt32) {
        print(#function, "\(id)")
//        installCompletion(nil)
        callback(nil)
    }

    func transactionDidError(_ id: UInt32, packageKey: PackageKey?, error: Error?) {
        print(#function, "\(id) \(String(describing: error))")
        callback(error)
    }

    func transactionDidUnknownEvent(_ id: UInt32, packageKey: PackageKey?, event: UInt32) {
        print(#function, "\(id)")
    }

    init(callback: @escaping (Error?) -> Void) {
        self.callback = callback
    }
}
