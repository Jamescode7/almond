import Foundation

final class FileWatcher {
    enum Event {
        case modified
        case deleted
        case renamed
    }

    private let url: URL
    private let onEvent: (Event) -> Void
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var isAccessingSecurityScope = false

    init(url: URL, onEvent: @escaping (Event) -> Void) {
        self.url = url
        self.onEvent = onEvent
    }

    func start() {
        stop()
        isAccessingSecurityScope = url.startAccessingSecurityScopedResource()

        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            if isAccessingSecurityScope {
                url.stopAccessingSecurityScopedResource()
                isAccessingSecurityScope = false
            }
            return
        }

        let queue = DispatchQueue.global(qos: .utility)
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename, .extend],
            queue: queue
        )

        let handler = onEvent
        source.setEventHandler { [weak source] in
            guard let source = source else { return }
            let flags = source.data
            DispatchQueue.main.async {
                if flags.contains(.delete) {
                    handler(.deleted)
                } else if flags.contains(.rename) {
                    handler(.renamed)
                } else {
                    handler(.modified)
                }
            }
        }

        source.setCancelHandler { [weak self] in
            guard let self = self else { return }
            if self.fileDescriptor >= 0 {
                close(self.fileDescriptor)
                self.fileDescriptor = -1
            }
        }

        self.source = source
        source.resume()
    }

    func stop() {
        source?.cancel()
        source = nil
        if isAccessingSecurityScope {
            url.stopAccessingSecurityScopedResource()
            isAccessingSecurityScope = false
        }
    }

    deinit {
        stop()
    }
}
