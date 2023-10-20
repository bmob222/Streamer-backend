import Foundation
import SwiftSoup

struct FilmPalastResolver: Resolver {
    let name = "FilmPalast"
    static let domains: [String] = ["filmpalast.to"]
    private let baseURL: URL = URL(staticString: "https://filmpalast.to/")

    func getMediaURL(url: URL) async throws -> [Stream] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select("a.iconPlay")
        return try await rows.array().compactMap { row -> URL? in
            let path1: String = try row.attr("data-player-url")
            let path2: String = try row.attr("href")
            let path: String = path1.isEmpty ? path2 : path1
            guard let url = URL(string: path) else {
                return nil
            }
            return url
        } .concurrentMap {
            return try? await HostsResolver.resolveURL(url: $0)
        }
        .compactMap { $0 }
        .flatMap { $0 }
    }

}
