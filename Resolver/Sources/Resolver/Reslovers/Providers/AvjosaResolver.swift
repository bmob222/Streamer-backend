import Foundation
import SwiftSoup

struct AvjosaResolver: Resolver {
    let name = "AvjosaResolver"
    static let domains: [String] = ["avjosa.com"]

    enum AvjosaResolverError: Error {
        case urlNotValid, contentFetchingError, parsingError
    }
    func canHandle(url: URL) -> Bool {
        Self.domains.firstIndex(of: url.host!) != nil || url.host?.contains("avjosa") == true
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        // Fetch and parse the main content
        guard let content = try? await Utilities.downloadPage(url: url) else {
            throw AvjosaResolverError.contentFetchingError
        }
        let document = try SwiftSoup.parse(content)

        // Extract the src attribute of the iframe with id "main-embed"
        let iframeSrcs = try document.select("a.redirect").array().map {
            try $0.attr("href")

        }

        // Convert relative URLs to absolute URLs and filter out invalid ones
        return try await iframeSrcs.compactMap { src -> URL? in
            guard var absoluteSrc = URL(string: src, relativeTo: url)?.absoluteString else {
                throw AvjosaResolverError.urlNotValid
            }
            if src.starts(with: "//") {
                absoluteSrc = "https:" + src
            }
            return URL(string: absoluteSrc)
        }.concurrentMap {
            return try? await HostsResolver.resolveURL(url: $0)
        }
        .compactMap { $0 }
        .flatMap { $0 }

    }
}
