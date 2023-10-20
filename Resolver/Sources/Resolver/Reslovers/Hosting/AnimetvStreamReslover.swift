import Foundation
import SwiftSoup

struct AnimetvStreamResolver: Resolver {
    let name = "AnimetvStream"
    static let domains: [String] = ["api.9animetv.live"]

    enum AnimetvStreamResolverError: Error {
        case idNotFound
    }
    func getMediaURL(url: URL) async throws -> [Stream] {
        let headers =
        [
            "Host": "api.9animetv.live",
            "Connection": "keep-alive",
            "sec-ch-ua": "\"Not.A/Brand\";v=\"8\", \"Chromium\";v=\"114\", \"Google Chrome\";v=\"114\"",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": "\"macOS\"",
            "Upgrade-Insecure-Requests": "1",
            "DNT": "1",
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
            "Sec-Fetch-Site": "same-origin",
            "Sec-Fetch-Mode": "navigate",
            "Sec-Fetch-User": "?1",
            "Sec-Fetch-Dest": "iframe",
            "Referer": "https://api.9animetv.live/player/cinema-player.php?id=tt8962124",
            "Accept-Language": "en-US,en;q=0.9,ar;q=0.8"
        ]
        let content = try await Utilities.downloadPage(url: url, extraHeaders: headers)

        return try await Utilities.extractURLs(content: content).filter { $0.absoluteString.contains("bestx.stream") }.concurrentMap {
            return try? await HostsResolver.resolveURL(url: $0)
        }.compactMap { $0 }.flatMap { $0 }
    }
}
