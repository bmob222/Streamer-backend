import Foundation
import SwiftyPyString

struct MyCloudResolver: Resolver {
    let name = "Mcloud"

    static let domains: [String] = [
        "vidplay.site",
        "mcloud.to",
        "mwvn.vizcloud.info",
        "vidstream.pro",
        "vidstreamz.online",
        "vizcloud.cloud",
        "vizcloud.digital",
        "vizcloud.info",
        "vizcloud.live",
        "vizcloud.online",
        "vizcloud.xyz",
        "vizcloud2.online",
        "vizcloud2.ru",
        "mcloud.bz"
    ]

    @EnviromentValue(key: "consumet_url", defaultValue: URL(staticString: "https://api.consumet.org"))
    private var consumetURL: URL

    enum RabbitstreamResolverError: Error {
        case idNotFound
    }
    func getMediaURL(url: URL) async throws -> [Stream] {
        let watchURL = consumetURL.appendingPathComponent("utils/extractor")
            .appending("url", value: url.absoluteString.base64Encoded())
            .appending("server", value: "vidcloud")

        guard let data = try? await Utilities.requestData(url: watchURL),
              let response = try? JSONDecoder().decode(WatchResponse.self, from: data) else {
            throw RabbitstreamResolverError.idNotFound
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
