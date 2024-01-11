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
        return Utilities.extractURLs(content: rows)
            .filter { $0.absoluteString.contains("mp4") }
            .compactMap {
                Stream(
                    Resolver: "WeCima",
                    streamURL: $0
                )
            }
    }

}
