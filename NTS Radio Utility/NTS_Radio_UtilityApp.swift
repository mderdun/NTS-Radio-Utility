//
//  NTS_Radio_UtilityApp.swift
//  NTS Radio Utility
//
//  Created by Miki on 07/10/2025.
//

import SwiftUI
import Sparkle

@main
struct NTS_Radio_UtilityApp: App {
    @StateObject private var viewModel = RadioViewModel()
    @AppStorage("autoPlayOnLaunch") private var autoPlayOnLaunch = false
    private let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

    init() {
        // Auto-play on launch if enabled
        if UserDefaults.standard.bool(forKey: "autoPlayOnLaunch") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                AudioPlayerService.shared.play(station: AudioPlayerService.shared.currentStation)
            }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environmentObject(viewModel)
        } label: {
            MenuBarView()
                .environmentObject(viewModel)
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }

        Settings {
            UpdaterSettingsView(updater: updaterController.updater)
        }
    }
}
