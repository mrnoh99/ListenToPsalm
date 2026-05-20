import SwiftUI
import AppIntents

@main
struct ListenToPsalmApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    init() {
        // App Shortcuts 강제 업데이트
        Task { @MainActor in
            ListenToPsalmShortcuts.updateAppShortcutParameters()
        }
    }
}
