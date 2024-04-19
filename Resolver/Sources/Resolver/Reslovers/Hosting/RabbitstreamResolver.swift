import Foundation
import SwiftSoup
import CryptoSwift

struct RabbitstreamResolver: Resolver {
    let name = "Rabbitstream"
    static let domains: [String] = ["rabbitstream.net", "rapid-cloud.co", "megacloud.tv"]

    @EnviromentValue(key: "consumet_url", defaultValue: URL(staticString: "https://api.consumet.org"))
    private var consumetURL: URL

    enum RabbitstreamResolverError: Error {
        case idNotFound
    }
    func getMediaURL(url: URL) async throws -> [Stream] {
        var server = "vidcloud"
        if url.absoluteString.contains("/e-1/") {
            server = "rapidcloud"
        }
        if url.absoluteString.contains("megacloud") {
            server = "megacloud"
        }

        let watchURL = consumetURL.appendingPathComponent("utils/extractor")
            .appending("url", value: url.absoluteString.base64Encoded())
            .appending("server", value: server)

        let data = try await Utilities.requestData(url: watchURL)
        let response = try JSONDecoder().decode(WatchResponse.self, from: data)

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
        let quality: String?
        let isM3U8: Bool

    }
    // MARK: - Subtitle
    struct ConsumetSubtitle: Codable, Equatable {
        let url: URL
        let lang: String
    }

}
