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
                        if #available(iOS 17, macOS 14, *) {
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
                    if #available(iOS 17, macOS 14, *) {
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
            infoView
                .frame(maxWidth: .infinity, alignment: .leading)
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

    private var infoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(library.title)
                .font(.system(size: 14))
                .lineLimit(2)

            Text("\(library.wordCount) 词")
                .font(.caption)
                .foregroundColor(.secondary)
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
                    .controlSize(.mini)
                    .font(.caption2)
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
                .controlSize(.mini)
                .scaleEffect(0.8)
                .disabled(!state.isDownloaded)
            }
            .frame(maxWidth: 50)
        }
    }

    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
