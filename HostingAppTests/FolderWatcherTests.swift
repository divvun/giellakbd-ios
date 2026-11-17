@testable import BaseKeyboard
import XCTest

final class FolderWatcherTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        try super.tearDownWithError()
    }

    func test_addingAFile_notifiesTheDelegate() throws {
        let spy = DelegateSpy()
        let watcher = FolderWatcher(directory: directory)
        watcher.delegate = spy
        watcher.start()
        defer { watcher.stop() }

        let file = directory.appendingPathComponent("download-a")
        spy.added = expectation(description: "added")
        FileManager.default.createFile(atPath: file.path, contents: nil)
        wait(for: [spy.added!], timeout: 3)
        XCTAssertEqual(spy.addedURLs.map(\.lastPathComponent), ["download-a"])
    }

    func test_removingAFile_notifiesTheDelegate() throws {
        let file = directory.appendingPathComponent("download-a")
        FileManager.default.createFile(atPath: file.path, contents: nil)

        let spy = DelegateSpy()
        let watcher = FolderWatcher(directory: directory)
        watcher.delegate = spy
        watcher.start()
        defer { watcher.stop() }

        spy.removed = expectation(description: "removed")
        try FileManager.default.removeItem(at: file)
        wait(for: [spy.removed!], timeout: 3)
        XCTAssertEqual(spy.removedURLs.map(\.lastPathComponent), ["download-a"])
    }

    func test_stoppedWatcher_doesNotNotify() {
        let spy = DelegateSpy()
        let watcher = FolderWatcher(directory: directory)
        watcher.delegate = spy
        watcher.start()
        watcher.stop()

        spy.added = expectation(description: "added")
        spy.added?.isInverted = true
        FileManager.default.createFile(atPath: directory.appendingPathComponent("download-a").path, contents: nil)
        wait(for: [spy.added!], timeout: 1.5)
    }

    func test_startedWatcher_isReleasedWhenNoLongerUsed() {
        weak var weakWatcher: FolderWatcher?
        autoreleasepool {
            let watcher = FolderWatcher(directory: directory)
            watcher.start()
            weakWatcher = watcher
        }
        // The timer must not keep the watcher (and itself) alive forever.
        XCTAssertNil(weakWatcher)
    }

    func test_ipc_replacingTheDelegate_releasesTheOldWatcher() {
        let ipc = IPC()
        let first = DownloadSpy()
        let second = DownloadSpy()
        ipc.delegate = first
        weak var firstWatcher = ipc.folderWatcher
        ipc.delegate = second
        XCTAssertNotNil(ipc.folderWatcher)
        XCTAssertNil(firstWatcher)
    }
}

private final class DelegateSpy: FolderWatcherDelegate {
    var added: XCTestExpectation?
    var removed: XCTestExpectation?
    var addedURLs: [URL] = []
    var removedURLs: [URL] = []

    func fileWasAdded(at url: URL) {
        addedURLs.append(url)
        added?.fulfill()
    }

    func fileWasRemoved(at url: URL) {
        removedURLs.append(url)
        removed?.fulfill()
    }
}

private final class DownloadSpy: IPCDelegate {
    func didBeginDownloading(id: String) {}
    func didFinishInstalling(id: String) {}
}
