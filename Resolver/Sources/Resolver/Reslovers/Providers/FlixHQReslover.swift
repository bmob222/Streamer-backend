import Foundation
import SwiftSoup

struct FlixHQResolver: Resolver {
    let name = "FlixHQ"
    static let domains: [String] = ["flixhq.to"]

    @EnviromentValue(key: "consumet_url", defaultValue: URL(staticString: "https://api.consumet.org"))
    private var consumetURL: URL

    enum FlixHQResolverError: Error {
        case idNotFound
    }
    func getMediaURL(url: URL) async throws -> [Stream] {

        guard let mediaId = url.queryParameters?["id"] else {
            throw FlixHQResolverError.idNotFound
        }

        let episodeId = url.lastPathComponent

        return try await ["upcloud", "vidcloud"].concurrentMap { server -> [Stream]?  in
            let watchURL = consumetURL.appendingPathComponent("movies/flixhq/watch")
                .appending("episodeId", value: episodeId)
                .appending("mediaId", value: mediaId)
                .appending("server", value: server)

           guard let data = try? await Utilities.requestData(url: watchURL),
                 let response = try? JSONDecoder().decode(WatchResponse.self, from: data) else {
               return nil
           }

            let subttiles = response.subtitles.map {
                let lang = $0.lang.components(separatedBy: "-").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? $0.lang
                return Subtitle(url: $0.url, language: .init(rawValue: lang) ?? .english)

            }
            return response.sources.map {
                Stream(
                    Resolver: response.headers.Referer.host ?? "FlixHQ",
                    streamURL: $0.url,
                    quality: Quality(quality: $0.quality),
                    headers: ["Referer": response.headers.Referer.absoluteString],
                    subtitles: subttiles
                )
            }
       }
       .compactMap { $0 }
       .flatMap { $0 }
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
