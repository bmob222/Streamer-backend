import Foundation
import SwiftSoup

struct WeCimaReslover: Resolver {
    let name = "WeCima"
    static let domains: [String] = ["weeciimaa.top"]

    func canHandle(url: URL) -> Bool {
        Self.domains.firstIndex(of: url.host!) != nil
        || url.host?.contains("weeciimaa") == true
        || url.host?.contains("weciimaa") == true
        || url.host?.contains("w1ecima") == true
        || url.host?.contains("mywe-ciima") == true
        || url.host?.contains("ciima") == true
        || url.host?.contains("we-cima") == true
        || url.absoluteString.contains("resolver=weciimaa") == true
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let rows = try document.select(".Download--Wecima--Single").html()

        let direct = Utilities.extractURLs(content: rows)
            .filter { $0.absoluteString.contains("mp4") }
            .compactMap {
                Stream(
                    Resolver: "WeCima",
                    streamURL: $0
                )
            }

            // extract all btn that has data-url
        let servers = try document.select(".WatchServersList ul li")
            .compactMap { try? $0.select("btn").first() }
            .compactMap {  try? $0.attr("data-url")}
            .compactMap { $0 }

        let streams: [Stream] =  try await servers
            .concurrentMap { path -> [Stream]? in
                guard let url = URL(string: path) else { return nil }
                return (try? await HostsResolver.resolveURL(url: url)) ?? []

            }
            .compactMap { $0 }
            .flatMap { $0 }

        return direct + streams
    }

}
