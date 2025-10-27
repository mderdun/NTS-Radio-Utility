//
//  Channel.swift
//  NTS Radio Utility
//
//  Created by Miki on 07/10/2025.
//

import Foundation

struct Channel: Codable, Identifiable {
    let id = UUID()
    let channelName: String
    let now: Show
    let next: [Show]

    var channelNumber: Int {
        Int(channelName) ?? 1
    }

    var streamURL: URL {
        URL(string: "https://streams.radiomast.io/nts\(channelName)")!
    }

    enum CodingKeys: String, CodingKey {
        case channelName = "channel_name"
        case now
    }

    init(channelName: String, now: Show, next: [Show]) {
        self.channelName = channelName
        self.now = now
        self.next = next
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        channelName = try container.decode(String.self, forKey: .channelName)
        now = try container.decode(Show.self, forKey: .now)

        // Decode dynamic "next" keys
        var nextShows: [Show] = []
        let dynamicContainer = try decoder.container(keyedBy: DynamicCodingKeys.self)

        for key in dynamicContainer.allKeys {
            if key.stringValue.starts(with: "next") {
                if let show = try? dynamicContainer.decode(Show.self, forKey: key) {
                    nextShows.append(show)
                }
            }
        }

        next = nextShows
    }
}

struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
