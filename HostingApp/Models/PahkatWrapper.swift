import Foundation
import PahkatClient
import RxSwift

struct UnknownError: Error {
}

extension PrefixPackageStore {
    func downloadAsync(packageKey: PackageKey) -> Single<String> {
        return Single<String>.create { emitter -> Disposable in
            do {
                let task = try self.download(packageKey: packageKey, completion: { (error, result) in
                    if let result = result {
                        emitter(.success(result))
                        return
                    }

                    if let error = error {
                        emitter(.error(error))
                    } else {
                        emitter(.error(UnknownError()))
                    }
                })

                return Disposables.create {
                    task.cancel(byProducingResumeData: { resumableData in
                        // TODO: we should handle this for resuming broken downloads, but not right now.
                    })
                }
            } catch let error {
                emitter(.error(error))
                return Disposables.create()
            }
        }
    }
}

final class PahkatWrapper {
    private let store: PrefixPackageStore
    private let storePath = KeyboardSettings.pahkatStoreURL.path
    private let repoURL = "https://x.brendan.so/divvun-pahkat-repo"
    private var downloadTask: URLSessionDownloadTask?
    private let ipc = IPC()

    private let bag = DisposeBag()

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
        let packageIds = Set(enabledKeyboards.compactMap { $0.divvunPackageId })
        let packageKeys = packageIds.map { packageKey(from: $0) }
        let notInstalled = packageKeys.filter { tryToGetStatus(for: $0) == .notInstalled }

        downloadAndInstallPackages(packageKeys: notInstalled)
            .do(
                onSubscribe: { [weak self] in self?.ipc.isDownloading = true },
                onDispose: { [weak self] in self?.ipc.isDownloading = false }
            )
            .subscribe(onSuccess: { _ in
                print("Successfully installed packages!")
            }, onError: { error in
                print("Error occurred downloading and installing packages")
                print(error)
            })
            .disposed(by: bag)
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

    private func downloadAndInstallPackages(packageKeys: [PackageKey]) -> Single<Empty> {
        if packageKeys.isEmpty {
            return Single.just(Empty.instance)
        }

        let downloadSequentially = Observable.from(packageKeys)
            .map {
                self.store.downloadAsync(packageKey: $0)
            }
            .merge(maxConcurrent: 1)
            .toArray()

        return downloadSequentially.map { _ in
            let actions = packageKeys.map { TransactionAction.install($0) }
            let transaction = try self.store.transaction(actions: actions)
            transaction.process(delegate: self)
            return Empty.instance
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
