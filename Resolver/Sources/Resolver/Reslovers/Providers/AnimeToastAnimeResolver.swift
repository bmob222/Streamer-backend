import Foundation
import SwiftSoup

struct AnimeToastAnimeResolver: Resolver {
    let name = "AnimeToast"
    static let domains: [String] = ["www.animetoast.cc"]

    enum AnimeToastResolverError: Error {
        case urlNotValid, contentFetchingError, parsingError
    }


        
    func getMediaURL(url: URL) async throws -> [Stream] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)

        return try await document.select("iframe").array()
            .map {
                try $0.attr("src")
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
