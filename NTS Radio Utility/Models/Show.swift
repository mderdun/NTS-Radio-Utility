//
//  Show.swift
//  NTS Radio Utility
//
//  Created by Miki on 07/10/2025.
//

import Foundation

struct Show: Codable, Identifiable {
    let id = UUID()
    let broadcastTitle: String
    let startTimestamp: String
    let endTimestamp: String
    let embeds: ShowEmbeds

    var title: String {
        embeds.details.name
    }

    var description: String? {
        embeds.details.description
    }

    var location: String? {
        embeds.details.locationLong ?? embeds.details.locationShort
    }

    var coverArtURL: URL? {
        // Prefer medium size for UI, fallback to large
        if let medium = embeds.details.media.pictureMedium {
            return URL(string: medium)
        }
        if let large = embeds.details.media.pictureLarge {
            return URL(string: large)
        }
        return nil
    }

    var startDate: Date? {
        ISO8601DateFormatter().date(from: startTimestamp)
    }

    var endDate: Date? {
        ISO8601DateFormatter().date(from: endTimestamp)
    }

    enum CodingKeys: String, CodingKey {
        case broadcastTitle = "broadcast_title"
        case startTimestamp = "start_timestamp"
        case endTimestamp = "end_timestamp"
        case embeds
    }
}

struct ShowEmbeds: Codable {
    let details: ShowDetails
}

struct ShowDetails: Codable {
    let name: String
    let description: String?
    let locationShort: String?
    let locationLong: String?
    let media: ShowMedia

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case locationShort = "location_short"
        case locationLong = "location_long"
        case media
    }
}

struct ShowMedia: Codable {
    let pictureLarge: String?
    let pictureMediumLarge: String?
    let pictureMedium: String?
    let pictureSmall: String?
    let pictureThumb: String?
    let backgroundLarge: String?
    let backgroundMediumLarge: String?
    let backgroundMedium: String?
    let backgroundSmall: String?
    let backgroundThumb: String?

    enum CodingKeys: String, CodingKey {
        case pictureLarge = "picture_large"
        case pictureMediumLarge = "picture_medium_large"
        case pictureMedium = "picture_medium"
        case pictureSmall = "picture_small"
        case pictureThumb = "picture_thumb"
        case backgroundLarge = "background_large"
        case backgroundMediumLarge = "background_medium_large"
        case backgroundMedium = "background_medium"
        case backgroundSmall = "background_small"
        case backgroundThumb = "background_thumb"
    }
}
