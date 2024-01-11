import Foundation
import SwiftSoup

struct AniworldResolver: Resolver {
    let name = "aniworld"
    static let domains: [String] = ["aniworld.to"]

    func getMediaURL(url: URL) async throws -> [Stream] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)

        return try await document.select("[data-link]").array()
            .map {
                try $0.attr("data-link")
            }
            .compactMap {
                    URL(string: $0)
            }
            .concurrentMap {
                return try? await HostsResolver.resolveURL(url: $0)
            }
            .compactMap { $0 }
            .flatMap { $0 }

    }

}
