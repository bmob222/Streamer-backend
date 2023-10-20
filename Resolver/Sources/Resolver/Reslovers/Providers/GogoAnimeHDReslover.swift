import Foundation
import SwiftSoup

struct GogoAnimeHDResolver: Resolver {
    let name = "GogoAnime"
    static let domains: [String] = ["gogoanimehd.to"]

    func getMediaURL(url: URL) async throws -> [Stream] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)

        return try await document.select("[data-video]").array()
            .map {
                try $0.attr("data-video")
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
