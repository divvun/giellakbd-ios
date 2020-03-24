/*!
 * The MIT License (MIT)
 *
 * Copyright (c) 2018 Daniel Pedersen
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

// Edited by Brendan Molloy (c) 2020

import Foundation

struct SystemError: Error {
    let code: Int32

    public static func fromErrno() -> SystemError {
        return SystemError(code: errno)
    }
}

public protocol SKQueueDelegate: class {
    func receivedNotification(_ notification: SKQueueNotification, path: String, queue: SKQueue)
}

public enum SKQueueNotification: OptionSet, RawRepresentable {
    public typealias RawValue = Int32

    case none
    case rename
    case write
    case delete
    case attributeChange
    case sizeIncrease
    case linkCountChange
    case accessRevocation
    case unlock
    case dataAvailable
    case `default`

    public init(rawValue: Self.RawValue) {
        switch rawValue {
        case 0: self = .none
        case NOTE_RENAME: self = .rename
        case NOTE_WRITE: self = .write
        case NOTE_DELETE: self = .delete
        case NOTE_ATTRIB: self = .attributeChange
        case NOTE_EXTEND: self = .sizeIncrease
        case NOTE_LINK: self = .linkCountChange
        case NOTE_REVOKE: self = .accessRevocation
        case NOTE_FUNLOCK: self = .unlock
        case NOTE_NONE: self = .dataAvailable
        default: self = .default
        }
    }

    public var rawValue: Int32 {
        switch self {
        case .none: return 0
        case .rename: return NOTE_RENAME
        case .write: return NOTE_WRITE
        case .delete: return NOTE_DELETE
        case .attributeChange: return NOTE_ATTRIB
        case .sizeIncrease: return NOTE_EXTEND
        case .linkCountChange: return NOTE_LINK
        case .accessRevocation: return NOTE_REVOKE
        case .unlock: return NOTE_FUNLOCK
        case .dataAvailable: return NOTE_NONE
        case .default: return Int32.max
        }
    }
}

public class SKQueue {
    private let kqueueId: Int32
    private var watchedPaths = [String: Int32]()
    private var keepWatcherThreadRunning = false
    public weak var delegate: SKQueueDelegate?

    public init(delegate: SKQueueDelegate? = nil) throws {
        kqueueId = kqueue()

        if kqueueId == -1 {
            throw SystemError.fromErrno()
        }

        self.delegate = delegate
    }

    deinit {
        keepWatcherThreadRunning = false
        removeAllPaths()
        close(kqueueId)
    }

    public func addPath(_ path: String, notifyingAbout notification: SKQueueNotification = .default) {
        var fileDescriptor: Int32! = watchedPaths[path]

        if fileDescriptor == nil {
            fileDescriptor = open(FileManager.default.fileSystemRepresentation(withPath: path), O_EVTONLY)

            guard fileDescriptor >= 0 else {
                return
            }

            watchedPaths[path] = fileDescriptor
        }

        var edit = kevent(
            ident: UInt(fileDescriptor),
            filter: Int16(EVFILT_VNODE),
            flags: UInt16(EV_ADD | EV_CLEAR),
            fflags: UInt32(notification.rawValue),
            data: 0,
            udata: nil
        )

        kevent(kqueueId, &edit, 1, nil, 0, nil)

        if !keepWatcherThreadRunning {
            keepWatcherThreadRunning = true
            DispatchQueue.global().async(execute: watcherThread)
        }
    }

    private func watcherThread() {
        var event = kevent()
        var timeout = timespec(tv_sec: 1, tv_nsec: 0)

        while keepWatcherThreadRunning {
            if kevent(kqueueId, nil, 0, &event, 1, &timeout) > 0 && event.filter == EVFILT_VNODE && event.fflags > 0 {
                guard let (path, _) = watchedPaths.first(where: { $1 == event.ident }) else {
                    continue
                }

                let notification = SKQueueNotification(rawValue: Int32(event.fflags))

                DispatchQueue.global().async {
                    self.delegate?.receivedNotification(notification, path: path, queue: self)
                }
            }
        }
    }

    public func isPathWatched(_ path: String) -> Bool {
        return watchedPaths[path] != nil
    }

    public func removePath(_ path: String) {
        if let fileDescriptor = watchedPaths.removeValue(forKey: path) {
            close(fileDescriptor)
        }
    }

    public func removeAllPaths() {
        watchedPaths.keys.forEach(removePath)
    }

    public func numberOfWatchedPaths() -> Int {
        return watchedPaths.count
    }

    public func fileDescriptor(forPath path: String) -> Int32? {
        if let fileDescriptor = watchedPaths[path] {
            return fcntl(fileDescriptor, F_DUPFD)
        }
        return nil
    }
}
