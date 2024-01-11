import Foundation

struct MixdropResolver: Resolver {
    let name = "Mixdrop"
    static let domains: [String] = [
        "mixdrop.co",
        "mixdrop.to",
        "mixdrop.club",
        "mixdrop.sx",
        "mixdrop.bz",
        "mixdroop.bz",
        "mixdrop.vc",
        "mixdrop.ag",
        "mdy48tn97.com",
        "md3b0j6hj.com",
        "mdbekjwqa.pw"
    ]
    @EnviromentValue(key: "consumet_url", defaultValue: URL(staticString: "https://api.consumet.org"))
    private var consumetURL: URL

    enum RabbitstreamResolverError: Error {
        case idNotFound
    }
    func getMediaURL(url: URL) async throws -> [Stream] {
        let watchURL = consumetURL.appendingPathComponent("utils/extractor")
            .appending("url", value: url.absoluteString.base64Encoded())
            .appending("server", value: "mixdrop")

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
