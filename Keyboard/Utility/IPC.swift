import Foundation
import Sentry

protocol IPCDelegate: class {
    func didBeginDownloading(id: String)
    func didFinishInstalling(id: String)
}

final class IPC {
    weak var delegate: IPCDelegate? {
        didSet {
            setupFileWatcher()
        }
    }

    private var fileWatcher: SKQueue?
    private var currentlyDownloadingIds: Set<String> = Set()

    private let ipcDirectory = KeyboardSettings.groupContainerURL
        .appendingPathComponent("ipc", isDirectory: true)

    // This one is for HostingApp
    public func startDownload(id: String) {
        let ipcFilePath = file(for: id).path
        try? FileManager.default.createDirectory(at: ipcDirectory, withIntermediateDirectories: true, attributes: nil)
        FileManager.default.createFile(atPath: ipcFilePath, contents: nil, attributes: nil)
//        fileWatcher?.addPath(ipcFilePath)
    }

    // This one is for HostingApp
    public func finishDownload(id: String) {
        let ipcFile = file(for: id)
        guard fileExists(atUrl: ipcFile) else {
            return
        }
        try? FileManager.default.removeItem(at: ipcFile)
//        fileWatcher?.removePath(ipcFile.path)
    }

    private func file(for downloadId: String) -> URL {
        return ipcDirectory.appendingPathComponent("download-\(downloadId)")
    }

    public func setupFileWatcher() {
        do {
            fileWatcher = try SKQueue(delegate: self)
            fileWatcher?.addPath(ipcDirectory.path) // kqueue requires adding the containing directory before the file of interest
        } catch {
            let error = Sentry.Event(level: .error)
            Client.shared?.send(event: error, completion: nil)
        }
    }

    private func fileExists(atUrl: URL) -> Bool {
        return FileManager.default.fileExists(atPath: atUrl.path)
    }

//    public var onStartDownload: ((String) -> ())? = nil
//    public var onFinishDownload: ((String) -> ())? = nil
}

extension IPC: SKQueueDelegate {
    func receivedNotification(_ notification: SKQueueNotification, path: String, queue: SKQueue) {
        print(notification)

//        guard path != ipcDirectory.path else {
//             disregard changes to the ipc directory itself; only watch for files inside it
//            return
//        }

        guard let url = URL(string: path) else {
            return
        }

        let id = String(url.lastPathComponent.split(separator: "-").last!)
        if fileExists(atUrl: url) {
            if self.currentlyDownloadingIds.contains(id) == false {
                self.currentlyDownloadingIds.insert(id)
                DispatchQueue.main.async {
//                    self.onStartDownload(id)
                    self.delegate?.didBeginDownloading(id: id)
                }
            }
        } else {
            if self.currentlyDownloadingIds.contains(id) {
                self.currentlyDownloadingIds.remove(id)
                DispatchQueue.main.async {
//                    self.onFinishDownload(id)
                    self.delegate?.didFinishInstalling(id: id)
                }
            }
        }
    }
}

// final class IPC {
//     enum DelegateCall {
//         case none
//         case didBeginDownloadingUpdate
//         case didFinishDownloadingUpdate
//     }

//     weak var delegate: IPCDelegate? {
//         didSet {
//             tryToSetupFileWatcher()
//         }
//     }
//     private var fileWatcher: SKQueue?
//     private let ipcDirectory = KeyboardSettings.groupContainerURL.appendingPathComponent("ipc", isDirectory: true)
//     private lazy var isDownloadingFile = ipcDirectory.appendingPathComponent("isDownloading")

//     private var lastDelegateCall = DelegateCall.none

//     public var isDownloading: Bool {
//         set {
//             if newValue == true {
//                 createIsDownloadingFile()
//             } else {
//                 removeIsDownloadingFile()
//             }
//         }
//         get {
//             fileExists(atUrl: isDownloadingFile)
//         }
//     }

//     func tryToSetupFileWatcher() {
//         do {
//             fileWatcher = try SKQueue(delegate: self)
//             fileWatcher?.addPath(ipcDirectory.path) // kqueue requires adding the containing directory before the file of interest
//         } catch {
//             fatalError("Error creating SKQueue: \(error)")
//         }
//     }

//     private func createIsDownloadingFile() {
//         createIpcDirectoryIfNeeded()
//         if !fileExists(atUrl: isDownloadingFile) {
//             FileManager.default.createFile(atPath: isDownloadingFile.path, contents: nil, attributes: nil)
//         }
//     }

//     private func createIpcDirectoryIfNeeded() {
//         if !fileExists(atUrl: ipcDirectory) {
//             do {
//                 try FileManager.default.createDirectory(at: ipcDirectory, withIntermediateDirectories: true, attributes: nil)
//             } catch {
//                 fatalError("Error creating ipc directory: \(error)")
//             }
//         }
//     }

//     private func removeIsDownloadingFile() {
//         guard fileExists(atUrl: isDownloadingFile) else {
//             return
//         }
//         try? FileManager.default.removeItem(at: isDownloadingFile)
//     }

//     private func fileExists(atUrl: URL) -> Bool {
//         return FileManager.default.fileExists(atPath: atUrl.path)
//     }
// }
