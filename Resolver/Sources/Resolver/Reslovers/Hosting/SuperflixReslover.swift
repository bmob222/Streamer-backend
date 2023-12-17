import Foundation
import SwiftSoup

struct SuperflixReslover: Resolver {
    let name = "Superflix"
    static let domains: [String] = ["23dfbfad8cb2-stremio-addon-superflix.baby-beamup.club"]

    enum AnimetvStreamResolverError: Error {
        case idNotFound
    }
    func getMediaURL(url: URL) async throws -> [Stream] {

        let data = try await Utilities.requestData(url: url)
        let response = try JSONDecoder().decode(Superflix.self, from: data)

        return response.streams.compactMap { stream in

            let subtitles = stream.subtitles.compactMap { s -> Subtitle? in
                guard let url = URL(string: s.url),
                      let language = s.lang.components(separatedBy: .whitespaces).first? .trimmingCharacters(in: .whitespaces) else { return nil}
                return Subtitle(url: url, language: .init(code: language) ?? .init(rawValue: language) ?? .unknown)
            }
            let q = Quality(quality: stream.name)
            if q == .k4 { return nil }

           return  Stream(
                Resolver: "Superflix",
                streamURL: stream.url,
                quality: q,
                subtitles: subtitles
            )
        }
    }

    // MARK: - Superflix
    struct Superflix: Codable {
        let streams: [SuperFlixStream]

        enum CodingKeys: String, CodingKey {
            case streams
        }
    }

    // MARK: - Stream
    struct SuperFlixStream: Codable {
        let name: String
        let description: String
        let url: URL
        let subtitles: [SuperflixSubtitle]

        enum CodingKeys: String, CodingKey {
            case name
            case description
            case url
            case subtitles
        }
    }

    // MARK: - Subtitle
    struct SuperflixSubtitle: Codable {
        let id: String
        let lang: String
        let url: String

        enum CodingKeys: String, CodingKey {
            case id
            case lang
            case url
        }
    }

}
