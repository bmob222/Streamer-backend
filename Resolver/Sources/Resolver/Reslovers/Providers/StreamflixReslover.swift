import Foundation
import SwiftSoup

struct StreamflixResolver: Resolver {
    let name = "Streamflix"

    static let domains: [String] = ["us-west2-compute-proxied.streamflix.one"]

    enum FlixHQResolverError: Error {
        case idNotFound
    }
    func getMediaURL(url: URL) async throws -> [Stream] {

        guard let data = try? await Utilities.requestData(url: url),
              let response = try? JSONDecoder().decode(WatchResponse.self, from: data) else {
            return []
        }

        let subttiles = response.subtitles.map {
            let lang = $0.lang.components(separatedBy: "-").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? $0.lang
            return Subtitle(url: $0.url, language: .init(rawValue: lang) ?? .english)

        }
        return response.sources.map {
            Stream(
                Resolver: "StreamFlix.one",
                streamURL: $0.url,
                quality: Quality(quality: $0.quality),
                headers: ["Referer": response.headers.Referer.absoluteString],
                subtitles: subttiles
            )
        }

    }

    // MARK: - WatchResponse
    struct WatchResponse: Codable, Equatable {
        let headers: ConsumetHeaders
        let sources: [ConsumetSource]
        let subtitles: [ConsumetSubtitle]
    }

    // MARK: - Headers
    struct ConsumetHeaders: Codable, Equatable {
        let Referer: URL
    }
    // MARK: - Source
    struct ConsumetSource: Codable, Equatable {
        let url: URL
        let quality: String
        let isM3U8: Bool

    }
    // MARK: - Subtitle
    struct ConsumetSubtitle: Codable, Equatable {
        let url: URL
        let lang: String
    }

}
