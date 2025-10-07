//
//  NTSAPIService.swift
//  NTS Radio Utility
//
//  Created by Miki on 07/10/2025.
//

import Foundation

class NTSAPIService {
    static let shared = NTSAPIService()

    private let baseURL = "https://www.nts.live/api/v2/live"

    private init() {}

    func fetchLiveData() async throws -> LiveResponse {
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("en-GB,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("u=3, i", forHTTPHeaderField: "Priority")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0.1 Safari/605.1.15", forHTTPHeaderField: "User-Agent")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlError as URLError {
            if urlError.code == .notConnectedToInternet || urlError.code == .networkConnectionLost {
                throw APIError.noInternet
            }
            throw APIError.networkError
        } catch {
            throw APIError.networkError
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            let liveResponse = try decoder.decode(LiveResponse.self, from: data)
            return liveResponse
        } catch {
            throw APIError.decodingError
        }
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError
    case noInternet

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "NTS API is temporarily unavailable"
        case .decodingError:
            return "Failed to process show data"
        case .networkError:
            return "Network connection failed"
        case .noInternet:
            return "No internet connection"
        }
    }
}
