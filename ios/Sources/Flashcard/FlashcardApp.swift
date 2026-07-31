import SwiftUI
import UIKit
import FlashcardShared

@main
struct FlashcardApp: App {
    @StateObject private var viewModel = AppViewModel.shared

    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold)
        ]
    }

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
