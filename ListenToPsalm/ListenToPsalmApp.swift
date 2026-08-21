import SwiftUI
import AppIntents

@main
struct ListenToPsalmApp: App {
    @State private var annotations = AnnotationStore()
    @State private var appSettings = AppSettings.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(annotations)
                .environment(appSettings)
                .task {
                    checkAutoBackup()
                }
        }
    }

    init() {
        // App Shortcuts 강제 업데이트
        Task { @MainActor in
            ListenToPsalmShortcuts.updateAppShortcutParameters()
        }
    }

    private func checkAutoBackup() {
        let backupManager = BackupManager.shared
        if backupManager.shouldBackup() {
            _ = backupManager.backup(annotationStore: annotations)
        }
    }
}
