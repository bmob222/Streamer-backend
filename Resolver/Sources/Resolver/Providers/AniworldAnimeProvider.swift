import Foundation
import SwiftSoup

public struct AniworldAnimeProvider: Provider {
    public let locale: Locale = Locale(identifier: "en")
    public let type: ProviderType = .init(.aniworld)
    public let title: String = "aniworld"
    public let langauge: String = ""

    public let baseURL: URL = URL(staticString: "https://aniworld.to")
    public var popularURL: URL {
        baseURL.appendingPathComponent("beliebte-animes")
    }
    // testing
    public var germanURL: URL {
        baseURL.appendingPathComponent("genre/ger/1")
    }

    public var kalendarURL: URL {
        baseURL.appendingPathComponent("animekalender")
    }

    // testing end

    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("animekalender")
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
        let rows: Elements = try document.select("div a")
        return try rows.array().compactMap { row -> MediaContent? in
            let path = try row.select("a").attr("href")
            let title: String = try row.select("img[alt]").attr("alt")
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

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: popularURL.appending(["page": String(page)]))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appending(["page": String(page)]))
    }
    // fuction test

    public func latestGerman(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: germanURL.appending(["1": String(page)]))
    }

    // function end
    public func fetchMovieDetails(for url: URL) async throws -> Movie {

        fatalError("")
    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        var url = url
        if !url.absoluteString.contains("genre/") {
            let pageContent = try await Utilities.downloadPage(url: url)
            let pageDocument = try SwiftSoup.parse(pageContent)
            let path = try pageDocument.select("a").attr("href")
            url = baseURL.appendingPathComponent(path)
        }
        // test germdub

        // test germend

        // need to revise
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)

        // Extract all data-episode-id values
        let episodeIds = try pageDocument.select("[data-episode-id]").array().compactMap { element in
            return try? element.attr("data-episode-id")
        }

        // Extract all data-season-id values
        let seasonIds = try pageDocument.select("[data-season-id]").array().compactMap { element in
            return try? element.attr("data-season-id")
        }

        // Extract all data-link-target values
        let linkTargets = try pageDocument.select("[data-link-target]").array().compactMap { element in
            return try? element.attr("data-link-target")
        }
        let movie_id = try pageDocument.select("[ul]").attr("[itemprop]")
        // genre link maybe to be used

        let genre_link = try pageDocument.select("a").attr("href")
        url = baseURL.appendingPathComponent(genre_link)

        let default_ep = try pageDocument.select("#default_ep").attr("value")
        let alias_anime = try pageDocument.select("#alias_anime").attr("value")
        let episode_numbers = try pageDocument.select("#episode_page a").array().map { row in
            (try row.attr("ep_start"), try row.attr("ep_end"))
        }

        let ep_start = episode_numbers.first?.0 ?? "0"
        let ep_end = episode_numbers.last?.1 ?? "1"

        // ?ep_start=0&ep_end=0&id=12883&default_ep=0&alias=bishoujo-senshi-sailor-moon-cosmos-movie
        let loadEpisodes = URL(staticString: "https://ajax.gogocdn.net/ajax/load-list-episode")
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
        let title = try pageDocument.select("alt").text()
        let posterPath = try pageDocument.select("a img").attr("src")
        let posterURL = try URL(posterPath)

        let seasons = [Season(seasonNumber: 1, webURL: url, episodes: episodes)]

        return TVshow(title: title, webURL: url, posterURL: posterURL, seasons: seasons)

    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let url = baseURL.appendingPathComponent("search").appending("keyword", value: keyword)
        return try await parsePage(url: url)

    }
    // new function use as base
    public func home() async throws -> [MediaContentSection] {

        let recentURL = URL(staticString: "animekalender")
        let recent = try await parsePage(url: recentURL)
        let dubURL = URL(staticString: "https://aniworld.to/genre/ger/1").appending(["1": String(1), "type": String(2)])
        let dub = try await parsePage(url: dubURL)
        let germanDubSection = MediaContentSection(title: "German Dub", media: dub)

        return [.init(title: "Recent", media: recent), germanDubSection]
    }

}
