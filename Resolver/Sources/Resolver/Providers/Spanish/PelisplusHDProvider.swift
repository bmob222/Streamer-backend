import Foundation
import SwiftSoup

public class PelisplusHDProvider: Provider {
    public init() {}

    public let type: ProviderType = .init(.pelisplus)

    public let title: String = "pelisplushd"
    public let langauge: String = "🇪🇸"

    public let baseURL: URL = URL(staticString: "https://ww1.pelisplushd.nu")
    public var moviesURL: URL {
        baseURL.appendingPathComponent("peliculas")
    }
    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("series")
    }
    public var homeURL: URL {
        baseURL
    }
    enum PelisplusHDProvider: Error {
        case MovieDetailsError
        case hostURLNotAvailable
    }

    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.downloadPage(url: url)
        return try parsePageContent(content)
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appending("page", value: String(page)))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appending("page", value: String(page)))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)

        let title = try pageDocument.select("title").text()
        let posterPath = try pageDocument.select("meta[property='og:image']").attr("content")
        let posterURL = try URL(posterPath)

        if let iframe = try pageDocument.select("div.video-html iframe").first(),
           let hostURLString = try? iframe.attr("src"),
           let hostURL = URL(string: hostURLString) {
            return Movie(title: cleanTitle(title), webURL: url, posterURL: posterURL, sources: [.init(hostURL: hostURL)])
        } else {
            throw PelisplusHDProvider.hostURLNotAvailable
        }
    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)

        let title = try pageDocument.select("title").text()
        let posterPath = try pageDocument.select("meta[property='og:image']").attr("content")
        let posterURL = try URL(posterPath)

        // Select the tab content for the first season
        let tabContent = try pageDocument.select(".tab-content .tab-pane").first()

        // Extract episode links and episode numbers from the tab content
        let episodeLinks = try tabContent?.select("a").array() ?? []

        var episodes: [Episode] = []

        for (index, episodeLinkElement) in episodeLinks.enumerated() {
            let episodeLink = try episodeLinkElement.attr("href").replacingOccurrences(of: "..", with: "")

            // Extract episode number from the link text
            let episodeNumberText = try episodeLinkElement.text().replacingOccurrences(of: "T1 - E", with: "")
            let episodeNumber = Int(episodeNumberText) ?? (index + 1)

            // Unwrap the optional URL
            if let episodeURL = URL(string: episodeLink, relativeTo: url) {
                // Assuming you have a Source structure
                let source = Source(hostURL: episodeURL)
                episodes.append(Episode(number: episodeNumber, sources: [source]))
            }
        }
        // Create the TVshow object with extracted data
        return TVshow(title: cleanTitle(title), webURL: url, posterURL: posterURL, seasons: [Season(seasonNumber: 1, webURL: url, episodes: episodes)])
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let query = keyword.replacingOccurrences(of: " ", with: "+")
        let url = baseURL.appendingPathComponent("search").appending("s", value: query)
        return try await parsePage(url: url)
    }

    public func home() async throws -> [MediaContentSection] {
        let recentURL = URL(string: "https://pelisplushd.nz/year/2023/series") ?? baseURL
        let recent = try await parsePage(url: recentURL)

        let AnimeURL = URL(string: "https://pelisplushd.nz/animes")?.appending(["page": String(1), "type": String(2)]) ?? baseURL
        let Anime = try await parsePage(url: AnimeURL)

        let DoramaURL = URL(string: "https://pelisplushd.nz/generos/dorama")?.appending(["page": String(1), "type": String(3)]) ?? baseURL
        let Dorama = try await parsePage(url: DoramaURL)

        return [.init(title: "Recent TV Shows", media: recent), .init(title: "Anime", media: Anime), .init(title: "Dorama", media: Dorama)]
    }

    func cleanTitle(_ title: String) -> String {
        return title.replacingOccurrences(of: "streaming", with: "")
            .replacingOccurrences(of: "Online - Pelisplus", with: "")
            .removingRegexMatches(pattern: "\\(\\d{4}\\)", replaceWith: "") // (2022)
            .strip()
    }

}
private extension PelisplusHDProvider {

    private func parsePageContent(_ content: String) throws -> [MediaContent] {
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select("a.Posters-link")

        return try rows.array().map { row in
            let path: String = try row.select("a").attr("href")
            let url = try URL(path)
            let title: String = try row.select(".listing-content p").text()
            let posterPath: String = try row.select(".Posters-img").attr("src")
            let posterURL = try URL(posterPath)
            let type: MediaContent.MediaContentType = path.contains("/pelicula/") ? .movie :  .tvShow
            return MediaContent(title: title, webURL: url, posterURL: posterURL, type: type, provider: .pelisplus)
        }

    }

    private struct Response: Codable {
        let html: String
    }
}
