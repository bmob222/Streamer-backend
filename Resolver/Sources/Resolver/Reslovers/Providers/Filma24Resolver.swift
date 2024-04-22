import Foundation
import SwiftSoup

struct Filma24Resolver: Resolver {
    let name = "Filma24 Resolver"

    static let domains: [String] = ["filma24.lol", "www.filma24.lol"]
    private let baseURL: URL = URL(staticString: "https://www.filma24.lol")
    enum Filma24ResolverError: Error {
        case invalidContent
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)

        var allLinks: [URL] = []

        // Select the <ul> element with specific classes
        guard let ulElement = try document.select("ul.list-unstyled.text-center").first() else {
            throw Filma24ResolverError.invalidContent
        }

        // Select all anchor tags <a> within the selected <ul> element
        let anchorTags = try ulElement.select("a[href]")

        // Extract the links and skip those with "#"
        for anchorTag in anchorTags {
            guard let href = try? anchorTag.attr("href"), !href.contains("#"), !href.contains("mixdrop  "),
                  let url = URL(string: href) else {
                continue
            }
            allLinks.append(url)
        }

        // Convert URLs to Stream objects
        let streamURLs = try await allLinks.concurrentMap { url in
            return try await HostsResolver.resolveURL(url: url)
        }.flatMap { $0 }

        return streamURLs
    }
}
