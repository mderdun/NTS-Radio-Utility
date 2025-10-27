
//
//  PopoverView.swift
//  NTS Radio Utility
//
//  Created by Miki on 07/10/2025.
//

import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var viewModel: RadioViewModel
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // Error Message
            if let errorMessage = viewModel.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                    Text(errorMessage)
                        .font(.caption2)
                }
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.1))
            }

            // Dual Channel Cards
            if viewModel.nts1 != nil && viewModel.nts2 != nil {
                HStack(spacing: 12) {
                    // NTS 1 Card
                    ChannelCard(
                        channel: viewModel.nts1!,
                        isActive: viewModel.currentStation == 1,
                        isPlaying: viewModel.isPlaying && viewModel.currentStation == 1,
                        onTap: {
                            if viewModel.currentStation != 1 {
                                viewModel.switchStation(to: 1)
                            }
                        },
                        onPlayPause: {
                            viewModel.togglePlayPause()
                        }
                    )

                    // NTS 2 Card
                    ChannelCard(
                        channel: viewModel.nts2!,
                        isActive: viewModel.currentStation == 2,
                        isPlaying: viewModel.isPlaying && viewModel.currentStation == 2,
                        onTap: {
                            if viewModel.currentStation != 2 {
                                viewModel.switchStation(to: 2)
                            }
                        },
                        onPlayPause: {
                            viewModel.togglePlayPause()
                        }
                    )
                }
                .padding(12)

                // Bottom Controls Bar
                VStack(spacing: 8) {
                    Divider()

                    HStack {
                        // Volume Control with scroll support
                        HStack(spacing: 6) {
                            Image(systemName: "speaker.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)

                            Slider(
                                value: Binding(
                                    get: { viewModel.volumeLevel },
                                    set: { viewModel.setVolume(Float($0)) }
                                ),
                                in: 0...1
                            )
                            .controlSize(.mini)

                            Text("\(Int(viewModel.volumeLevel * 100))%")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 28)

                            Button(action: {
                                let new = max(0, viewModel.volumeLevel - 0.05)
                                viewModel.setVolume(Float(new))
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                let new = min(1, viewModel.volumeLevel + 0.05)
                                viewModel.setVolume(Float(new))
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: 160)

                        Spacer()

                        // Next Show with marquee
                        if let nextShow = viewModel.currentChannel?.next.first {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)

                                MarqueeText(
                                    text: nextShow.title,
                                    font: .caption2,
                                    color: .secondary
                                )
                                .frame(height: 12)
                                .frame(maxWidth: 120)

                                if let startDate = nextShow.startDate {
                                    Text(formatTime(startDate))
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
                }
            } else if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "antenna.radiowaves.left.and.right.slash")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No information")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
            }

            Divider()

            // Footer
            HStack(spacing: 12) {
                Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(",", modifiers: .command)
                .popover(isPresented: $showSettings, arrowEdge: .bottom) {
                    SettingsView(isPresented: $showSettings)
                }

                Spacer()

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("Quit")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(width: 380)
        .onAppear {
            viewModel.forceRefresh()
        }
        .onKeyPress { press in
            if press.characters == " " {
                viewModel.togglePlayPause()
                return .handled
            } else if press.characters == "1" {
                if viewModel.currentStation != 1 {
                    viewModel.switchStation(to: 1)
                    if !viewModel.isPlaying {
                        viewModel.togglePlayPause()
                    }
                }
                return .handled
            } else if press.characters == "2" {
                if viewModel.currentStation != 2 {
                    viewModel.switchStation(to: 2)
                    if !viewModel.isPlaying {
                        viewModel.togglePlayPause()
                    }
                }
                return .handled
            }
            return .ignored
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Channel Card Component
struct ChannelCard: View {
    let channel: Channel
    let isActive: Bool
    let isPlaying: Bool
    let onTap: () -> Void
    let onPlayPause: () -> Void
    @EnvironmentObject var viewModel: RadioViewModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Artwork with play button overlay
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: channel.now.coverArtURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            ZStack {
                                Color.gray.opacity(0.2)
                                VStack(spacing: 2) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red.opacity(0.5))
                                    Text("Failed")
                                        .font(.system(size: 8))
                                        .foregroundColor(.secondary)
                                }
                            }
                        case .empty:
                            ZStack {
                                Color.gray.opacity(0.2)
                                Image(systemName: "radio")
                                    .font(.system(size: 20))
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                        @unknown default:
                            ProgressView()
                        }
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                    // Play button overlay or buffering indicator (only on active channel)
                    if isActive {
                        if viewModel.isPlaying && viewModel.audioPlayer.playerState == .buffering {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 24, height: 24)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.5))
                                        .frame(width: 24, height: 24)
                                )
                                .offset(x: -4, y: -4)
                        } else {
                            Button(action: onPlayPause) {
                                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.5))
                                            .frame(width: 24, height: 24)
                                    )
                            }
                            .buttonStyle(.plain)
                            .offset(x: -4, y: -4)
                        }
                    }
                }

                // Show Info - Same structure for both to prevent layout shift
                VStack(alignment: .leading, spacing: 2) {
                    // Title - use marquee only for active
                    if isActive {
                        MarqueeText(
                            text: channel.now.title,
                            font: .system(.caption, weight: .semibold),
                            color: .primary
                        )
                        .frame(height: 24)
                    } else {
                        Text(channel.now.title)
                            .font(.system(.caption, weight: .medium))
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .foregroundColor(.primary.opacity(0.6))
                            .frame(height: 24, alignment: .top)
                    }

                    // Location - always reserve space for consistent layout
                    Text(channel.now.location ?? " ")
                        .font(.system(.caption2))
                        .foregroundColor(isActive ? .secondary : .secondary.opacity(0.6))
                        .lineLimit(1)
                        .frame(height: 12)

                    // Time - always show for consistent layout
                    if let startDate = channel.now.startDate,
                       let endDate = channel.now.endDate {
                        Text("\(formatTime(startDate))–\(formatTime(endDate))")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(isActive ? .secondary : .secondary.opacity(0.6))
                            .frame(height: 12)

                        ShowProgressBar(startDate: startDate, endDate: endDate, isActive: isActive)
                            .frame(height: 2)
                            .padding(.top, 2)
                    } else {
                        Text(" ")
                            .font(.system(.caption2, design: .monospaced))
                            .frame(height: 12)

                        Color.clear
                            .frame(height: 2)
                            .padding(.top, 2)
                    }
                }
                .padding(.top, 6)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Channel label
                Text("NTS \(channel.channelName)")
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundColor(isActive ? .accentColor : .secondary.opacity(0.5))
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isActive ? Color.accentColor.opacity(0.5) : Color.clear,
                        lineWidth: 2
                    )
            )
            .opacity(isActive ? 1 : 0.6)
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let url = channel.now.showURL {
                Button("Open Show Page on NTS") {
                    openURL(url)
                }
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    PopoverView()
        .environmentObject(RadioViewModel())
}

// MARK: - Timeline

private struct ShowProgressBar: View {
    let startDate: Date
    let endDate: Date
    let isActive: Bool

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 30)) { timeline in
            let progress = progress(at: timeline.date)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 2)

                    RoundedRectangle(cornerRadius: 1)
                        .fill(isActive ? Color.accentColor : Color.secondary.opacity(0.4))
                        .frame(width: geometry.size.width * progress, height: 2)
                }
            }
        }
    }

    private func progress(at date: Date) -> CGFloat {
        let total = endDate.timeIntervalSince(startDate)
        guard total > 0 else { return 0 }
        let elapsed = date.timeIntervalSince(startDate)
        let clamped = min(max(elapsed / total, 0), 1)
        return CGFloat(clamped)
    }
}
