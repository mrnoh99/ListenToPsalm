//
//  AppSettingsView.swift
//  ListenToPsalm
//
//  앱 설정 - 백업 및 기타 기능
//

import SwiftUI

struct AppSettingsView: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            BackupSettingsView()
                .navigationTitle("설정")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("완료") { dismiss() }
                    }
                }
        }
    }
}

#Preview {
    AppSettingsView()
        .environment(AppSettings.shared)
}
