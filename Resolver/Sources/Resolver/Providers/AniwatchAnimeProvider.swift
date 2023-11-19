import Foundation
import SwiftSoup

public class AniwatchAnimeProvider: Provider {
    public let type: ProviderType = .init(.aniwatch)

    public let title: String = "aniwatch.to"
    public let langauge: String = ""

    public let baseURL: URL = URL(staticString: "https://aniwatch.to")
    public var moviesURL: URL {
        baseURL.appendingPathComponent("movie")
    }
    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("tv")
    }
    public var homeURL: URL {
        baseURL.appendingPathComponent("home")
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
        // Not used
        return Movie(title: "", webURL: url, posterURL: url, sources: [], subtitles: nil)
    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)

        let title = try pageDocument.select(".anisc-detail > .film-name").text()
        let posterPath = try pageDocument.select(".anisc-poster > .film-poster> img").attr("src")
        let posterURL = URL(string: posterPath)!

        let mediaID = url.lastPathComponent.components(separatedBy: "-").last!
        let requestUrl = baseURL.appendingPathComponent("ajax/v2/episode/list/").appendingPathComponent(mediaID)
        let data = try await Utilities.requestData(url: requestUrl)
        let content = try JSONCoder.decoder.decode(Response.self, from: data)
        let document = try SwiftSoup.parse(content.html)
        let rows: Elements = try document.select(".ss-list > a")
        let episodes = try rows.array().map { row -> Episode in
            let number: String = try row.attr("data-number")
            let id: String = try row.attr("data-id")
            let url = self.baseURL.appendingPathComponent("ajax/v2/episode/servers")
                .appending(["episodeId": id])
                .appending(["id": url.lastPathComponent])
            let source = Source(hostURL: url)
            return Episode(number: Int(number) ?? 1, sources: [source])

        }.sorted()
        let season = Season(seasonNumber: 1, webURL: url, episodes: episodes)
        return TVshow(title: title, webURL: url, posterURL: posterURL, seasons: [season])
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let query = keyword.replacingOccurrences(of: " ", with: "+")
        let url = baseURL.appendingPathComponent("search")
            .appending("keyword", value: query)
        return try await parsePage(url: url)
    }

    public func home() async throws -> [MediaContentSection] {
        var items = try await parsePage(url: homeURL)
        guard items.count >= 24 else {
            return []
        }
        let recommendedMovies = MediaContentSection(title: NSLocalizedString("Latest Episode", comment: ""),
                                                    media: Array(items.prefix(12)))
        items.removeFirst(12)
        let recommendedTVShows = MediaContentSection(title: NSLocalizedString("New On aniwatch", comment: ""),
                                                     media: Array(items.prefix(12)))
        return [recommendedMovies, recommendedTVShows]

    }
}

private extension AniwatchAnimeProvider {

    private func parsePageContent(_ content: String) throws -> [MediaContent] {
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select(".film_list-wrap > .flw-item > .film-poster")
        let watchBaseURL = URL(staticString: "https://aniwatch.to/watch")

        return try rows.array().map { row in
            let path: String = try row.select("a").attr("href").replacingOccurrences(of: "?ref=search", with: "")
            let url = watchBaseURL.appendingPathComponent(path)
            let title: String = try row.select("img").attr("alt")
            let posterPath: String = try row.select("img").attr("data-src")
            let posterURL = URL(string: posterPath)!
            return MediaContent(title: title, webURL: url, posterURL: posterURL, type: .tvShow, provider: .kaido)
        }

    }

    private struct Response: Codable {
        let html: String
    }
}
