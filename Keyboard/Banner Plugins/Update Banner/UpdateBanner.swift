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

    private let testDownloadFileName = "simulatedDownload.txt"

    var view: UIView {
        bannerView
    }

    private lazy var downloadFileURL: URL = {
        let groupId = KeyboardSettings.groupId
        guard let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId) else {
            fatalError("Error opening app group for group id: \(groupId)")
        }
        return groupUrl.appendingPathComponent(testDownloadFileName)
    }()

    init(theme: ThemeType) {
        bannerView = UpdateBannerView(theme: theme)
        checkForUpdates() // TODO: we may not want to check for updates on init
    }

    func updateTheme(_ theme: ThemeType) {
        bannerView.updateTheme(theme)
    }

    func updateProgressBar(_ newFileSize: UInt64) {
        bannerView.progress = Float(newFileSize) / Float(downloadSimulator.targetFileSizeInBytes)
    }

    private func checkForUpdates() {
        downloadSimulator.simulateDownload(url: downloadFileURL)
        tryToSetupFileWatcher()
    }

    private func tryToSetupFileWatcher() {
        do {
            fileWatcher = try SKQueue(delegate: self)
            let dir = downloadFileURL.deletingLastPathComponent().path
            fileWatcher?.addPath(dir) // kqueue requires adding the containing directory before adding the file of interest
            fileWatcher?.addPath(downloadFileURL.path)
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
        switch notification {
        case .sizeIncrease, .write:
            let fileSize = tryToGetSizeOfFileAt(path: path)
            DispatchQueue.main.async {
                self.updateProgressBar(fileSize)
            }
        default:
            break
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
