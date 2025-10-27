//
//  MarqueeText.swift
//  NTS Radio Utility
//
//  Created by Miki on 07/10/2025.
//

import SwiftUI

private struct MarqueeContentWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct MarqueeText: View {
    let text: String
    let font: Font
    let color: Color
    var speed: CGFloat = 36
    var gap: CGFloat = 32
    var initialDelay: TimeInterval = 1.2

    @State private var containerWidth: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @State private var animationStartDate = Date()

    private var needsScrolling: Bool {
        contentWidth > containerWidth && containerWidth > 0
    }

    private var travelDistance: CGFloat {
        contentWidth + gap
    }

    private var animationDuration: TimeInterval {
        guard needsScrolling, travelDistance > 0 else { return 0 }
        return TimeInterval(travelDistance / speed)
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width

            ZStack(alignment: .leading) {
                if needsScrolling, animationDuration > 0 {
                    TimelineView(.animation) { timeline in
                        let now = timeline.date
                        let elapsed = max(0, now.timeIntervalSince(animationStartDate))
                        let distance = travelDistance
                        let duration = animationDuration

                        let progress = distance > 0 && duration > 0
                            ? (elapsed.truncatingRemainder(dividingBy: duration) / duration)
                            : 0
                        let offset = -distance * progress

                        HStack(spacing: gap) {
                            Text(text)
                                .font(font)
                                .foregroundColor(color)
                                .lineLimit(1)
                                .fixedSize()
                            Text(text)
                                .font(font)
                                .foregroundColor(color)
                                .lineLimit(1)
                                .fixedSize()
                        }
                        .frame(width: width, alignment: .leading)
                        .offset(x: offset)
                    }
                } else {
                    Text(text)
                        .font(font)
                        .foregroundColor(color)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .onAppear {
                containerWidth = width
            }
            .onChange(of: width, initial: false) { _, newWidth in
                containerWidth = newWidth
            }
        }
        .clipped()
        .background(measurementView)
        .onPreferenceChange(MarqueeContentWidthKey.self) { newWidth in
            if abs(contentWidth - newWidth) > 0.5 {
                contentWidth = newWidth
                resetAnimation()
            }
        }
        .onChange(of: text, initial: false) { _, _ in
            resetAnimation()
        }
    }

    private var measurementView: some View {
        Text(text)
            .font(font)
            .lineLimit(1)
            .fixedSize()
            .foregroundColor(.clear)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: MarqueeContentWidthKey.self, value: proxy.size.width)
                }
            )
    }

    private func resetAnimation() {
        animationStartDate = Date().addingTimeInterval(initialDelay)
    }
}
