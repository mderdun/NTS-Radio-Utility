//
//  RadioViewModel.swift
//  NTS Radio Utility
//
//  Created by Miki on 07/10/2025.
//

import Foundation
import Combine

@MainActor
class RadioViewModel: ObservableObject {
    @Published var nts1: Channel?
    @Published var nts2: Channel?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var menuBarText = "NTS"

    let audioPlayer = AudioPlayerService.shared
    private let apiService = NTSAPIService.shared
    private var showEndTimer: Timer?
    private var fallbackTimer: Timer?
    private var marqueeTimer: Timer?
    private let marqueeOffsetLock = NSLock()
    private nonisolated(unsafe) var _marqueeOffset = 0
    private var fullMenuBarText = ""
    private var cancellables = Set<AnyCancellable>()

    nonisolated private var marqueeOffset: Int {
        get {
            marqueeOffsetLock.lock()
            defer { marqueeOffsetLock.unlock() }
            return _marqueeOffset
        }
        set {
            marqueeOffsetLock.lock()
            _marqueeOffset = newValue
            marqueeOffsetLock.unlock()
        }
    }

    var currentChannel: Channel? {
        audioPlayer.currentStation == 1 ? nts1 : nts2
    }

    var isPlaying: Bool {
        audioPlayer.isPlaying
    }

    var volume: Float {
        audioPlayer.volume
    }

    var currentStation: Int {
        audioPlayer.currentStation
    }

    init() {
        setupBindings()
        Task {
            await fetchLiveData()
        }
        startFallbackRefresh()
    }

    private func setupBindings() {
        // Subscribe to audio player changes
        audioPlayer.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func fetchLiveData() async {
        isLoading = true
        errorMessage = nil

        do {
            let liveResponse = try await apiService.fetchLiveData()
            nts1 = liveResponse.nts1
            nts2 = liveResponse.nts2

            // Schedule next refresh at show end time
            scheduleShowEndRefresh()

            // Update menu bar text
            updateMenuBarText()
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ Failed to fetch live data: \(error)")
            #endif
        }

        isLoading = false
    }

    func forceRefresh() {
        Task {
            await fetchLiveData()
        }
    }

    private func scheduleShowEndRefresh() {
        // Cancel existing timer
        showEndTimer?.invalidate()

        let now = Date()
        var nextRefresh: Date?

        // Check NTS1 end time
        if let end1 = nts1?.now.endDate, end1 > now {
            nextRefresh = end1
        }

        // Check NTS2 end time
        if let end2 = nts2?.now.endDate, end2 > now {
            if let current = nextRefresh {
                // Use earliest end time
                nextRefresh = min(current, end2)
            } else {
                nextRefresh = end2
            }
        }

        // Schedule refresh 5 seconds after show ends
        if let refresh = nextRefresh {
            let delay = refresh.addingTimeInterval(5).timeIntervalSince(now)
            if delay > 0 {
                showEndTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                    Task { @MainActor [weak self] in
                        await self?.fetchLiveData()
                    }
                }
            }
        }
    }

    private func startFallbackRefresh() {
        // Fallback refresh every 5 minutes in case show end detection fails
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchLiveData()
            }
        }
    }

    func togglePlayPause() {
        audioPlayer.togglePlayPause()
        updateMenuBarText()
    }

    func switchStation(to station: Int) {
        audioPlayer.switchStation(to: station)
        updateMenuBarText()
    }

    func setVolume(_ volume: Float) {
        audioPlayer.setVolume(volume)
    }

    private func updateMenuBarText() {
        let stationNum = currentStation
        let prefix = isPlaying ? "● " : ""
        let station = "NTS\(stationNum)"

        guard let currentShow = currentChannel?.now else {
            fullMenuBarText = "\(prefix)\(station)"
            menuBarText = fullMenuBarText
            marqueeTimer?.invalidate()
            return
        }

        let title = currentShow.title
        fullMenuBarText = "\(prefix)\(station): \(title)"

        // If text is short enough, just display it
        if fullMenuBarText.count <= 30 {
            menuBarText = fullMenuBarText
            marqueeTimer?.invalidate()
        } else {
            // Start marquee for long titles
            startMenuBarMarquee()
        }
    }

    private func startMenuBarMarquee() {
        marqueeTimer?.invalidate()
        marqueeOffset = 0

        // Add spacing for seamless loop (separator added visually in MarqueeText)
        let loopText = fullMenuBarText + "       "

        marqueeTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            let maxLength = 30
            let localOffset = self.marqueeOffset
            let textCount = loopText.count

            // Compute display text
            let startIndex = loopText.index(loopText.startIndex, offsetBy: localOffset % textCount)
            var displayText = ""

            for i in 0..<min(maxLength, textCount) {
                let endIndex = loopText.index(before: loopText.endIndex)
                let idx = loopText.index(startIndex, offsetBy: i, limitedBy: endIndex)
                if let idx = idx {
                    displayText.append(loopText[idx])
                } else {
                    // Wrap around
                    let wrapBase = (textCount - (localOffset % textCount))
                    let wrapIdx = loopText.index(loopText.startIndex, offsetBy: i - wrapBase)
                    displayText.append(loopText[wrapIdx])
                }
            }

            let newOffset = localOffset + 1

            // Update UI-related state on the main actor
            Task { @MainActor [weak self, displayText, newOffset] in
                guard let self = self else { return }
                self.menuBarText = displayText
                self.marqueeOffset = newOffset
            }
        }
    }

    deinit {
        showEndTimer?.invalidate()
        fallbackTimer?.invalidate()
        marqueeTimer?.invalidate()
    }
}

