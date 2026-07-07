import Foundation

@MainActor
public class AppViewModel: ObservableObject {
    public static let shared = AppViewModel()

    @Published public var config: Config?
    @Published public var words: [Word] = []
    @Published public var currentIndex = 0
    @Published public var libraryStates: [String: LibraryState] = [:]

    public struct LibraryState {
        public var isDownloaded: Bool
        public var isDownloading: Bool
        public var isExtracting: Bool
        public var downloadProgress: Double

        public init(isDownloaded: Bool, isDownloading: Bool, isExtracting: Bool, downloadProgress: Double) {
            self.isDownloaded = isDownloaded
            self.isDownloading = isDownloading
            self.isExtracting = isExtracting
            self.downloadProgress = downloadProgress
        }
    }

    private init() {
        ConfigService.shared.ensureConfigExists()
        loadConfig()
    }

    public func loadConfig() {
        config = ConfigService.shared.loadConfig()
        updateLibraryStates()
        loadActiveWords()
    }

    public func updateLibraryStates() {
        guard let config else { return }
        var states: [String: LibraryState] = [:]
        for lib in config.libraries {
            states[lib.id] = LibraryState(
                isDownloaded: LibraryService.shared.isDownloaded(lib.id),
                isDownloading: false,
                isExtracting: false,
                downloadProgress: 0
            )
        }
        libraryStates = states
    }

    public func loadActiveWords() {
        guard let config else {
            words = []
            return
        }
        let activeId = config.activeLibrary
        guard !activeId.isEmpty, LibraryService.shared.isDownloaded(activeId) else {
            words = []
            return
        }
        words = LibraryService.shared.loadWords(for: activeId)
        currentIndex = 0
    }

    public var currentWord: Word? {
        guard !words.isEmpty, currentIndex >= 0, currentIndex < words.count else { return nil }
        return words[currentIndex]
    }

    public var hasWords: Bool { !words.isEmpty }
    public var wordCount: Int { words.count }
    public var activeLibraryId: String { config?.activeLibrary ?? "" }

    public func nextWord() {
        guard hasWords else { return }
        currentIndex = (currentIndex + 1) % words.count
    }

    public func previousWord() {
        guard hasWords else { return }
        currentIndex = (currentIndex - 1 + words.count) % words.count
    }

    public func downloadLibrary(_ library: Library) {
        guard var state = libraryStates[library.id] else { return }
        state.isDownloading = true
        state.isExtracting = false
        state.downloadProgress = 0
        libraryStates[library.id] = state

        LibraryService.shared.onProgress = { [weak self] progress in
            DispatchQueue.main.async {
                guard var s = self?.libraryStates[library.id] else { return }
                s.downloadProgress = progress
                self?.libraryStates[library.id] = s
            }
        }

        LibraryService.shared.onExtracting = { [weak self] in
            DispatchQueue.main.async {
                guard var s = self?.libraryStates[library.id] else { return }
                s.isExtracting = true
                self?.libraryStates[library.id] = s
            }
        }

        LibraryService.shared.download(library) { [weak self] result in
            DispatchQueue.main.async {
                guard var s = self?.libraryStates[library.id] else { return }
                switch result {
                case .success:
                    s.isDownloaded = true
                    s.isDownloading = false
                    s.isExtracting = false
                case .failure:
                    s.isDownloading = false
                    s.isExtracting = false
                }
                self?.libraryStates[library.id] = s
                if case .success = result {
                    self?.loadActiveWords()
                }
            }
        }
    }

    public func enableLibrary(_ id: String) {
        guard var config else { return }
        config.activeLibrary = id
        self.config = config
        ConfigService.shared.saveConfig(config)
        updateLibraryStates()
        loadActiveWords()
    }
}
