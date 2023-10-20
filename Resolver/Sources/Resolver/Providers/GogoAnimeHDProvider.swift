import Foundation
import SwiftSoup

public struct GogoAnimeHDProvider: Provider {
    public let locale: Locale = Locale(identifier: "en")
    public let type: ProviderType = .init(.gogoAnimeHD)
    public let title: String = "GogoAnimeHD"
    public let langauge: String = ""

    public let baseURL: URL = URL(staticString: "https://gogoanimehd.to")
    public var moviesURL: URL {
        baseURL.appendingPathComponent("anime-movies.html")
    }
    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("new-season.html")
    }

    private var homeURL: URL {
        baseURL
    }

    enum EmpireStreamingProviderError: Error {
        case missingMovieInformation
    }

    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await  Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select(".items li")
        return try rows.array().compactMap { row -> MediaContent? in
            let path = try row.select(".name a").attr("href")
            let title: String = try row.select(".name a").attr("title")
            let posterPath: String = try row.select("img").attr("src")

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

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appending(["page": String(page)]))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appending(["page": String(page)]))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {

        fatalError("")
    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        var url = url
        if !url.absoluteString.contains("category/") {
            let pageContent = try await Utilities.downloadPage(url: url)
            let pageDocument = try SwiftSoup.parse(pageContent)
            let path = try pageDocument.select(".anime-info a").attr("href")
            url = baseURL.appendingPathComponent(path)
        }

        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)

        let movie_id = try pageDocument.select("#movie_id").attr("value")
        let default_ep = try pageDocument.select("#default_ep").attr("value")
        let alias_anime = try pageDocument.select("#alias_anime").attr("value")
        let episode_numbers = try pageDocument.select("#episode_page a").array().map { row in
            (try row.attr("ep_start"), try row.attr("ep_end"))
        }

        let ep_start = episode_numbers.first?.0 ?? "0"
        let ep_end = episode_numbers.last?.1 ?? "1"

        // ?ep_start=0&ep_end=0&id=12883&default_ep=0&alias=bishoujo-senshi-sailor-moon-cosmos-movie
        let loadEpisodes = URL(staticString: "https://ajax.gogo-load.com/ajax/load-list-episode")
            .appending([
                "ep_start": ep_start,
                "ep_end": ep_end,
                "id": movie_id,
                "default_ep": default_ep,
                "alias": alias_anime
            ])

        let episodesContent = try await Utilities.downloadPage(url: loadEpisodes)
        let episodesDocument = try SwiftSoup.parse(episodesContent)

        let episodes = try episodesDocument.select("#episode_related a").array().map { row in
            let epInfo = try row.select(".name").text()
            let episodeNumber = Int(String(epInfo.dropFirst(3))) ?? 1
            let path = try row.attr("href")
            let sourceUrl = self.baseURL.appendingPathComponent(path.strip())
            return Episode(number: episodeNumber, sources: [Source(hostURL: sourceUrl)])

        }.sorted()
        let title = try pageDocument.select(".anime_info_body_bg h1").text()
        let posterPath = try pageDocument.select(".anime_info_body_bg img").attr("src")
        let posterURL = try URL(posterPath)

        let seasons = [Season(seasonNumber: 1, webURL: url, episodes: episodes)]

        return TVshow(title: title, webURL: url, posterURL: posterURL, seasons: seasons)

    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let url = baseURL.appendingPathComponent("search.html").appending("keyword", value: keyword)
        return try await parsePage(url: url)

    }

    public func home() async throws -> [MediaContentSection] {

        let recentURL = URL(staticString: "https://ajax.gogo-load.com/ajax/page-recent-release.html").appending(["page": String(1), "type": String(1)])
        let recent = try await parsePage(url: recentURL)
        let dubURL = URL(staticString: "https://ajax.gogo-load.com/ajax/page-recent-release.html").appending(["page": String(1), "type": String(2)])
        let dub = try await parsePage(url: dubURL)
        let chineseURL = URL(staticString: "https://ajax.gogo-load.com/ajax/page-recent-release.html").appending(["page": String(1), "type": String(3)])
        let chinese = try await parsePage(url: chineseURL)

        return [.init(title: "Recent", media: recent), .init(title: "Dub", media: dub), .init(title: "Chinese", media: chinese)]
    }

}
