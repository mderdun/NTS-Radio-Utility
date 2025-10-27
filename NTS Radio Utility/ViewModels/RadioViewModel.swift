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
    @Published var menuBarFullText = "NTS"
    @Published var volumeLevel: Double = 0.5

    let audioPlayer = AudioPlayerService.shared
    private let apiService = NTSAPIService.shared
    private var showEndTimer: Timer?
    private var fallbackTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    var currentChannel: Channel? {
        audioPlayer.currentStation == 1 ? nts1 : nts2
    }

    var isPlaying: Bool {
        audioPlayer.isPlaying
    }

    var volume: Float {
        Float(volumeLevel)
    }

    var currentStation: Int {
        audioPlayer.currentStation
    }

    init() {
        setupBindings()
        volumeLevel = Double(audioPlayer.volume)
        Task {
            await fetchLiveData()
        }
        startFallbackRefresh()
    }

    private func setupBindings() {
        audioPlayer.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        audioPlayer.$volume
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                guard let self else { return }
                let doubleValue = Double(newValue)
                if abs(self.volumeLevel - doubleValue) > 0.0001 {
                    self.volumeLevel = doubleValue
                }
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

            scheduleShowEndRefresh()
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
        showEndTimer?.invalidate()

        let now = Date()
        var nextDelay: TimeInterval?
        var staleDetected = false

        func evaluate(channel: Channel?) {
            guard let show = channel?.now else { return }
            guard let endDate = show.endDate else { return }

            if endDate > now {
                let desiredDelay = endDate.addingTimeInterval(5).timeIntervalSince(now)
                nextDelay = nextDelay.map { min($0, desiredDelay) } ?? desiredDelay
            } else {
                staleDetected = true
            }
        }

        evaluate(channel: nts1)
        evaluate(channel: nts2)

        showEndTimer?.invalidate()

        if staleDetected {
            if promoteStaleShowsIfPossible(referenceDate: now) {
                updateMenuBarText()
                scheduleShowEndRefresh()
                return
            }

            let retryDelay: TimeInterval = 15
            #if DEBUG
            print("[RadioViewModel] Stale show data detected, retrying in \(retryDelay)s")
            #endif
            let timer = Timer(timeInterval: retryDelay, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.fetchLiveData()
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            showEndTimer = timer
            return
        }

        guard let delay = nextDelay else { return }

        let clampedDelay = max(delay, 0.5)

        #if DEBUG
        print("[RadioViewModel] Next refresh in: \(clampedDelay)s (raw: \(delay)s)")
        #endif

        let timer = Timer(timeInterval: clampedDelay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchLiveData()
            }
        }

        RunLoop.main.add(timer, forMode: .common)
        showEndTimer = timer
    }

    private func promoteStaleShowsIfPossible(referenceDate: Date) -> Bool {
        var promoted = false

        if let channel = nts1,
           let end = channel.now.endDate,
           end <= referenceDate,
           let nextShow = channel.next.first {
            let remaining = Array(channel.next.dropFirst())
            nts1 = Channel(channelName: channel.channelName, now: nextShow, next: remaining)
            promoted = true
        }

        if let channel = nts2,
           let end = channel.now.endDate,
           end <= referenceDate,
           let nextShow = channel.next.first {
            let remaining = Array(channel.next.dropFirst())
            nts2 = Channel(channelName: channel.channelName, now: nextShow, next: remaining)
            promoted = true
        }

        return promoted
    }

    private func startFallbackRefresh() {
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
        let clamped = max(0, min(1, Double(volume)))
        if abs(volumeLevel - clamped) > 0.0001 {
            volumeLevel = clamped
        }
        audioPlayer.setVolume(Float(clamped))
    }

    private func updateMenuBarText() {
        let stationNum = currentStation
        let prefix = isPlaying ? "● " : ""
        let station = "NTS\(stationNum)"

        guard let currentShow = currentChannel?.now else {
            menuBarFullText = "\(prefix)\(station)"
            return
        }

        let title = currentShow.title
        menuBarFullText = "\(prefix)\(station): \(title)"
    }

    deinit {
        showEndTimer?.invalidate()
        fallbackTimer?.invalidate()
    }
}
