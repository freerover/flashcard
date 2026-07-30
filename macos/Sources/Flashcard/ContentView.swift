import SwiftUI
import FlashcardShared

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showWordList = false
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                if let name = activeLibraryName {
                    Button {
                        showWordList = true
                    } label: {
                        Text(name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Text("\(viewModel.currentIndex + 1) / \(viewModel.wordCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if viewModel.hasWords, let word = viewModel.currentWord {
                wordCardView(word: word)
            } else {
                emptyStateView
            }
            Spacer()
        }
        .padding()
        .frame(width: 340, height: 420)
        .background(Color.white)
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
            .searchable(text: $searchText, prompt: "搜索单词")
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
        .background(Color.white)
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
            Button("打开设置") {
                openSettingsWindow()
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .padding(.top, 4)
        }
        .padding(.vertical, 40)
    }

    private var activeLibraryName: String? {
        viewModel.config?.libraries.first { $0.id == viewModel.activeLibraryId }?.title
    }
}
