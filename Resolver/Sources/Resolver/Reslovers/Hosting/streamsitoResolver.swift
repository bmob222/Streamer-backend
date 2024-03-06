import Foundation
import SwiftSoup

struct StreamsitoResolver: Resolver {
    let name = "StreamsitoResolver"
    static let domains: [String] = ["streamsito.com"]

    enum StreamsitoResolverError: Error {
        case episodeNotAvailable
        case urlNotValid
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)
        let lis = pageDocument
        let links = try extractLinks(from: pageContent)
        return try await links.concurrentMap { videoURL -> [Stream] in
            guard let resolvedStreams = try? await HostsResolver.resolveURL(url: videoURL) else {
                return []
            }
            return resolvedStreams
        }
        .flatMap { $0 }
    }

    func extractLinks(from content: String) throws -> [URL] {
        let doc = try SwiftSoup.parse(content)
        let html = try doc.select(".OptionsLangDisp").html()
        var matches =  html.matches(for: "go_to_player\\(\'(.+)\\',").compactMap {
            URL(string: $0)
        }
        matches = matches + html.matches(for: "go_to_playerVast\\(\'(.+)\\',").compactMap {
            URL(string: $0)
        }
        return matches
    }
}
