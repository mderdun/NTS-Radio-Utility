
//
//  AudioPlayerService.swift
//  NTS Radio Utility
//
//  Created by Miki on 07/10/2025.
//

import Foundation
import AVFoundation
import Combine

@MainActor
class AudioPlayerService: NSObject, ObservableObject {
    static let shared = AudioPlayerService()

    override private init() {
        super.init()
        if let storedVolume = UserDefaults.standard.object(forKey: "savedVolume") as? NSNumber {
            volume = storedVolume.floatValue
        } else {
            volume = 0.5
        }

        if let storedStation = UserDefaults.standard.object(forKey: "savedStation") as? NSNumber {
            let value = storedStation.intValue
            currentStation = value == 0 ? 1 : value
        } else {
            currentStation = 1
        }
        setupAudioSession()
    }

    @Published var isPlaying = false
    @Published var volume: Float = 0.5 {
        didSet {
            UserDefaults.standard.set(volume, forKey: "savedVolume")
        }
    }
    @Published var currentStation: Int = 1 {
        didSet {
            UserDefaults.standard.set(currentStation, forKey: "savedStation")
        }
    }
    @Published var playerState: PlayerState = .stopped

    @Published var nowPlayingTitle: String?
    @Published var nowPlayingArtist: String?

    var statusText: String {
        switch playerState {
        case .stopped: return "Stopped"
        case .buffering: return "Buffering…"
        case .playing: return "Playing"
        case .paused: return "Paused"
        case .error(let message): return "Error: \(message)"
        }
    }

    private var player: AVPlayer?
    private var playerStatusObserver: AnyCancellable?
    private var timeControlStatusObserver: NSKeyValueObservation?
    private var metadataObserver: AnyCancellable?

    private let httpHeaders: [String: String] = [
        "User-Agent": "NTSRadioUtility/1.0"
    ]

    enum PlayerState: Equatable {
        case stopped
        case buffering
        case playing
        case paused
        case error(String)
    }

    private func setupAudioSession() {
        #if os(iOS) || os(tvOS) || os(watchOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            #if DEBUG
            print("Failed to set up audio session: \(error)")
            #endif
        }
        #else
        #endif
    }

    func play(station: Int) {
        currentStation = station
        let streamURL = URL(string: "https://streams.radiomast.io/nts\(station)")!

        if player == nil {
            let asset = AVURLAsset(url: streamURL, options: ["AVURLAssetHTTPHeaderFieldsKey": httpHeaders])
            let playerItem = AVPlayerItem(asset: asset)
            observeMetadata(for: playerItem)
            player = AVPlayer(playerItem: playerItem)
            applyVolume()

            timeControlStatusObserver = player?.observe(\.timeControlStatus, options: [.initial, .new], changeHandler: { [weak self] player, _ in
                DispatchQueue.main.async {
                    switch player.timeControlStatus {
                    case .waitingToPlayAtSpecifiedRate:
                        self?.playerState = .buffering
                    case .playing:
                        self?.playerState = .playing
                    case .paused:
                        if self?.isPlaying == false {
                            self?.playerState = .paused
                        }
                    @unknown default:
                        break
                    }
                }
            })

            playerStatusObserver = player?.currentItem?.publisher(for: \.status)
                .sink { [weak self] status in
                    DispatchQueue.main.async {
                        switch status {
                        case .readyToPlay:
                            self?.playerState = .playing
                        case .failed:
                            let err = self?.player?.currentItem?.error
                            self?.playerState = .error(err?.localizedDescription ?? "Failed to load stream")
                        case .unknown:
                            self?.playerState = .buffering
                        @unknown default:
                            break
                        }
                    }
                }

            #if DEBUG
            NotificationCenter.default.addObserver(forName: .AVPlayerItemNewAccessLogEntry, object: player?.currentItem, queue: .main) { _ in
                if let log = self.player?.currentItem?.accessLog(), let last = log.events.last {
                    print("AccessLog: \(last)")
                }
            }
            #endif
        } else {
            let asset = AVURLAsset(url: streamURL, options: ["AVURLAssetHTTPHeaderFieldsKey": httpHeaders])
            let playerItem = AVPlayerItem(asset: asset)
            observeMetadata(for: playerItem)
            player?.replaceCurrentItem(with: playerItem)
        }

        player?.play()

        #if DEBUG
        if let currentItem = player?.currentItem, let asset = currentItem.asset as? AVURLAsset {
            Task {
                do {
                    let playable = try await asset.load(.isPlayable)
                    if !playable {
                        print("Asset not playable")
                    }
                } catch {
                    print("Failed to load asset playability: \(error)")
                }
            }
        }
        #endif

        isPlaying = true
        playerState = .buffering
    }

    func pause() {
        player?.pause()
        isPlaying = false
        playerState = .paused
    }

    func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        isPlaying = false
        nowPlayingTitle = nil
        nowPlayingArtist = nil
        metadataObserver = nil
        timeControlStatusObserver?.invalidate()
        timeControlStatusObserver = nil
        playerStatusObserver?.cancel()
        playerStatusObserver = nil
        playerState = .stopped
        player = nil
    }

    func switchStation(to station: Int) {
        guard station != currentStation else { return }

        let wasPlaying = isPlaying
        stop()
        nowPlayingTitle = nil
        nowPlayingArtist = nil

        if wasPlaying {
            play(station: station)
        } else {
            currentStation = station
        }
    }

    func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
        applyVolume()
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play(station: currentStation)
        }
    }

    private func observeMetadata(for item: AVPlayerItem) {
        let metadataOutput = AVPlayerItemMetadataOutput()
        metadataOutput.setDelegate(self, queue: DispatchQueue.main)
        item.add(metadataOutput)
    }

    private func applyVolume() {
        guard let player = player else { return }
        player.volume = volume
        player.isMuted = volume == 0
    }
}

extension AudioPlayerService: AVPlayerItemMetadataOutputPushDelegate {
    nonisolated func metadataOutput(_ output: AVPlayerItemMetadataOutput, didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup], from track: AVPlayerItemTrack?) {
        Task { @MainActor in
            var title: String?
            var artist: String?

            for group in groups {
                for meta in group.items {
                    let keyString = (meta.key as? String)?.lowercased()

                    if let key = keyString {
                        if key.contains("title") {
                            let value = try? await meta.load(.stringValue)
                            if let value = value {
                                if value.contains(" - ") {
                                    let parts = value.split(separator: "-", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespaces) }
                                    if parts.count == 2 {
                                        artist = parts[0]
                                        title = parts[1]
                                    } else {
                                        title = value
                                    }
                                } else {
                                    title = value
                                }
                            }
                        } else if key.contains("artist") {
                            let value = try? await meta.load(.stringValue)
                            artist = value
                        }
                    }

                    if let raw = meta.identifier?.rawValue as? String {
                        let id = raw.lowercased()
                        if id.contains("title"), title == nil {
                            title = try? await meta.load(.stringValue)
                        }
                        if id.contains("artist"), artist == nil {
                            artist = try? await meta.load(.stringValue)
                        }
                    }
                }
            }

            if title != nil || artist != nil {
                self.nowPlayingTitle = title
                self.nowPlayingArtist = artist
            }
        }
    }
}
