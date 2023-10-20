import Foundation
import SwiftSoup

struct PelisflixResolver: Resolver {
    let name = "Pelisnetflix"
    static let domains: [String] = ["pelisflix.one", "pelisflix.uno", "pelisflix.org", "pelisflix2.tv", "pelisflix2.bio"]

    func getMediaURL(url: URL) async throws -> [Stream] {
        let pageData = try await Utilities.downloadPage(url: url, encoding: .isoLatin1)
        let pageDocument = try SwiftSoup.parse(pageData)
        return try await pageDocument.select("[data-url]").array().asyncMap { row -> [Stream] in
            guard let path = try row.attr("data-url").base64Decoded(),
                  path.contains("/watch/"),
                  let url = URL(string: path) else {
                return []
            }
            return try await HostsResolver.resolveURL(url: url)
        }.flatMap {
            $0
        }
    }
}
