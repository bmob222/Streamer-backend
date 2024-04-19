import Foundation
import SwiftSoup

struct VidsrcAPIReslover: Resolver {
    let name = "VidSrc"
    static let domains: [String] = ["streamer-backend-vidsrc-api.3tx8cy.easypanel.host", "vidsrc.streamerapp.tech"]

    enum AnimetvStreamResolverError: Error {
        case idNotFound
    }

    func getMediaURL(url: URL) async throws -> [Stream] {

        let data = try await Utilities.requestData(url: url)
        let response = try JSONDecoder().decode(Vidsrc.self, from: data)

        let subtitles = response.subtitles?.compactMap { s -> Subtitle? in
            guard let language = s.label?.components(separatedBy: .whitespaces).first? .trimmingCharacters(in: .whitespaces) else { return nil}
            return Subtitle(url: s.file, language: .init(code: language) ?? .init(rawValue: language) ?? .unknown)
        }
        return [
            Stream(
                Resolver: "VidSrc",
                streamURL: response.source,
                subtitles: subtitles ?? []
            )
        ]

    }

    // MARK: - Vidsrc
    struct Vidsrc: Codable {
        let source: URL
        let subtitles: [SSubtitle]?

        enum CodingKeys: String, CodingKey {
            case source = "source"
            case subtitles = "subtitles"
        }
    }

    // MARK: - Subtitle
    struct SSubtitle: Codable {
        let file: URL
        let label: String?
        let kind: Kind?

        enum CodingKeys: String, CodingKey {
            case file = "file"
            case label = "label"
            case kind = "kind"
        }
    }

    enum Kind: String, Codable {
        case captions = "captions"
    }

}
