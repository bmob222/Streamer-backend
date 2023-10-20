import Foundation
import SwiftSoup

struct  SeriesYonkisResolver: Resolver {
    let name = "SeriesYonkis"
    static let domains: [String] = ["seriesyonkis.io", "seriesyonkis.nu"]

    enum SeriesYonkisResolverError: Error {
        case episodeNotAvailable
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)
        if url.absoluteString.contains("trembed") {
            let path = try pageDocument.select("iframe").attr("src")
            guard let seriesURL = URL(string: path) else {
                throw SeriesYonkisResolverError.episodeNotAvailable
            }
            return try await HostsResolver.resolveURL(url: seriesURL)
        } else {
            let path = try pageDocument.select(".TPlayer iframe").attr("src")
            guard let embedURL = URL(string: path) else {
                throw SeriesYonkisResolverError.episodeNotAvailable
            }
            return try await HostsResolver.resolveURL(url: embedURL)
        }
    }
}
