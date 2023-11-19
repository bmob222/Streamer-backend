import Foundation
import SwiftSoup

struct StreamtapeResolver: Resolver {
    let name = "Streamtape"

    static let domains: [String] = [
        "streamtape.com", "streamtapeadblock.art", "streamtape.to", "tapeblocker.com", "streamtapeadblockuser.xyz"
    ]

    @EnviromentValue(key: "consumet_url", defaultValue: URL(staticString: "https://api.consumet.org"))
    private var consumetURL: URL

    enum RabbitstreamResolverError: Error {
        case idNotFound
    }
    func getMediaURL(url: URL) async throws -> [Stream] {
        let watchURL = consumetURL.appendingPathComponent("utils/extractor")
            .appending("url", value: url.absoluteString.base64Encoded())
            .appending("server", value: "streamtape")

        let data = try await Utilities.requestData(url: watchURL)
        let response = try JSONDecoder().decode(WatchResponse.self, from: data)
        return response.sources.map {
            Stream(
                Resolver: response.headers.Referer.host ?? "FlixHQ",
                streamURL: $0.url,
                headers: ["Referer": response.headers.Referer.absoluteString]
            )
        }

    }

    // MARK: - WatchResponse
    struct WatchResponse: Codable, Equatable {
        let headers: ConsumetHeaders
        let sources: [ConsumetSource]
    }

    // MARK: - Headers
    struct ConsumetHeaders: Codable, Equatable {
        let Referer: URL
    }
    // MARK: - Source
    struct ConsumetSource: Codable, Equatable {
        let url: URL
        let isM3U8: Bool

    }
}
