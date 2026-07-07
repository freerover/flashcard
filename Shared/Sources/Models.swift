import Foundation

public struct Config: Codable {
    public var activeLibrary: String
    public var libraries: [Library]
}

public struct Library: Codable, Identifiable {
    public let id: String
    public let index: Int
    public let imageURL: String
    public let title: String
    public let wordCount: Int
    public let fileSize: Int
    public let recitationCount: Int?
    public let downloadURLs: DownloadURLs
    public let tags: [String]

    enum CodingKeys: String, CodingKey {
        case id, index, title, tags
        case imageURL = "image_url"
        case wordCount = "word_count"
        case fileSize = "file_size"
        case recitationCount = "recitation_count"
        case downloadURLs = "download_urls"
    }
}

public struct DownloadURLs: Codable {
    public let downloadLocal: String
    public let downloadOriginal: String

    enum CodingKeys: String, CodingKey {
        case downloadLocal = "download_local"
        case downloadOriginal = "download_original"
    }
}

public struct Sentence: Identifiable {
    public let id = UUID()
    public let english: String
    public let chinese: String

    public init(english: String, chinese: String) {
        self.english = english
        self.chinese = chinese
    }
}

public struct Word: Identifiable {
    public let id = UUID()
    public let word: String
    public let ukphone: String?
    public let usphone: String?
    public let translation: String?
    public let sentences: [Sentence]

    public init?(from dict: [String: Any]) {
        guard let word = (dict["word"] as? String)
            ?? (dict["headWord"] as? String)
            ?? (dict["key"] as? String)
            ?? (dict["name"] as? String)
        else { return nil }
        self.word = word
        self.ukphone = dict["ukphone"] as? String
        self.usphone = dict["usphone"] as? String

        if let trans = dict["translation"] as? String {
            self.translation = trans
        } else if let trans = dict["trans"] as? String {
            self.translation = trans
        } else if let trans = dict["meaning"] as? String {
            self.translation = trans
        } else if let trans = dict["definition"] as? String {
            self.translation = trans
        } else if let trans = dict["explain"] as? String {
            self.translation = trans
        } else if let transArray = dict["translation"] as? [String] {
            self.translation = transArray.joined(separator: "; ")
        } else {
            self.translation = nil
        }
        self.sentences = []
    }

    public init?(fromYoudao dict: [String: Any]) {
        guard let word = dict["headWord"] as? String else { return nil }
        self.word = word

        let content = dict["content"] as? [String: Any]
        let wordContent = content?["word"] as? [String: Any]
        let innerContent = wordContent?["content"] as? [String: Any]

        self.ukphone = innerContent?["ukphone"] as? String
        self.usphone = innerContent?["usphone"] as? String

        if let transArray = innerContent?["translation"] as? [String] {
            self.translation = transArray.joined(separator: "; ")
        } else if let trans = innerContent?["translation"] as? String {
            self.translation = trans
        } else if let transList = innerContent?["trans"] as? [[String: Any]] {
            let parts = transList.compactMap { item -> String? in
                guard let cn = item["tranCn"] as? String else { return nil }
                if let pos = item["pos"] as? String {
                    return "\(pos). \(cn)"
                }
                return cn
            }
            self.translation = parts.isEmpty ? nil : parts.joined(separator: "；")
        } else {
            self.translation = nil
        }

        if let sentenceDict = innerContent?["sentence"] as? [String: Any],
           let list = sentenceDict["sentences"] as? [[String: Any]] {
            self.sentences = list.compactMap { item in
                guard let en = item["sContent"] as? String,
                      let cn = item["sCn"] as? String
                else { return nil }
                return Sentence(english: en, chinese: cn)
            }
        } else {
            self.sentences = []
        }
    }

    public static func parseWords(from data: Data) -> [Word] {
        guard let text = String(data: data, encoding: .utf8) else { return [] }

        let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
        if lines.count > 1 {
            let words = lines.compactMap { line -> Word? in
                guard let lineData = line.data(using: .utf8),
                      let obj = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any]
                else { return nil }
                return Word(fromYoudao: obj) ?? Word(from: obj)
            }
            if !words.isEmpty { return words }
        }

        guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) else {
            return []
        }
        if let array = json as? [[String: Any]] {
            return array.compactMap { Word(fromYoudao: $0) ?? Word(from: $0) }
        }
        if let dict = json as? [String: Any] {
            for key in ["words", "data", "list", "wordList", "items", "entries"] {
                if let words = dict[key] as? [[String: Any]] {
                    return words.compactMap { Word(fromYoudao: $0) ?? Word(from: $0) }
                }
            }
        }
        return []
    }
}
