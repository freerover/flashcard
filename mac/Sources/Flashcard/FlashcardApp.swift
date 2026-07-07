import SwiftUI
import AppKit
import FlashcardShared

@main
struct FlashcardApp: App {
    @StateObject private var viewModel = AppViewModel.shared

    init() {
        DispatchQueue.main.async {
            toggleFloatingWindow()
        }
    }

    var body: some Scene {
        MenuBarExtra("Flashcard", systemImage: "text.book.closed") {
            Button("显示/隐藏 闪卡") {
                toggleFloatingWindow()
            }
            Divider()
            Button("设置...") {
                openSettingsWindow()
            }
            Divider()
            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
        }
        .menuBarExtraStyle(.menu)
    }
}

var floatingWindowController: NSWindowController?
var settingsWindowController: NSWindowController?

@MainActor
func toggleFloatingWindow() {
    if let wc = floatingWindowController, let window = wc.window, window.isVisible {
        window.orderOut(nil)
        return
    }

    let contentView = ContentView()
        .environmentObject(AppViewModel.shared)

    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 340, height: 420),
        styleMask: [.titled, .closable, .fullSizeContentView],
        backing: .buffered,
        defer: false
    )
    window.contentViewController = NSHostingController(rootView: contentView)
    window.level = .floating
    window.isMovableByWindowBackground = true
    window.titlebarAppearsTransparent = true
    if let screen = NSScreen.main?.visibleFrame {
        let x = screen.maxX - 340
        let y = screen.maxY - 420
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    let wc = NSWindowController(window: window)
    floatingWindowController = wc
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
}

@MainActor
func openSettingsWindow() {
    if let wc = settingsWindowController, let window = wc.window {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        }
        return
    }

    let settingsView = SettingsView()
        .environmentObject(AppViewModel.shared)

    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 800, height: 650),
        styleMask: [.titled, .closable, .miniaturizable, .resizable],
        backing: .buffered,
        defer: false
    )
    window.title = "设置"
    window.contentViewController = NSHostingController(rootView: settingsView)
    window.center()

    let wc = NSWindowController(window: window)
    settingsWindowController = wc
    DispatchQueue.main.async {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }
}
