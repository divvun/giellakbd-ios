import Foundation

final class DownloadSimulator {
    let targetFileSizeInBytes = 25

    var currentFileSizeInBytes = 0
    private var timer = Timer()

    public func simulateDownload(url: URL) {
        deleteExisitingFileIfNeeded(url: url)

        let text = "a"
        appendTextToFile(text: text, fileUrl: url)

        timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true, block: { (timer) in
            guard self.currentFileSizeInBytes <= self.targetFileSizeInBytes else {
                timer.invalidate()
                // todo: post complete or something
                return
            }
            self.appendTextToFile(text: text, fileUrl: url)
        })
    }

    private func deleteExisitingFileIfNeeded(url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                fatalError("Couldn't delete file at path: \(url)")
            }
        }
    }

    private func appendTextToFile(text: String, fileUrl: URL) {
        let path = fileUrl.path
        let dataToWrite = text.data(using: .utf8)!

        guard FileManager.default.fileExists(atPath: path) else {
            FileManager.default.createFile(atPath: path, contents: dataToWrite, attributes: nil)
            return
        }

        guard let fileHandle = FileHandle(forWritingAtPath: fileUrl.path) else {
            fatalError("Couldn't open file at path: \(fileUrl)")
        }
        fileHandle.seekToEndOfFile()
        fileHandle.write(dataToWrite)
        let bytesAdded = dataToWrite.count
        currentFileSizeInBytes += bytesAdded
    }

    private func tryWritingToFile(text: String, url: URL) {
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            fatalError("Couldn't write to file: \(error)")
        }
    }
}
