import SwiftUI
import FlashcardShared

struct SettingsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                if let libraries = viewModel.config?.libraries, !libraries.isEmpty {
                    let filtered = filterLibraries(libraries)
                    if filtered.isEmpty {
                        if #available(macOS 14, *) {
                            ContentUnavailableView.search(text: searchText)
                        } else {
                            Text("没有匹配「\(searchText)」的词库")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        ForEach(filtered) { library in
                            LibraryRow(library: library)
                                .environmentObject(viewModel)
                        }
                    }
                } else {
                    if #available(macOS 14, *) {
                        ContentUnavailableView(
                            "没有词库",
                            systemImage: "tray",
                            description: Text("请检查配置文件")
                        )
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary)
                            Text("没有词库")
                                .font(.headline)
                            Text("请检查配置文件")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
            }
            .navigationTitle("词库管理")
            .searchable(text: $searchText, prompt: "搜索词库...")
        }
    }

    private func filterLibraries(_ libraries: [Library]) -> [Library] {
        if searchText.isEmpty { return libraries }
        return libraries.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
}

struct LibraryRow: View {
    @EnvironmentObject var viewModel: AppViewModel
    let library: Library

    var body: some View {
        HStack(spacing: 12) {
            indexView
            coverImageView
            infoView
            Spacer()
            actionButtons
        }
        .padding(.vertical, 4)
    }

    private var indexView: some View {
        Text("\(library.index)")
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(width: 24, alignment: .leading)
    }

    private var coverImageView: some View {
        AsyncImage(url: URL(string: library.imageURL)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .clipped()
            case .failure:
                Image(systemName: "book.closed")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(width: 56, height: 56)
            case .empty:
                ProgressView()
                    .frame(width: 56, height: 56)
            @unknown default:
                EmptyView()
            }
        }
        #if os(iOS)
        .background(Color(.systemGray6))
        #else
        .background(Color.gray.opacity(0.15))
        #endif
        .cornerRadius(8)
    }

    private var infoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(library.title)
                .font(.headline)
                .lineLimit(2)

            HStack(spacing: 12) {
                Label("\(library.wordCount) 词", systemImage: "text.word.count")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Label(formatFileSize(library.fileSize), systemImage: "doc")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 6) {
                ForEach(library.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundColor(.accentColor)
                        .cornerRadius(4)
                }
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if let state = viewModel.libraryStates[library.id] {
            VStack(alignment: .trailing, spacing: 6) {
                if state.isDownloading || state.isExtracting {
                    if state.isExtracting {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("解压中...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        ProgressView(value: state.downloadProgress)
                            .frame(width: 50)
                        Text("\(Int(state.downloadProgress * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else if !state.isDownloaded {
                    Button("下载") {
                        viewModel.downloadLibrary(library)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                } else {
                    Text("已下载")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                let isEnabled = viewModel.activeLibraryId == library.id
                Toggle(isOn: Binding(
                    get: { isEnabled },
                    set: { newValue in
                        if newValue { viewModel.enableLibrary(library.id) }
                    }
                )) {
                    EmptyView()
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .disabled(!state.isDownloaded)
            }
        }
    }

    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
