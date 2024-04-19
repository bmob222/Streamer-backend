import Foundation
import SwiftSoup

public struct GeoAnimeProvider: Provider {
    public init() {}

    public let locale: Locale = Locale(identifier: "en")
    public let type: ProviderType = .init(.geoanime)
    public let title: String = "GeoDubbedanime"
    public let langauge: String = ""
    public let baseURL: URL = URL(staticString: "https://genoanime.com")

    public var moviesURL: URL {
        // https://genoanime.com/browse?sort=latest
        baseURL.appendingPathComponent("browse").appending("genre", value: "dubbed")
    }

    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("browse").appending("sort", value: "latest")
    }

    private var homeURL: URL {
        baseURL.appendingPathComponent("home")
    }

    enum GeoAnimeProviderError: Error {
        case missingMovieInformation
        case episodeLinkNotFound
        case invalidURL
    }

    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.downloadPage(url: url)
        return try await parsePage(content: content)
    }

    func parsePage(content: String) async throws -> [MediaContent] {
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select(".product__item")

        return try rows.array().compactMap { item in
            let path: String = try item.select("a").attr("href").replacingOccurrences(of: ".", with: "")
            var webURL: URL

            if path.hasPrefix("https") {
                webURL = try URL(path)
            } else {
                // Remove the dot (.) from the path
                let cleanedPath = path.replacingOccurrences(of: "./", with: "")
                webURL = baseURL.appendingPathComponent(cleanedPath)
            }

            let title: String = try item.select(".product__item__text h5 a").text()
            let posterPath: String = try item.select(".product__item__pic").attr("data-setbg")
            var fullPosterURL: URL

            if let posterURL = URL(string: posterPath), posterURL.scheme != nil {
                // If posterPath is a valid absolute URL
                fullPosterURL = posterURL
            } else {
                // If posterPath is a relative URL
                let absolutePosterPath = posterPath.hasPrefix("/") ? posterPath : "/" + posterPath
                fullPosterURL = baseURL.appendingPathComponent(absolutePosterPath)
            }

            let posterURL = try URL(posterPath)
            let sfullPosterURL = baseURL.appendingPathComponent(posterURL.path)

            let epType = try item.select(".ep").text()
            let type: MediaContent.MediaContentType = epType.contains("Movie") ? .movie : .tvShow

            return MediaContent(
                title: title,
                webURL: webURL,
                posterURL: sfullPosterURL,
                type: type,
                provider: self.type
            )
        }
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appending(["page": String(page)]))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appending(["page": String(page)]))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        throw GeoAnimeProviderError.missingMovieInformation
    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)

        // Extract title and poster URL
        let title = try pageDocument.select("title").text().replacingOccurrences(of: "Episode List on Genoanime", with: "").replacingOccurrences(of: "Watch", with: "")
        let posterPath = try pageDocument.select("meta[property=og:image]").attr("content")
        let posterURL = try URL(posterPath)

        let episodesDiv = try pageDocument.select(".tab-content .tab-pane.fade.in.active")
        let episodeElements = try episodesDiv.select("a.episode")

        var episodes: [Episode] = []
        var episodeURLs: [URL] = []

        for (index, episodeElement) in episodeElements.enumerated() {
            let episodeNumberText = try episodeElement.text().replacingOccurrences(of: "Ep ", with: "")
            let episodeNumber = Int(episodeNumberText) ?? (index + 1)
            let episodeLink = try episodeElement.attr("href").replacingOccurrences(of: "..", with: "")
            let episodeURL = baseURL.appendingPathComponent(episodeLink)
            let source = Source(hostURL: episodeURL)

            episodes.append(Episode(number: episodeNumber, sources: [source]))
            episodeURLs.append(episodeURL)
        }

        let season = Season(seasonNumber: 1, webURL: url, episodes: episodes)
        let tvShow = TVshow(title: title, webURL: url, posterURL: posterURL, seasons: [season])

        return tvShow
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let payload = "anime=\(keyword)".data(using: .utf8)
        let searchURL = URL(staticString: "https://genoanime.com/data/searchdata-test.php")
        let headers = [
            "authority": "genoanime.com",
            "accept": "text/html, */*; q=0.01",
            "accept-language": "en-US,en;q=0.9,ar;q=0.8",
            "cache-control": "no-cache",
            "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
            "dnt": "1",
            "origin": "https://genoanime.com",
            "pragma": "no-cache",
            "referer": "https://genoanime.com/search?ani=\(keyword)",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": "\"macOS\"",
            "sec-fetch-dest": "empty",
            "sec-fetch-mode": "cors",
            "sec-fetch-site": "same-origin",
            "x-requested-with": "XMLHttpRequest"
        ]
        let content = try await Utilities.downloadPage(url: searchURL, httpMethod: "POST", data: payload, extraHeaders: headers)
        return try await parsePage(content: content)
    }

    enum MediaType {
        case movie
        case tvShow
    }

    public func home() async throws -> [MediaContentSection] {
        let subbedURL = baseURL.appendingPathComponent("browse").appending(["sort": "latest", "genre": "subbed"])
        let dubbedURL = baseURL.appendingPathComponent("browse").appending(["sort": "latest", "genre": "dubbed"])
        let oVAURL = baseURL.appendingPathComponent("browse").appending(["sort": "latest", "genre": "OVA"])
        let specialURL = baseURL.appendingPathComponent("browse").appending(["sort": "latest", "genre": "Special"])

        let subbed = try await parsePage(url: subbedURL)
        let dubbed = try await parsePage(url: dubbedURL)
        let ova = try await parsePage(url: oVAURL)
        let special = try await parsePage(url: specialURL)

        return [
            .init(title: "Subbed", media: subbed),
            .init(title: "Dubbed", media: dubbed),
            .init(title: "OVA Series", media: ova),
            .init(title: "Special", media: special)
        ]
    }

    private struct Response: Codable {
        let html: String
    }
}
