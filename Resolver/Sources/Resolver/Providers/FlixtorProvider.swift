import Foundation
import SwiftSoup

public struct FlixtorProvider: Provider {
    public let type: ProviderType = .init(.flixtor)
    public let title: String = "Flixtorz.to"

    public let baseURL: URL = URL(staticString: "https://flixtorz.to")
    public var moviesURL: URL {
        baseURL.appendingPathComponent("movies")
    }
    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("tv")
    }
    private var homeURL: URL {
        baseURL.appendingPathComponent("home")
    }
    public let langauge: String = "🇺🇸"

    public init() {}
    @EnviromentValue(key: "vrfSolverURL", defaultValue: URL(staticString: "https://google.com"))
    private var vrfSolverURL: URL

    @EnviromentValue(key: "vrfSolverKey", defaultValue: "111111")
    private var vrfSolverKey: String

    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await  Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select(".movies .part")
        return try rows.array().compactMap { row -> MediaContent? in
            let content = try row.select("a")
            let path = try content.attr("href")
            let isMovie = path.contains("/movie/")
            let title: String = try content.select("img").attr("alt")
            let posterPath: String = try content.select("img").attr("data-src")
            guard let posterURL = URL(string: posterPath) else {
                return nil
            }
            let webURL = baseURL.appendingPathComponent(path)
            return MediaContent(
                title: title,
                webURL: webURL,
                posterURL: posterURL,
                type: isMovie ? .movie : .tvShow,
                provider: self.type
            )
        }
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
        let details = try pageDocument.select("#video-info .poster img")
        let title = try details.attr("alt")
        let posterPath = try details.attr("src")
        let posterURL = try URL(posterPath)

        let dataId = try pageDocument.select(".watch-wrap").attr("data-id")
        let requestUrl = baseURL.appendingPathComponent("ajax/episode/list").appendingPathComponent(dataId)
        let releaseDate = try pageDocument.select("[itemprop=dateCreated]").text()
        let year = Int(releaseDate.components(separatedBy: " ").last ?? "2023")
        let vrf = try await encodeVrf(text: dataId)
        let data = try await Utilities.requestData(url: requestUrl, parameters: ["vrf": vrf])
        let content = try JSONCoder.decoder.decode(Response.self, from: data)

        let document = try SwiftSoup.parse(content.result)
        let row: Element = try document.select(".episode-range  a").array().first!
        let epDataId: String = try row.attr("data-id")
        let sourceUrl = self.baseURL.appendingPathComponent("ajax/server/list").appendingPathComponent(epDataId)
        let sources =  [Source(hostURL: sourceUrl)]
        return Movie(title: title, webURL: url, posterURL: posterURL, year: year, sources: sources, subtitles: nil)
    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)
        let details = try pageDocument.select("#video-info .poster img")
        let title = try details.attr("alt")
        let posterPath = try details.attr("src")
        let posterURL = try URL(posterPath)

        let dataId = try pageDocument.select(".watch-wrap").attr("data-id")
        let requestUrl = baseURL.appendingPathComponent("ajax/episode/list").appendingPathComponent(dataId)
        let releaseDate = try pageDocument.select("[itemprop=dateCreated]").text()
        let year = Int(releaseDate.components(separatedBy: " ").last ?? "2023")

        let vrf = try await encodeVrf(text: dataId)
        let data = try await Utilities.requestData(url: requestUrl, parameters: ["vrf": vrf])
        let content = try JSONCoder.decoder.decode(Response.self, from: data)
        let document = try SwiftSoup.parse(content.result)
        let rows: Elements = try document.select(".episode-range")
        let seasons = try rows.array().map { seasonDoc in

            let episodes = try seasonDoc.select("a").array().map { row in
                let epInfo = try row.attr("data-num")
                let episodeNumber = Int(epInfo) ?? 1
                let epDataId = try row.attr("data-id")
                let sourceUrl = self.baseURL.appendingPathComponent("ajax/server/list").appendingPathComponent(epDataId)
                return Episode(number: episodeNumber, sources: [Source(hostURL: sourceUrl)])
            }

            let seasonInfo = try seasonDoc.attr("data-season")
            let seasonNumber = Int(seasonInfo) ?? 1
            let seasonURL = baseURL.appendingPathComponent(seasonNumber)
            return Season(seasonNumber: seasonNumber, webURL: seasonURL, episodes: episodes)
        }

        return TVshow(title: title, webURL: url, posterURL: posterURL,year: year, seasons: seasons)
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let query = keyword.replacingOccurrences(of: " ", with: "+")
        let url = baseURL.appendingPathComponent("filter").appending("keyword", value: query)
        return try await parsePage(url: url)
    }

    public func home() async throws -> [MediaContentSection] {
        var items = try await parsePage(url: homeURL)
        guard items.count >= 80 else {
            return []
        }
        let recommendedMovies = MediaContentSection(title: NSLocalizedString("Recommended Movies", comment: ""),
                                                    media: Array(items.prefix(16)))
        items.removeFirst(16)
        let recommendedTVShows = MediaContentSection(title: NSLocalizedString("Recommended TV shows", comment: ""),
                                                     media: Array(items.prefix(16)))
        items.removeFirst(16)
        let trending = MediaContentSection(title: NSLocalizedString("Trending", comment: ""),
                                           media: Array(items.prefix(16)))
        items.removeFirst(16)
        let latestMovies = MediaContentSection(title: NSLocalizedString("Latest Movies", comment: ""),
                                               media: Array(items.prefix(16)))
        items.removeFirst(16)
        let latestTVSeries = MediaContentSection(title: NSLocalizedString("Latest TV Series", comment: ""),
                                                 media: items)
        return [recommendedMovies, recommendedTVShows, trending, latestMovies, latestTVSeries]
    }
}

private extension FlixtorProvider {
    struct Response: Codable {
        let result: String
    }

    func encodeVrf(text: String) async throws -> String {
        struct SearchData: Codable {
            let url: String
        }
        let url = vrfSolverURL.appendingPathComponent("fmovies-vrf").appending([
            "query": text,
            "apikey": vrfSolverKey
        ])
        let data = try await Utilities.requestData(url: url)
        let result = try JSONDecoder().decode(SearchData.self, from: data).url
        return result.replacingOccurrences(of: "/", with: "%2F").replacingOccurrences(of: "=", with: "%3D")
    }
}
