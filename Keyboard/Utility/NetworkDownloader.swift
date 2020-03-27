import Foundation

final class NetworkDownloader: NSObject {
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "networkDownloader")
        config.sharedContainerIdentifier = KeyboardSettings.groupId
        config.shouldUseExtendedBackgroundIdleMode = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private lazy var sharedGroupURL: URL = {
        let groupId = KeyboardSettings.groupId
        guard let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId) else {
            fatalError("Error opening app group for group id: \(groupId)")
        }
        return groupUrl
    }()

    func downloadFile() {
        let url = URL(string: "https://pahkat.uit.no/artifacts/speller-smn-1.0.0.pkg")!
//        let downloadTask = urlSession.downloadTask(with: url)
//        downloadTask.resume()
        let dataTask = urlSession.dataTask(with: url)
        dataTask.resume()
    }

    deinit {
        self.urlSession.finishTasksAndInvalidate()
    }
}

extension NetworkDownloader: URLSessionDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print(#function)
    }

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print(#function)
    }

}

extension NetworkDownloader: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print(#function)
        print(data)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        print(#function)
        print(response)
        completionHandler(.allow)
    }
}

extension NetworkDownloader: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print(#function)
        print(location)
        do {
            let downloadFileURL = sharedGroupURL.appendingPathComponent("download.pkg")
            if FileManager.default.fileExists(atPath: downloadFileURL.path) {
                try FileManager.default.removeItem(at: downloadFileURL)
            }
            try FileManager.default.moveItem(at: location, to: downloadFileURL)
        } catch {
            fatalError("Error moving downloaded file: \(error)")
        }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {

        tryToWriteDownloadProgressToAppGroup(progress: downloadTask.progress.fractionCompleted)

        print(#function)
        print("written: \(totalBytesWritten), expected: \(totalBytesExpectedToWrite)")
    }

    private func tryToWriteDownloadProgressToAppGroup(progress: Double) {
        let progress = String(progress)
        let progressFileURL = sharedGroupURL.appendingPathComponent("downloadProgress.txt")

        do {
            try progress.write(to: progressFileURL, atomically: false, encoding: .utf8)
        } catch {
            fatalError("Couldn't write progress to app group: \(error)")
        }

    }
}
