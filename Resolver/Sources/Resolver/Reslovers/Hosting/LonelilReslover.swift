import Foundation
import SwiftSoup

struct LonelilReslover: Resolver {
    let name = "Lonelil"
    static let domains: [String] = ["watch.lonelil.com"]

    enum AnimetvStreamResolverError: Error {
        case idNotFound
    }
    func getMediaURL(url: URL) async throws -> [Stream] {

        var page = try await Utilities.requestCloudFlare(url: url)
        page = page.replacingOccurrences(of: "<html><head><meta name=\"color-scheme\" content=\"light dark\"></head><body><pre style=\"word-wrap: break-word; white-space: pre-wrap;\">", with: "")
            .replacingOccurrences(of: "</pre></body></html>", with: "")

        let data = page.data(using: .utf8)!
        let response = try JSONDecoder().decode(LonliResponse.self, from: data)

        return response.first?.result.data.dataJSON.stream.compactMap { stream in
           return Stream(Resolver: "Lonelil", streamURL: stream.playlist)
        } ?? []
    }

    // MARK: - LonliResponseElement
    struct LonliResponseElement: Codable {
        let result: Result

        enum CodingKeys: String, CodingKey {
            case result = "result"
        }
    }

    // MARK: - Result
    struct Result: Codable {
        let data: DataClass

        enum CodingKeys: String, CodingKey {
            case data = "data"
        }
    }

    // MARK: - DataClass
    struct DataClass: Codable {
        let dataJSON: JSON

        enum CodingKeys: String, CodingKey {
            case dataJSON = "json"
        }
    }

    // MARK: - JSON
    struct JSON: Codable {
        let stream: [SStream]

        enum CodingKeys: String, CodingKey {
            case stream = "stream"
        }
    }

    // MARK: - Stream
    struct SStream: Codable {
        let playlist: URL

        enum CodingKeys: String, CodingKey {
            case playlist = "playlist"
        }
    }

    typealias LonliResponse = [LonliResponseElement]

}
