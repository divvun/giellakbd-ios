import Foundation

protocol FolderWatcherDelegate: class {
    func fileWasAdded(at url: URL)
    func fileWasRemoved(at url: URL)
}

final class FolderWatcher {
    public weak var delegate: FolderWatcherDelegate?
    private var watchedFolder: URL
    private var watchedFolderContents: Set<URL>
    private var timer: Timer?

    init(directory: URL) {
        self.watchedFolder = directory
        self.watchedFolderContents = getFolderContents(url: directory)
    }

    public func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
            self.notifyDelegateOfChanges()
        })
    }

    public func stop() {
        timer?.invalidate()
    }

    private func notifyDelegateOfChanges() {
        guard let delegate = delegate else {
            return
        }

        let newContents = getFolderContents(url: watchedFolder)
        let previousContents = watchedFolderContents

        if newContents == previousContents {
            return
        }

        let addedFiles = newContents.subtracting(previousContents)
        addedFiles.forEach { delegate.fileWasAdded(at: $0) }

        let removedFiles = previousContents.subtracting(newContents)
        removedFiles.forEach { delegate.fileWasRemoved(at: $0) }

        watchedFolderContents = newContents
    }
}

private func getFolderContents(url: URL) -> Set<URL> {
    do {
        let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
        return Set(contents)
    } catch {
        print("Error getting watched folder contents: \(error)")
        return Set()
    }
}
