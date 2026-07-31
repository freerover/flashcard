import Foundation
import zlib

public class LibraryService: NSObject {
    public static let shared = LibraryService()

    public var onProgress: ((Double) -> Void)?
    public var onExtracting: (() -> Void)?

    private var completionHandler: ((Result<Void, Error>) -> Void)?
    private var currentLibraryId: String?
    private var downloadSession: URLSession?

    private let libsDir: URL

    private override init() {
        let base: URL
        #if os(iOS)
        base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        #else
        base = FileManager.default.homeDirectoryForCurrentUser
        #endif
        libsDir = base.appendingPathComponent(".flashcard/libs")
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
        let data = try Data(contentsOf: source)
        try Self.unzip(data: data, to: destination)
    }

    private static func unzip(data: Data, to destination: URL) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: destination, withIntermediateDirectories: true)

        let eocd = try findEOCD(in: data)
        let entryCount = Int(data.u16(at: eocd + 10))
        let cdOffset = Int(data.u32(at: eocd + 16))

        var offset = cdOffset
        for _ in 0..<entryCount {
            guard offset + 46 <= data.count, data.u32(at: offset) == 0x02014b50 else { break }
            let method = Int(data.u16(at: offset + 10))
            let compSize = Int(data.u32(at: offset + 20))
            let nameLen = Int(data.u16(at: offset + 28))
            let extraLen = Int(data.u16(at: offset + 30))
            let commentLen = Int(data.u16(at: offset + 32))
            let localOffset = Int(data.u32(at: offset + 42))
            let nameBytes = data.subdata(in: offset + 46 ..< offset + 46 + nameLen)
            let name = String(data: nameBytes, encoding: .utf8)
                ?? String(data: nameBytes, encoding: .isoLatin1)
                ?? ""
            offset += 46 + nameLen + extraLen + commentLen

            let isDirectory = name.hasSuffix("/")
            let entryName = isDirectory ? String(name.dropLast()) : name
            guard !entryName.isEmpty, !entryName.contains(".."), !name.contains("__MACOSX") else { continue }

            if isDirectory {
                try fm.createDirectory(at: destination.appendingPathComponent(entryName), withIntermediateDirectories: true)
                continue
            }

            guard localOffset + 30 <= data.count, data.u32(at: localOffset) == 0x04034b50 else { continue }
            let localNameLen = Int(data.u16(at: localOffset + 26))
            let localExtraLen = Int(data.u16(at: localOffset + 28))
            let dataStart = localOffset + 30 + localNameLen + localExtraLen
            guard dataStart + compSize <= data.count else { continue }

            let compressed = data.subdata(in: dataStart ..< dataStart + compSize)
            let fileData: Data
            switch method {
            case 0:
                fileData = compressed
            case 8:
                guard let inflated = inflateRaw(compressed) else {
                    throw NSError(domain: "Flashcard", code: -4, userInfo: [NSLocalizedDescriptionKey: "解压失败: \(entryName)"])
                }
                fileData = inflated
            default:
                continue
            }

            let destURL = destination.appendingPathComponent(entryName)
            try fm.createDirectory(at: destURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try fileData.write(to: destURL, options: .atomic)
        }
    }

    private static func findEOCD(in data: Data) throws -> Int {
        let minimum = 22
        guard data.count >= minimum else {
            throw NSError(domain: "Flashcard", code: -3, userInfo: [NSLocalizedDescriptionKey: "无效的 zip 文件"])
        }
        let maxComment = 65535
        let start = max(0, data.count - minimum - maxComment)
        var index = data.count - minimum
        while index >= start {
            if data.u32(at: index) == 0x06054b50 {
                return index
            }
            index -= 1
        }
        throw NSError(domain: "Flashcard", code: -3, userInfo: [NSLocalizedDescriptionKey: "无效的 zip 文件"])
    }

    private static func inflateRaw(_ data: Data) -> Data? {
        guard !data.isEmpty else { return nil }
        var stream = z_stream()
        let ret = data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) -> Int32 in
            let ptr = raw.bindMemory(to: UInt8.self).baseAddress
            stream.next_in = UnsafeMutablePointer<UInt8>(mutating: ptr)
            stream.avail_in = UInt32(data.count)
            return inflateInit2_(&stream, -MAX_WBITS, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        }
        guard ret == Z_OK else { return nil }

        var out = Data()
        let bufferSize = 65536
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        while stream.avail_in > 0 {
            buffer.withUnsafeMutableBytes { (raw: UnsafeMutableRawBufferPointer) in
                let ptr = raw.bindMemory(to: UInt8.self).baseAddress
                stream.next_out = ptr
                stream.avail_out = UInt32(bufferSize)
            }
            let result = inflate(&stream, Z_NO_FLUSH)
            let written = bufferSize - Int(stream.avail_out)
            if written > 0 {
                out.append(buffer, count: written)
            }
            if result == Z_STREAM_END { break }
            guard result == Z_OK else {
                inflateEnd(&stream)
                return nil
            }
        }
        inflateEnd(&stream)
        return out
    }
}

private extension Data {
    func u16(at offset: Int) -> UInt16 {
        UInt16(self[offset]) | (UInt16(self[offset + 1]) << 8)
    }

    func u32(at offset: Int) -> UInt32 {
        UInt32(self[offset])
            | (UInt32(self[offset + 1]) << 8)
            | (UInt32(self[offset + 2]) << 16)
            | (UInt32(self[offset + 3]) << 24)
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
