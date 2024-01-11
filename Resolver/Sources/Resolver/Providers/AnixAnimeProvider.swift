import Foundation
import SwiftSoup

// KaidoAnimeProvider class that conforms to the Provider protocol
public class AnixAnimeProvider: Provider {
    // Provider type, title, and language properties
    public let type: ProviderType = .init(.anix) // Initialize provider type as Kaido
    public let title: String = "anix.to" // Set the provider title
    public let langauge: String = "" // Language property, currently set to an empty string

    // Base URL for the Kaido website
    public let baseURL: URL = URL(staticString: "https://anix.to")

    // Computed properties for specific URL paths
    public var moviesURL: URL {
        baseURL.appendingPathComponent("movie") // URL for movies
    }
    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("tv") // URL for TV shows
    }
    public var homeURL: URL {
        baseURL.appendingPathComponent("home") // URL for the homepage
    }

    public var AnimeURL: URL {
        baseURL.appendingPathComponent("anime") // URL for anime
    }

    // Function to parse a page and return an array of MediaContent
    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.downloadPage(url: url) // Download page content
        return try parsePageContent(content) // Parse the downloaded content
    }

    // Fetches the latest movies from the movies URL
    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL)
    }

    // Fetches the latest TV shows from the TV shows URL
    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL)
    }

    // Function to fetch movie details - currently not implemented
    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        return Movie(title: "", webURL: url, posterURL: url, sources: [], subtitles: nil)
    }
// https://anix.to/anime/heat-the-pig-liver-the-story-of-a-man-turned-into-a-pig-yqq31/ep-1
    // Function to fetch details of a TV show from show url
    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        // https://kaido.to/watch/to-heart-5267
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)

        let title = try pageDocument.select("data-jp").text()
        let posterPath = try pageDocument.select("img").attr("src")
        let posterURL = try URL(posterPath)

        // https://zoro.to/ajax/v2/episode/list/18079
        let mediaID = url.lastPathComponent
        let requestUrl = baseURL.appendingPathComponent("anime").appendingPathComponent(mediaID)
        // Extract title and poster URL
        let titlehtml  = try pageDocument.select(".piece")

        let episodes = try titlehtml.array().map { row -> Episode in
            let number: String = try row.attr("data-ep-name")
            let id: String = try row.attr("data-id")
            let url = self.baseURL.appendingPathComponent("anime").appendingPathComponent(mediaID).appending("id", value: id)
            let source = Source(hostURL: url)
            return Episode(number: Int(number) ?? 1, sources: [source])

        }.sorted()
        let season = Season(seasonNumber: 1, webURL: url, episodes: episodes)
        return TVshow(title: title, webURL: url, posterURL: posterURL, seasons: [season])
    }

    // Function to search content using a keyword
    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let query = keyword.replacingOccurrences(of: " ", with: "+") // Format keyword for URL
        let url = baseURL.appendingPathComponent("search")
            .appending("keyword", value: query)
        return try await parsePage(url: url)
    }

    // Function to get content for the home page
    public func home() async throws -> [MediaContentSection] {
        var items = try await parsePage(url: homeURL) // Fetch items for the home page
        guard items.count >= 24 else {
            return [] // Return empty array if not enough items
        }
        let recommendedMovies = MediaContentSection(title: NSLocalizedString("Latest Episode", comment: ""),
                                                    media: Array(items.prefix(12)))
        items.removeFirst(12)
        let recommendedTVShows = MediaContentSection(title: NSLocalizedString("New On Anix", comment: ""),
                                                     media: Array(items.prefix(12)))
        return [recommendedMovies, recommendedTVShows]
    }
}

// Private extension for KaidoAnimeProvider
private extension AnixAnimeProvider {
// pulls information from the tv homepage anix.tv/home
    // Function to parse page content and return an array of MediaContent
    func parsePageContent(_ content: String) throws -> [MediaContent] {
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select(".poster")
        let watchBaseURL = URL(staticString: "https://anix.to")

        return try rows.array().map { row in
            let path: String = try row.select("a").attr("href")
            let url = watchBaseURL.appendingPathComponent(path)
            let title: String = try row.select("img").attr("alt")
            let posterPath: String = try row.select("img").attr("src")
            let posterURL = try URL(posterPath)
            return MediaContent(title: title, webURL: url, posterURL: posterURL, type: .tvShow, provider: .anix)
        }
    }

    // Codable struct to handle response data
    private struct Response: Codable {
        let html: String
    }
}
