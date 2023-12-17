import Foundation

struct GogoCDNResolver: Resolver {
    let name = "GogoCDN"
    static let domains: [String] = [
        "playtaku.net",
        "goone.pro",
        "gogo-stream.com",
        "gogo-play.net",
        "streamani.net",
        "goload.one",
        "goload.io",
        "gogohd.net",
        "gogohd.pro",
        "gembedhd.com",
        "playgo1.cc",
        "anihdplay.com",
        "playtaku.net",
        "playtaku.online",
        "gotaku1.com",
        "goone.pro"
    ]
    @EnviromentValue(key: "consumet_url", defaultValue: URL(staticString: "https://api.consumet.org"))
    private var consumetURL: URL

    enum RabbitstreamResolverError: Error {
        case idNotFound
    }
    func getMediaURL(url: URL) async throws -> [Stream] {
        let watchURL = consumetURL.appendingPathComponent("utils/extractor")
            .appending("url", value: url.absoluteString.base64Encoded())
            .appending("server", value: "gogocdn")

        let data = try await Utilities.requestData(url: watchURL)
        let response = try JSONDecoder().decode(WatchResponse.self, from: data)

        return response.sources.map {
            Stream(
                Resolver: "Gogo Server",
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
