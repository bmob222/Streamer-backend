import Foundation
import SwiftSoup

struct DatabasegdriveplayerResolver: Resolver {
    let name = "Databasegdriveplayer"

    static let domains: [String] = ["databasegdriveplayer.xyz"]

    enum TwoEmbedResolverError: Error {
        case capchaKeyNotFound
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)
        return try await pageDocument.select("#list-server-more a").array()
            .filter { row in
                (try? row.attr("href").contains(VidCloud9Resolver.domains)) == true
            }
            .map {try "https:" + $0.attr("href")}
            .compactMap { URL(string: $0)}
            .concurrentMap {
                return try? await HostsResolver.resolveURL(url: $0)
            }
            .compactMap { $0 }
            .flatMap { $0 }
    }

}

private extension String {
    func contains(_ strings: [String]) -> Bool {
        strings.contains { contains($0) }
    }
}
