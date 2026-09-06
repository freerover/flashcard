import SwiftUI
import FlashcardShared

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showWordList = false
    @State private var searchText = ""
    @State private var autoPlayActive = true
    @State private var autoPlayTimer: Timer?
    @AppStorage("autoPlayEnabled") private var autoPlayEnabled = true

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.hasWords, let word = viewModel.currentWord {
                ScrollView {
                    VStack(spacing: 16) {
                        HStack {
                            if let name = activeLibraryName {
                                Text(name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button {
                                showWordList = true
                            } label: {
                                Text("\(viewModel.currentIndex + 1) / \(viewModel.wordCount)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity)
                        wordCardView(word: word)
                        prevNextRow(currentWord: word)
                        if autoPlayEnabled {
                            Button {
                                autoPlayActive.toggle()
                                if autoPlayActive { startAutoPlay() } else { stopAutoPlay() }
                            } label: {
                                Image(systemName: autoPlayActive ? "pause.fill" : "play.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(Circle().fill(Color.blue))
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            if value.translation.width < -50 {
                                viewModel.nextWord()
                            } else if value.translation.width > 50 {
                                viewModel.previousWord()
                            }
                        }
                )
                .onAppear { startAutoPlay() }
                .onDisappear { stopAutoPlay() }
                .onChange(of: viewModel.currentIndex) { _ in startAutoPlay() }
            } else {
                emptyStateView
                    .frame(maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showWordList) {
            wordListView
        }
    }

    private var wordListView: some View {
        NavigationStack {
            let filtered = searchText.isEmpty ? viewModel.words : viewModel.words.filter { $0.word.localizedCaseInsensitiveContains(searchText) }
            List(Array(filtered.enumerated()), id: \.element.id) { index, word in
                Button {
                    if let originalIndex = viewModel.words.firstIndex(where: { $0.id == word.id }) {
                        viewModel.currentIndex = originalIndex
                    }
                    showWordList = false
                } label: {
                    HStack(spacing: 8) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        Text(word.word)
                            .foregroundColor(.primary)
                        Spacer()
                        if let trans = word.translation {
                            Text(trans)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        if word.id == viewModel.currentWord?.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            .navigationTitle("")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索单词")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭") { showWordList = false }
                }
            }
        }
    }

    private func wordCardView(word: Word) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(word.word)
                .font(.largeTitle)
                .fontWeight(.bold)

            if word.ukphone != nil || word.usphone != nil {
                HStack(spacing: 16) {
                    if let uk = word.ukphone {
                        HStack(spacing: 4) {
                            Text("UK /\(uk)/")
                                .font(.body)
                                .foregroundColor(.secondary)
                            Button(action: { AudioService.shared.play(word: word.word, type: 1) }) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.callout)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if let us = word.usphone {
                        HStack(spacing: 4) {
                            Text("US /\(us)/")
                                .font(.body)
                                .foregroundColor(.secondary)
                            Button(action: { AudioService.shared.play(word: word.word, type: 2) }) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.callout)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if let translation = word.translation {
                Divider()
                Text(translation)
                    .font(.title3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !word.sentences.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(word.sentences.prefix(2)) { s in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.english)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(s.chinese)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        #if os(iOS)
        .background(Color(.systemBackground))
        #else
        .background(Color.white)
        #endif
        .cornerRadius(10)
        .padding(.vertical, 4)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("没有可用的单词")
                .font(.title3)
            Text("请在设置中下载并启用词库")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }

    private var activeLibraryName: String? {
        viewModel.config?.libraries.first { $0.id == viewModel.activeLibraryId }?.title
    }

    private func prevNextRow(currentWord: Word) -> some View {
        let prev = prevWord(before: currentWord)
        let next = nextWord(after: currentWord)
        return HStack {
            if let prev {
                Button {
                    viewModel.previousWord()
                } label: {
                    Label(prev.word, systemImage: "arrow.left")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            } else {
                Spacer()
            }
            Spacer()
            if let next {
                Button {
                    viewModel.nextWord()
                } label: {
                    Label(next.word, systemImage: "arrow.right")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            } else {
                Spacer()
            }
        }
    }

    private func previousWordIndex(for current: Word) -> Int? {
        guard let idx = viewModel.words.firstIndex(where: { $0.id == current.id }) else { return nil }
        return (idx - 1 + viewModel.words.count) % viewModel.words.count
    }

    private func nextWordIndex(for current: Word) -> Int? {
        guard let idx = viewModel.words.firstIndex(where: { $0.id == current.id }) else { return nil }
        return (idx + 1) % viewModel.words.count
    }

    private func prevWord(before current: Word) -> Word? {
        guard let idx = previousWordIndex(for: current) else { return nil }
        return viewModel.words[idx]
    }

    private func nextWord(after current: Word) -> Word? {
        guard let idx = nextWordIndex(for: current) else { return nil }
        return viewModel.words[idx]
    }

    private func startAutoPlay() {
        autoPlayTimer?.invalidate()
        guard autoPlayEnabled, autoPlayActive, let word = viewModel.currentWord else { return }
        AudioService.shared.play(word: word.word, type: 2)
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            Task { @MainActor in
                guard autoPlayEnabled, autoPlayActive, let w = viewModel.currentWord else { return }
                AudioService.shared.play(word: w.word, type: 2)
            }
        }
    }

    private func stopAutoPlay() {
        autoPlayTimer?.invalidate()
        autoPlayTimer = nil
    }
}
