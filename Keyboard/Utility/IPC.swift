import Foundation
//import Sentry

protocol IPCDelegate: AnyObject {
    func didBeginDownloading(id: String)
    func didFinishInstalling(id: String)
}

final class IPC {
    weak var delegate: IPCDelegate? {
        didSet {
            setupFolderWatcher()
        }
    }

    private var folderWatcher: FolderWatcher?
    private let ipcDirectory = KeyboardSettings.groupContainerURL
        .appendingPathComponent("ipc", isDirectory: true)

    init() {
        do {
            try FileManager.default.createDirectory(at: ipcDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            fatalError("Couldn't create IPC directory")
        }
    }

    // This one is for HostingApp
    public func startDownload(id: String) {
        let ipcFilePath = file(for: id).path
        FileManager.default.createFile(atPath: ipcFilePath, contents: nil, attributes: nil)
    }

    // This one is for HostingApp
    public func finishDownload(id: String) {
        let ipcFile = file(for: id)
        guard fileExists(atUrl: ipcFile) else {
            return
        }
        try? FileManager.default.removeItem(at: ipcFile)
    }

    private func setupFolderWatcher() {
        folderWatcher = FolderWatcher(directory: ipcDirectory)
        folderWatcher?.delegate = self
        folderWatcher?.start()
    }

    public func isDownloading(id: String) -> Bool {
        let fileURL = file(for: id)
        return fileExists(atUrl: fileURL)
    }

    private func file(for downloadId: String) -> URL {
        return ipcDirectory.appendingPathComponent("download-\(downloadId)")
    }

    private func downloadId(from file: URL) -> String {
        return String(file.lastPathComponent.split(separator: "-").last!)
    }

    private func fileExists(atUrl: URL) -> Bool {
        return FileManager.default.fileExists(atPath: atUrl.path)
    }
}

extension IPC: FolderWatcherDelegate {
    func fileWasAdded(at url: URL) {
        let id = downloadId(from: url)
        delegate?.didBeginDownloading(id: id)
    }

    func fileWasRemoved(at url: URL) {
        let id = downloadId(from: url)
        delegate?.didFinishInstalling(id: id)
    }
}
