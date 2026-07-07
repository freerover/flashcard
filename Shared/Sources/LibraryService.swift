import Foundation

public class LibraryService: NSObject {
    public static let shared = LibraryService()

    public var onProgress: ((Double) -> Void)?
    public var onExtracting: (() -> Void)?

    private var completionHandler: ((Result<Void, Error>) -> Void)?
    private var currentLibraryId: String?
    private var downloadSession: URLSession?

    private let libsDir: URL

    private override init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        libsDir = home.appendingPathComponent(".flashcard/libs")
        super.init()
    }

    public func isDownloaded(_ id: String) -> Bool {
        FileManager.default.fileExists(atPath: libsDir.appendingPathComponent(id).path)
    }

    public func download(_ library: Library, completion: @escaping (Result<Void, Error>) -> Void) {
        currentLibraryId = library.id
        completionHandler = completion

        guard let url = URL(string: library.downloadURLs.downloadOriginal) else {
            completion(.failure(NSError(domain: "Flashcard", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的下载地址"])))
            return
        }

        let config = URLSessionConfiguration.default
        downloadSession?.invalidateAndCancel()
        downloadSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        let task = downloadSession!.downloadTask(with: url)
        task.resume()
    }

    public func loadWords(for libraryId: String) -> [Word] {
        let libPath = libsDir.appendingPathComponent(libraryId)
        guard FileManager.default.fileExists(atPath: libPath.path) else { return [] }

        guard let enumerator = FileManager.default.enumerator(at: libPath, includingPropertiesForKeys: nil) else { return [] }

        var words: [Word] = []
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "json" else { continue }
            guard let data = try? Data(contentsOf: fileURL) else { continue }
            let parsed = Word.parseWords(from: data)
            words.append(contentsOf: parsed)
        }
        return words
    }

    private func extractZip(at source: URL, to destination: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", source.path, "-d", destination.path]
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            throw NSError(domain: "Flashcard", code: -2, userInfo: [NSLocalizedDescriptionKey: "解压失败"])
        }
    }
}

extension LibraryService: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = totalBytesExpectedToWrite > 0 ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0
        DispatchQueue.main.async {
            self.onProgress?(progress)
        }
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let libraryId = currentLibraryId else { return }

        let fm = FileManager.default
        let destDir = libsDir.appendingPathComponent(libraryId)

        DispatchQueue.main.async {
            self.onExtracting?()
        }

        do {
            if fm.fileExists(atPath: destDir.path) {
                try fm.removeItem(at: destDir)
            }
            try fm.createDirectory(at: destDir, withIntermediateDirectories: true)
            try extractZip(at: location, to: destDir)
        } catch {
            DispatchQueue.main.async {
                self.completionHandler?(.failure(error))
            }
            return
        }

        DispatchQueue.main.async {
            self.completionHandler?(.success(()))
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.completionHandler?(.failure(error))
            }
        }
        session.invalidateAndCancel()
    }
}
