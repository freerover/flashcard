import SwiftUI
import AppKit
import FlashcardShared

struct SettingsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var searchText = ""
    @State private var selectedTab: SettingsTab = .library

    enum SettingsTab: String, CaseIterable, Identifiable {
        case library = "词库管理"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .library: return "book.closed"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 140, ideal: 160)
        } detail: {
            switch selectedTab {
            case .library:
                libraryContentView
            }
        }
        .frame(minWidth: 800, minHeight: 650)
    }

    @ViewBuilder
    private var libraryContentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("词库管理")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.top, 16)

            if let name = activeLibraryName {
                Text("当前启用：\(name)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }

            SearchField(text: $searchText)
                .padding(.horizontal)
                .padding(.vertical, 8)

            Divider()

            if let libraries = viewModel.config?.libraries, !libraries.isEmpty {
                let filtered = filterLibraries(libraries)
                if filtered.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                        Text("未找到匹配词库")
                            .font(.title3)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filtered) { library in
                            LibraryRow(library: library)
                                .environmentObject(viewModel)
                        }
                    }
                    .listStyle(.plain)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("没有词库")
                        .font(.title3)
                    Text("请检查配置文件")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var activeLibraryName: String? {
        viewModel.config?.libraries.first { $0.id == viewModel.activeLibraryId }?.title
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
        .padding(.vertical, 6)
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
                    VStack(spacing: 4) {
                        if state.isExtracting {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("解压中...")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            ProgressView(value: state.downloadProgress)
                                .frame(width: 30)
                            Text("\(Int(state.downloadProgress * 100))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
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

struct SearchField: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSSearchField {
        let field = NSSearchField()
        field.placeholderString = "搜索词库..."
        field.bezelStyle = .roundedBezel
        field.delegate = context.coordinator
        return field
    }

    func updateNSView(_ nsView: NSSearchField, context: Context) {
        nsView.stringValue = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    class Coordinator: NSObject, NSSearchFieldDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSSearchField else { return }
            text = field.stringValue
        }
    }
}
