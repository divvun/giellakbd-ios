import Foundation

protocol UpdateBannerDelegate: class {
    func willBeginupdates(banner: UpdateBanner)
    func didFinishUpdates(banner: UpdateBanner)
}

final class UpdateBanner: Banner {
    weak var delegate: UpdateBannerDelegate?
    private let bannerView: UpdateBannerView
    private let downloadSimulator = DownloadSimulator()
    private var fileWatcher: SKQueue?
    private let networkDownloader = NetworkDownloader()

    var view: UIView {
        bannerView
    }

    private lazy var sharedGroupURL: URL = {
        let groupId = KeyboardSettings.groupId
        guard let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId) else {
            fatalError("Error opening app group for group id: \(groupId)")
        }
        return groupUrl
    }()

    private lazy var downloadFileURL: URL = {
        return sharedGroupURL.appendingPathComponent("simulatedDownload.txt")
    }()

    private lazy var progressFileURL: URL = {
        return sharedGroupURL.appendingPathComponent("downloadProgress.txt")
    }()

    init(theme: ThemeType) {
        bannerView = UpdateBannerView(theme: theme)
        checkForUpdates() // TODO: we may not want to check for updates on init
//        networkDownloader.downloadFile()
    }

    func updateTheme(_ theme: ThemeType) {
        bannerView.updateTheme(theme)
    }

    func updateProgressBar(_ newFileSize: UInt64) {
        bannerView.progress = Float(newFileSize) / Float(downloadSimulator.targetFileSizeInBytes)
    }

    private func checkForUpdates() {
//        downloadSimulator.simulateDownload(url: downloadFileURL)
        tryToSetupFileWatcher()
    }

    private func tryToSetupFileWatcher() {
        do {
            fileWatcher = try SKQueue(delegate: self)
//            fileWatcher?.addPath(sharedGroupURL.path) // kqueue requires adding the containing directory before adding the file of interest
//            fileWatcher?.addPath(progressFileURL.path)

            let downloadsURL = sharedGroupURL
                .appendingPathComponent("Library")
                .appendingPathComponent("Caches")
                .appendingPathComponent("com.apple.nsurlsessiond")
                .appendingPathComponent("Downloads")
                .appendingPathComponent("no.divvun.GiellaKeyboardTest") // TODO: if we use this method, make this dynamic
            fileWatcher?.addPath(downloadsURL.path)
        } catch {
            fatalError("Error creating SKQueue: \(error)")
        }
    }

    private func startUpdates() {
        delegate?.willBeginupdates(banner: self)
    }
}

extension UpdateBanner: SKQueueDelegate {
    func receivedNotification(_ notification: SKQueueNotification, path: String, queue: SKQueue) {
        print(notification)
        print(path)
        switch notification {
        case .sizeIncrease, .write:
//            let fileSize = tryToGetSizeOfFileAt(path: path)
            let progress = tryToGetProgressFromFile()
            DispatchQueue.main.async {
//                self.updateProgressBar(fileSize)
                self.bannerView.progress = progress
            }
        default:
            break
        }
    }

    private func tryToGetProgressFromFile() -> Float {
        do {
            let progress = try String(contentsOf: progressFileURL, encoding: .utf8) as NSString
            return progress.floatValue
        } catch {
            fatalError("Error reading data in progress file: \(error)")
        }
    }

    private func tryToGetSizeOfFileAt(path: String) -> UInt64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            guard let size = attributes[.size] as? NSNumber else {
                fatalError("Error getting file size. This shouldn't happen")
            }
            return size.uint64Value
        } catch {
            fatalError("ERROR getting file attributes: \(error)")
        }
    }
}
