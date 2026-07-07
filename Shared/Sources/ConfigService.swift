import Foundation

public class ConfigService {
    public static let shared = ConfigService()

    public let configDir: URL
    public let configFile: URL
    public let libsDir: URL

    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        configDir = home.appendingPathComponent(".flashcard")
        configFile = configDir.appendingPathComponent("config.json")
        libsDir = configDir.appendingPathComponent("libs")
    }

    public func ensureConfigExists() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: configDir.path) {
            try? fm.createDirectory(at: configDir, withIntermediateDirectories: true)
        }
        if !fm.fileExists(atPath: libsDir.path) {
            try? fm.createDirectory(at: libsDir, withIntermediateDirectories: true)
        }
        if !fm.fileExists(atPath: configFile.path) {
            if let bundled = Bundle.main.resourceURL?.appendingPathComponent("config.json"),
               fm.fileExists(atPath: bundled.path),
               let data = try? Data(contentsOf: bundled) {
                try? data.write(to: configFile, options: .atomic)
            } else {
                let defaultLib = Library(
                    id: "CET4luan_1",
                    index: 1,
                    imageURL: "https://nos.netease.com/ydschool-online/1496632727200CET4luan_1.jpg",
                    title: "四级真题核心词（image_url记忆）",
                    wordCount: 1162,
                    fileSize: 788457,
                    recitationCount: 875260,
                    downloadURLs: DownloadURLs(
                        downloadLocal: "~/.flashcard/libs/1523620217431_CET4luan_1.zip",
                        downloadOriginal: "http://ydschool-online.nos.netease.com/1523620217431_CET4luan_1.zip"
                    ),
                    tags: ["四级", "有道"]
                )
                let config = Config(activeLibrary: "CET4luan_1", libraries: [defaultLib])
                if let data = try? JSONEncoder.pretty.encode(config) {
                    try? data.write(to: configFile, options: .atomic)
                }
            }
        }
        copyBundledLibs()
    }

    private func copyBundledLibs() {
        guard let bundledLibs = Bundle.main.resourceURL?.appendingPathComponent("libs") else { return }
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(at: bundledLibs, includingPropertiesForKeys: nil) else { return }
        for source in items {
            let dest = libsDir.appendingPathComponent(source.lastPathComponent)
            if !fm.fileExists(atPath: dest.path) {
                try? fm.copyItem(at: source, to: dest)
            }
        }
    }

    public func loadConfig() -> Config? {
        guard let data = try? Data(contentsOf: configFile) else { return nil }
        guard let config = try? JSONDecoder().decode(Config.self, from: data) else { return nil }
        saveConfig(config)
        return config
    }

    public func saveConfig(_ config: Config) {
        guard let data = try? JSONEncoder.pretty.encode(config) else { return }
        try? data.write(to: configFile, options: .atomic)
    }
}

extension JSONEncoder {
    public static let pretty: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = .prettyPrinted
        return e
    }()
}
