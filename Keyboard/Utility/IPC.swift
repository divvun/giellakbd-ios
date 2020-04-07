import Foundation
import Sentry

protocol IPCDelegate: class {
    func didBeginDownloading(id: String)
    func didFinishInstalling(id: String)
}

final class IPC {
//    enum DelegateCall {
//        case none
//        case didBeginDownloadingUpdate
//        case didFinishDownloadingUpdate
//    }

    weak var delegate: IPCDelegate? {
        didSet {
            setupFileWatcher()
        }
    }

    private var fileWatcher: SKQueue? = nil
    private var isDownloading: Set<String> = Set()

    private let ipcDirectory = KeyboardSettings.groupContainerURL
        .appendingPathComponent("ipc", isDirectory: true)
    
    // This one is for HostingApp
    public func startDownload(id: String) {
        try? FileManager.default.createDirectory(at: ipcDirectory, withIntermediateDirectories: true, attributes: nil)
        FileManager.default.createFile(atPath: file(for: id).path, contents: nil, attributes: nil)
    }

    // This one is for HostingApp
    public func finishDownload(id: String) {
        let ipcFile = file(for: id)
        guard fileExists(atUrl: ipcFile) else {
            return
        }
        try? FileManager.default.removeItem(at: ipcFile)
    }

    private func file(for downloadId: String) -> URL {
        return ipcDirectory.appendingPathComponent("download-\(downloadId)")
    }

    public func setupFileWatcher() {
        do {
            fileWatcher = try SKQueue(delegate: self)
            fileWatcher?.addPath(ipcDirectory.path) // kqueue requires adding the containing directory before the file of interest
            // TODO: watch all added files
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
        print(path)
//        let id = "hihihih" // get last path component to get the id
        guard let url = URL(string: path) else {
            return
        }
        let id = String(url.lastPathComponent.split(separator: "-")[1])
        print("ID: \(id)")
        print(url)

        if fileExists(atUrl: url) {
            if !self.isDownloading.contains(id) {
                self.isDownloading.insert(id)
                DispatchQueue.main.async {
//                    self.onStartDownload(id)
                    self.delegate?.didBeginDownloading(id: id)
                }
            }
        } else {
            if self.isDownloading.contains(id) {
                self.isDownloading.remove(id)
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
