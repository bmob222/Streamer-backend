import Foundation
import SwiftyPyString

struct VidPlayReslover: Resolver {
    let name = "VidPlayer"

    static let domains: [String] = [
        "vidplay.online",
        "vidplay.site",
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
        "vid41c.site"
    ]

    @EnviromentValue(key: "mycloud_keys_url", defaultValue: URL(staticString: "https://google.com"))
    var keysURL: URL

    func canHandle(url: URL) -> Bool {
        Self.domains.firstIndex(of: url.host!) != nil || url.host?.contains("vidplay") == true
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let url = url.removing("sub.info")
        let info = url.absoluteString.replacingOccurrences(of: "https://", with: "")
        let eURL = keysURL.appendingPathComponent("vidplay").appending("url", value: info.encodeURIComponent())

        do {

            let data = try await Utilities.requestData(url: eURL)
            let content = try JSONDecoder().decode(VidPlay.self, from: data)
            return content.stream.compactMap {

                Stream(Resolver: "VizCloud", streamURL: $0.playlist, headers: [
                    "Referer": $0.headers.referer,
                    "Origin": $0.headers.origin
                ], subtitles: $0.captions.map { .init(url: $0.url, language: .init(rawValue: $0.language) ?? .unknown)})
            }
        } catch {
            print(error)
            throw error
        }

    }

    // MARK: - VidPlay
    struct VidPlay: Codable {
        let stream: [SStream]

        enum CodingKeys: String, CodingKey {
            case stream = "stream"
        }
    }

    // MARK: - Stream
    struct SStream: Codable {
        let playlist: URL
        let headers: Headers
        let captions: [Caption]

        enum CodingKeys: String, CodingKey {
            case playlist = "playlist"
            case headers = "headers"
            case captions = "captions"
        }
    }

    // MARK: - Caption
    struct Caption: Codable {
        let url: URL
        let language: String

        enum CodingKeys: String, CodingKey {
            case url = "url"
            case language = "language"
        }
    }

    // MARK: - Headers
    struct Headers: Codable {
        let referer: String
        let origin: String

        enum CodingKeys: String, CodingKey {
            case referer = "Referer"
            case origin = "Origin"
        }
    }

}
