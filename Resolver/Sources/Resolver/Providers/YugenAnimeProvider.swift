import Foundation
import SwiftSoup

public struct YugenAnimeProvider: Provider {
    public init() {}

    public let locale: Locale = Locale(identifier: "en")
    public let type: ProviderType = .init(.yugen)
    public let title: String = "YugenAnimeProvider"
    public let langauge: String = ""

    public let baseURL: URL = URL(staticString: "https://yugenanime.tv")
    public var moviesURL: URL {
        baseURL.appendingPathComponent("trending")
    }
    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("latest")
    }
    public var discoverURL: URL {
        baseURL.appendingPathComponent("discover")
    }

    private var homeURL: URL {
        baseURL
    }
    public var categories: [Category] = [
        .init(id: 0, name: "Avant Garde"),
        .init(id: 1, name: "Boys Love"),
        .init(id: 2, name: "Cars"),
        .init(id: 3, name: "Comedy"),
        .init(id: 4, name: "Dementia"),
        .init(id: 5, name: "Demons"),
        .init(id: 6, name: "Drama"),
        .init(id: 7, name: "Ecchi"),
        .init(id: 8, name: "Fantasy"),
        .init(id: 9, name: "Game"),
        .init(id: 10, name: "Girls Love"),
        .init(id: 11, name: "Gourmet"),
        .init(id: 12, name: "Harem"),
        .init(id: 13, name: "Hentai"),
        .init(id: 14, name: "Historical"),
        .init(id: 15, name: "Horror"),
        .init(id: 16, name: "Josei"),
        .init(id: 17, name: "Kids"),
        .init(id: 18, name: "Magic"),
        .init(id: 19, name: "Martial Arts"),
        .init(id: 20, name: "Mecha"),
        .init(id: 21, name: "Military"),
        .init(id: 22, name: "Music"),
        .init(id: 23, name: "Mystery"),
        .init(id: 24, name: "Parody"),
        .init(id: 25, name: "Police"),
        .init(id: 26, name: "Psychological"),
        .init(id: 27, name: "Romance"),
        .init(id: 28, name: "Samurai"),
        .init(id: 29, name: "School"),
        .init(id: 30, name: "Sci-Fi"),
        .init(id: 31, name: "Seinen"),
        .init(id: 32, name: "Shoujo"),
        .init(id: 33, name: "Shoujo Ai"),
        .init(id: 34, name: "Shounen"),
        .init(id: 35, name: "Shounen Ai"),
        .init(id: 36, name: "Slice of Life"),
        .init(id: 37, name: "Space"),
        .init(id: 38, name: "Sports"),
        .init(id: 39, name: "Suspense"),
        .init(id: 40, name: "Super Power"),
        .init(id: 41, name: "Supernatural"),
        .init(id: 42, name: "Thriller"),
        .init(id: 43, name: "Vampire"),
        .init(id: 44, name: "Yaoi"),
        .init(id: 45, name: "Yuri")
    ]

    enum YugenAnimeProviderError: Error {
        case moviesNotSupported
    }

    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.downloadPage(url: url)
        return try await parsePage(content: content, episodes: true)
    }

    public func parsePage(content: String, episodes: Bool) async throws -> [MediaContent] {
        let document = try SwiftSoup.parse(content)
        if episodes {
            let rows: Elements = try document.select(".ep-grid > li")
            return try rows.array().compactMap { row -> MediaContent? in
                let path = try row.select("a").attr("href")
                let titleElement: Element? = try row.select(".ep-origin-name").first()
                guard let title = try titleElement?.text() else {
                    return nil
                }
                let posterPath: String = try row.select("img").attr("data-src")

                guard let posterURL = URL(string: posterPath) else {
                    return nil
                }
                let webURL = baseURL.appendingPathComponent(path)
                return MediaContent(
                    title: title,
                    webURL: webURL,
                    posterURL: posterURL,
                    type: .tvShow,
                    provider: self.type
                )
            }

        } else {
            let rows: Elements = try document.select(".anime-meta")
            return try rows.array().compactMap { row -> MediaContent? in
                let path = try rows.attr("href")
                let title = try row.attr("title")
                let posterPath: String = try row.select("img").attr("data-src")
                guard let posterURL = URL(string: posterPath) else {
                    return nil
                }
                let webURL = baseURL.appendingPathComponent(path)
                return MediaContent(
                    title: title,
                    webURL: webURL,
                    posterURL: posterURL,
                    type: .tvShow,
                    provider: self.type
                )
            }

        }
    }
    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return []
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appending(["page": String(page)]))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        throw YugenAnimeProviderError.moviesNotSupported
    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        // https://yugenanime.tv/watch/18506/captain-tsubasa-season-2-junior-youth-hen/12/
        // https://yugenanime.tv/anime/18506/captain-tsubasa-season-2-junior-youth-hen/
        var url = url
        if url.absoluteString.contains("yugenanime.tv/watch") {
            let path = url.deletingLastPathComponent()
                .absoluteString
                .replacingOccurrences(of: "yugenanime.tv/watch", with: "yugenanime.tv/anime")

            url = try URL(path)

        }
        url = url.appendingPathComponent("watch")
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)
        let posterPath = try pageDocument.select("meta[property=og:image]").attr("content")
        let episodesPath = try pageDocument.select("meta[property=og:url]").attr("content")
        let posterURL = try URL(posterPath)

        let requestUrl = try URL(episodesPath)
        let data = try await Utilities.downloadPage(url: requestUrl)
        let document = try SwiftSoup.parse(data)
        let rows: Elements = try document.select(".ep-card a")
        let episodes = try rows.array().map { row -> Episode in
            let path = try row.attr("href")
            let url = self.baseURL.appendingPathComponent(path)
            let source = Source(hostURL: url)
            return Episode(number: Int(url.lastPathComponent) ?? 1, sources: [source])

        }.uniqued().sorted()
        let title = try pageDocument.select(".content h1").text()
        let finalTitle = title.replacingOccurrences(of: #"(\d+)(st|nd|rd|th) Season"#, with: "", options: .regularExpression).strip()
        let seasonNumber = Int(title.replacingOccurrences(of: #".+(\d+)(st|nd|rd|th) Season"#, with: "$1", options: .regularExpression)) ?? 1
        let season = Season(seasonNumber: seasonNumber, webURL: url, episodes: episodes)
        return TVshow(title: finalTitle, webURL: url, posterURL: posterURL, seasons: [season])
    }

    public func latestCategory(id: Int, page: Int) async throws -> [MediaContent] {
        guard let category = categories.first(where: { $0.id == id }) else {
            return []
        }
        let url = discoverURL
            .appending("genreIncluded", value: category.name)
            .appending("page", value: String(page))

        let content = try await Utilities.downloadPage(url: url)
        return try await parsePage(content: content, episodes: false)
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let url = discoverURL.appending("q", value: keyword)
        let content = try await Utilities.downloadPage(url: url)
        return try await parsePage(content: content, episodes: false)
    }

    public func home() async throws -> [MediaContentSection] {
        let content = try await Utilities.downloadPage(url: homeURL)
        var epItems =  try await parsePage(content: content, episodes: true)
        guard epItems.count >= 16 else {
            return []
        }
        let sub = MediaContentSection(title: NSLocalizedString("Sub", comment: ""), media: Array(epItems.prefix(8)))
        epItems.removeFirst(8)
        let chinese = MediaContentSection(title: NSLocalizedString("CHINESE", comment: ""), media: Array(epItems.prefix(8)))
        epItems.removeFirst(8)

        var showItems = try await parsePage(content: content, episodes: false)
        guard showItems.count >= 30 else {
            return []
        }

        let TrendingAiringSeries = MediaContentSection(
            title: NSLocalizedString("Trending Airing Series", comment: ""),
            media: Array(showItems.prefix(6))
        )
        showItems.removeFirst(6)
        let EditorPick = MediaContentSection(
            title: NSLocalizedString("Editor's Pick", comment: ""),
            media: Array(showItems.prefix(6))
        )
        showItems.removeFirst(6)

        let UnderratedSeries = MediaContentSection(
            title: NSLocalizedString("Underrated Series", comment: ""),
            media: Array(showItems.prefix(6))
        )
        showItems.removeFirst(6)

        let NewonYugenAnime = MediaContentSection(
            title: NSLocalizedString("New on YugenAnime", comment: ""),
            media: Array(showItems.prefix(6))
        )
        showItems.removeFirst(6)
        let MostPopularSeries = MediaContentSection(
            title: NSLocalizedString("Most Popular Series", comment: ""),
            media: Array(showItems.prefix(6))
        )
        showItems.removeFirst(6)

        return [sub, chinese, TrendingAiringSeries, EditorPick, UnderratedSeries, NewonYugenAnime, MostPopularSeries ]
    }
}
