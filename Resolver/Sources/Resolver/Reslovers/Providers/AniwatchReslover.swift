import Foundation
import SwiftSoup

struct AniwatchReslover: Resolver {
    let name = "Aniwatch"

    static let domains: [String] = ["aniwatch.to"]
    private let baseURL: URL = URL(staticString: "https://aniwatch.to")

    func canHandle(url: URL) -> Bool {
        Self.domains.firstIndex(of: url.host!) != nil || url.host?.contains("aniwatch") == true
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
       // https://aniwatch.to/ajax/v2/episode/servers?episodeId=107145&id=the-summer-18553

        let data = try await Utilities.requestData(url: url)
        let serversContent = try JSONDecoder().decode(HTMLResponse.self, from: data)

        let serversDocument = try SwiftSoup.parse(serversContent.html)
        let rows: Elements = try serversDocument.select(".server-item")
        return try await rows.array().map { row -> URL in
            let eposideNumber: String = try row.attr("data-id")
                let sourceURL = baseURL.appendingPathComponent("ajax/v2/episode/sources")
                .appendingQueryItem(name: "id", value: eposideNumber)
            return sourceURL
        }
        .concurrentMap {
            let data = try await Utilities.requestData(url: $0)
            let content = try JSONDecoder().decode(Response.self, from: data)
            return try? await HostsResolver.resolveURL(url: content.link)
        }
        .compactMap { $0 }
        .flatMap { $0 }

    }

    struct Response: Codable {
        let link: URL
    }

    struct HTMLResponse: Codable {
        let status: Bool
        let html: String
    }

}
