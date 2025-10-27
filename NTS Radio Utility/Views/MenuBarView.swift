//
//  MenuBarView.swift
//  NTS Radio Utility
//
//  Created by Miki on 07/10/2025.
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var viewModel: RadioViewModel

    var body: some View {
        MarqueeText(
            text: viewModel.menuBarFullText,
            font: .system(size: 13, weight: .medium, design: .rounded),
            color: .primary,
            speed: 44,
            gap: 40,
            initialDelay: 0.8
        )
        .frame(width: 150, alignment: .leading)
    }
}

#Preview {
    MenuBarView()
        .environmentObject(RadioViewModel())
}
