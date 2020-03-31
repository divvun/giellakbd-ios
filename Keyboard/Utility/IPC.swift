import Foundation

protocol IPCDelegate: class {
    func didBeginDownloadingUpdate()
    func didFinishDownloadingUpdate()
}

final class IPC {
    enum DelegateCall {
        case none
        case didBeginDownloadingUpdate
        case didFinishDownloadingUpdate
    }

    weak var delegate: IPCDelegate? {
        didSet {
            tryToSetupFileWatcher()
        }
    }
    private var fileWatcher: SKQueue?
    private let ipcDirectory = KeyboardSettings.groupContainerURL.appendingPathComponent("ipc", isDirectory: true)
    private lazy var isDownloadingFile = ipcDirectory.appendingPathComponent("isDownloading")

    private var lastDelegateCall = DelegateCall.none

    public var isDownloading: Bool {
        set {
            if newValue == true {
                createIsDownloadingFile()
            } else {
                removeIsDownloadingFile()
            }
        }
        get {
            fileExists(atUrl: isDownloadingFile)
        }
    }

    init() {
        createIsDownloadingFile()
    }

    func tryToSetupFileWatcher() {
        do {
            fileWatcher = try SKQueue(delegate: self)
            fileWatcher?.addPath(ipcDirectory.path) // kqueue requires adding the containing directory before the file of interest
        } catch {
            fatalError("Error creating SKQueue: \(error)")
        }
    }

    private func createIsDownloadingFile() {
        createIpcDirectoryIfNeeded()
        if !fileExists(atUrl: isDownloadingFile) {
            FileManager.default.createFile(atPath: isDownloadingFile.path, contents: nil, attributes: nil)
        }
    }

    private func createIpcDirectoryIfNeeded() {
        if !fileExists(atUrl: ipcDirectory) {
            do {
                try FileManager.default.createDirectory(at: ipcDirectory, withIntermediateDirectories: false, attributes: nil)
            } catch {
                fatalError("Error creating ipc directory: \(error)")
            }
        }
    }

    private func removeIsDownloadingFile() {
        guard fileExists(atUrl: isDownloadingFile) else {
            return
        }
        try? FileManager.default.removeItem(at: isDownloadingFile)
    }

    private func fileExists(atUrl: URL) -> Bool {
        return FileManager.default.fileExists(atPath: atUrl.path)
    }
}

extension IPC: SKQueueDelegate {
    func receivedNotification(_ notification: SKQueueNotification, path: String, queue: SKQueue) {
        print(notification)
        print(path)
        if fileExists(atUrl: isDownloadingFile) {
            if lastDelegateCall != .didBeginDownloadingUpdate {
                DispatchQueue.main.async {
                    self.delegate?.didBeginDownloadingUpdate()
                }
                lastDelegateCall = .didBeginDownloadingUpdate
            }
        } else {
            if lastDelegateCall != .didFinishDownloadingUpdate {
                DispatchQueue.main.async {
                    self.delegate?.didFinishDownloadingUpdate()
                }
                lastDelegateCall = .didFinishDownloadingUpdate
            }
        }
    }
}
