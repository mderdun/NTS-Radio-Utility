//
//  MarqueeText.swift
//  NTS Radio Utility
//
//  Created by Miki on 07/10/2025.
//

import SwiftUI

struct MarqueeText: View {
    let text: String
    let font: Font
    let color: Color
    @State private var animate = false
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0

    var needsScrolling: Bool {
        textWidth > containerWidth && containerWidth > 0
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Text(text)
                    .font(font)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .fixedSize()

                if needsScrolling {
                    // Add visible gap separator
                    Spacer()
                        .frame(width: 12)

                    Circle()
                        .fill(color.opacity(0.4))
                        .frame(width: 3, height: 3)

                    Spacer()
                        .frame(width: 12)

                    Text(text)
                        .font(font)
                        .foregroundColor(color)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .background(
                GeometryReader { textGeometry in
                    Color.clear
                        .onAppear {
                            textWidth = textGeometry.size.width / (needsScrolling ? 2 : 1)
                            containerWidth = geometry.size.width
                        }
                        .onChange(of: text) {
                            animate = false
                            DispatchQueue.main.async {
                                textWidth = textGeometry.size.width / (needsScrolling ? 2 : 1)
                                containerWidth = geometry.size.width
                                animate = true
                            }
                        }
                }
            )
            .offset(x: needsScrolling && animate ? -(textWidth + 20) : 0)
            .onAppear {
                if needsScrolling {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        animate = true
                    }
                }
            }
            .animation(
                needsScrolling ? .linear(duration: Double(textWidth) / 20).repeatForever(autoreverses: false) : nil,
                value: animate
            )
        }
        .clipped()
    }
}
