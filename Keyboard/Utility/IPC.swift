import Foundation

fileprivate let trueStr = "1"
fileprivate let falseStr = "0"

protocol IPCDelegate: class {
    func didBeginDownloadingUpdate()
    func didFinishDownloadingUpdate()
}

final class IPC {
    weak var delegate: IPCDelegate?
    private var fileWatcher: SKQueue?
    private let ipcDirectory = KeyboardSettings.groupContainerURL.appendingPathComponent("ipc", isDirectory: true)
    private lazy var isDownloadingFile = ipcDirectory.appendingPathComponent("isDownloading")

    private let trueData = trueStr.data(using: .utf8)!
    private let falseData = falseStr.data(using: .utf8)!

    public var isDownloading: Bool {
        set {
            if isDownloading != newValue {
                tryToWrite(isDownloading: newValue)
            }
        }
        get {
            tryToReadIsDownloading()
        }
    }

    init(delegate: IPCDelegate?) {
        createIsDownloadingFile()
        if let delegate = delegate {
            self.delegate = delegate
            tryToSetupFileWatcher()
        }
    }

    func tryToSetupFileWatcher() {
        do {
            fileWatcher = try SKQueue(delegate: self)
            fileWatcher?.addPath(ipcDirectory.path) // kqueue requires adding the containing directory before adding the file of interest
            fileWatcher?.addPath(isDownloadingFile.path)
        } catch {
            fatalError("Error creating SKQueue: \(error)")
        }
    }

    private func tryToWrite(isDownloading: Bool) {
        do {
            let data = isDownloading ? trueData : falseData
            try data.write(to: isDownloadingFile)
        } catch {
            fatalError("Error writing isDownloading file: \(error)")
        }
    }

    private func tryToReadIsDownloading() -> Bool {
        do {
            let str = try String(contentsOf: isDownloadingFile, encoding: .utf8)
            return str == trueStr
        } catch {
            fatalError("Error reading isDownloading file: \(error)")
        }
    }

    private func createIsDownloadingFile() {
        createIpcDirectoryIfNeeded()
        if !fileExists(atUrl: isDownloadingFile) {
            FileManager.default.createFile(atPath: isDownloadingFile.path, contents: falseData, attributes: nil)
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
        if path == isDownloadingFile.path {
            if notification == .write {
                if isDownloading {
                    delegate?.didBeginDownloadingUpdate()
                } else {
                    delegate?.didFinishDownloadingUpdate()
                }
            }
        }
    }
}
