import SwiftUI
import FlashcardShared

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 16) {
            if let name = activeLibraryName {
                Text(name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if viewModel.hasWords, let word = viewModel.currentWord {
                wordCardView(word: word)
            } else {
                emptyStateView
            }
            Spacer()
            if viewModel.hasWords {
                navigationView
            }
        }
        .padding()
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

    private var navigationView: some View {
        HStack(spacing: 16) {
            Button(action: viewModel.previousWord) {
                Label("Previous", systemImage: "chevron.left")
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)

            Text("\(viewModel.currentIndex + 1) / \(viewModel.wordCount)")
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: viewModel.nextWord) {
                Label("Next", systemImage: "chevron.right")
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
    }

    private var activeLibraryName: String? {
        viewModel.config?.libraries.first { $0.id == viewModel.activeLibraryId }?.title
    }
}
