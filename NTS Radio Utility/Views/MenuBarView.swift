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
        Text(viewModel.menuBarText)
            .font(.system(size: 13, weight: .medium, design: .rounded))
    }
}

#Preview {
    MenuBarView()
        .environmentObject(RadioViewModel())
}
