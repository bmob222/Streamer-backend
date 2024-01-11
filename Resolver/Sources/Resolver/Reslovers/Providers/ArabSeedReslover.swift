import Foundation
import SwiftSoup

struct ArabSeedResolver: Resolver {
    let name = "ArabSeed"
    static let domains: [String] = ["f20.arabseed.ink"]

    enum ArabSeedResolverError: Error {
        case urlNotValid
    }
    func canHandle(url: URL) -> Bool {
        Self.domains.firstIndex(of: url.host!) != nil || url.host?.contains("arabseed") == true
    }

    func getMediaURL(url: URL) async throws -> [Stream] {

        let arabseedURL = try await Utilities.getRedirect(url: ArabseedProvider.baseURL)
        let mainContent = try await Utilities.downloadPage(url: url)
        let mainDocument = try SwiftSoup.parse(mainContent)
        let watchPath = try mainDocument.select(".WatchButtons > a").attr("href")
        let watchURL = try URL(watchPath)

        let content = try await Utilities.downloadPage(
            url: watchURL,
            extraHeaders: [
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
                "Accept-Language": "en-US,en;q=0.9,ar;q=0.8",
                "Connection": "keep-alive",
                "DNT": "1",
                "Host": watchURL.host ?? "",
                "Referer": arabseedURL.absoluteString,
                "sec-ch-ua": "\"Google Chrome\";v=\"113\", \"Chromium\";v=\"113\", \"Not-A.Brand\";v=\"24\"",
                "sec-ch-ua-mobile": "?0",
                "sec-ch-ua-platform": "\"macOS\"",
                "Sec-Fetch-Dest": "document",
                "Sec-Fetch-Mode": "navigate",
                "Sec-Fetch-Site": "cross-site",
                "Sec-Fetch-User": "?1",
                "Upgrade-Insecure-Requests": "1",
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36"
            ]
        )
        let document = try SwiftSoup.parse(content)
        var lastKey: Quality = .unknown
        var linksDic: [Quality: [URL]] = [lastKey: []]
        try document.select("ul > li[data-link], ul > h3").array().lazy.forEach { element in
            if try element.iS("h3") {
                lastKey = (Quality(quality: try element.text()) ?? Quality.unknown)
                linksDic[lastKey] = []
            } else {
                let path = try element.attr("data-link")
                var quality = lastKey
                if quality == .unknown {
                    let text = try element.text()
                    quality = Quality(quality: text) ?? .unknown
                }
                let url = try URL(path)
                if !linksDic.keys.contains(quality) {
                    linksDic[quality] = []

                }
                linksDic[quality]?.append(url)
            }
        }

        return try await linksDic.concurrentMap { quality, links in
            try await links.concurrentMap { link -> [Stream] in
                if link.absoluteString.contains("reviewtech") || link.absoluteString.contains("reviewrate.net") || link.absoluteString.contains("techinsider.wiki") {
                    return (try? await getMp4Link(url: link, quality: quality)) ?? []
                } else {
                    return (try? await HostsResolver.resolveURL(url: link).map {
                        Stream(stream: $0, quality: quality)
                    }) ?? []
                }
            }
        }
        .flatMap { $0.lazy.joined() }
    }

    private func getMp4Link(url: URL, quality: Quality) async throws -> [Stream] {
        let content = try await Utilities.downloadPage(url: url, extraHeaders: ["Referer": ArabseedProvider.baseURL.absoluteString])

        let document = try SwiftSoup.parse(content)
        let links: Elements = try document.select("source[src]") // a with href

        return links.array().compactMap { row in
            try? row.attr("src")
        }
        .compactMap {
            URL(string: $0)
        }
        .map {
            .init(
                Resolver: "ArabSeed",
                streamURL: $0,
                quality: quality,
                headers: [
                    "Host": url.host ?? "",
                    "Referer": url.absoluteString
                ]
            )
        }
    }

}
