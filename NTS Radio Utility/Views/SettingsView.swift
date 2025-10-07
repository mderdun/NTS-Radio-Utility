//
//  SettingsView.swift
//  NTS Radio Utility
//
//  Created by Miki on 07/10/2025.
//

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("autoPlayOnLaunch") private var autoPlayOnLaunch = false
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(.caption, weight: .semibold))
                Spacer()
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Launch at Login
            Toggle(isOn: Binding(
                get: { launchAtLogin },
                set: { newValue in
                    launchAtLogin = newValue
                    setLaunchAtLogin(enabled: newValue)
                }
            )) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Launch at Login")
                        .font(.system(.caption2))
                    Text("Start when you log in")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
            .controlSize(.mini)

            // Auto-play on Launch
            Toggle(isOn: $autoPlayOnLaunch) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Auto-play on Launch")
                        .font(.system(.caption2))
                    Text("Start playing automatically")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
            .controlSize(.mini)

            Divider()

            // About section
            VStack(alignment: .leading, spacing: 2) {
                Text("NTS Radio Utility v1.0")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(width: 220)
    }

    private func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                #if DEBUG
                print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
                #endif
            }
        }
    }
}

#Preview {
    SettingsView(isPresented: .constant(true))
}
