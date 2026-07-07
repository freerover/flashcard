import SwiftUI
import FlashcardShared

@main
struct FlashcardApp: App {
    @StateObject private var viewModel = AppViewModel.shared

    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("单词", systemImage: "text.book.closed")
                    }

                SettingsView()
                    .tabItem {
                        Label("设置", systemImage: "gearshape")
                    }
            }
            .environmentObject(viewModel)
        }
    }
}
