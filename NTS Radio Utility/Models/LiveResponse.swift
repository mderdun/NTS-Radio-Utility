//
//  LiveResponse.swift
//  NTS Radio Utility
//
//  Created by Miki on 07/10/2025.
//

import Foundation

struct LiveResponse: Codable {
    let results: [Channel]

    var nts1: Channel? {
        results.first { $0.channelName == "1" }
    }

    var nts2: Channel? {
        results.first { $0.channelName == "2" }
    }
}
