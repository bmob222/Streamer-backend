import Foundation
import SwiftSoup

public struct PutlockerProvider: Provider {
    public init() {}

    public var type: ProviderType = .init(.putlocker)

    public let title: String = "PutLocker.vip"
    public let langauge: String = "🇺🇸"

    private let baseURL: URL = URL(staticString: "https://ww7.putlocker.vip")
    private var moviesURL: URL {
        baseURL.appendingPathComponent("movie/filter/movies/")
    }
    private var tvShowsURL: URL {
        baseURL.appendingPathComponent("movie/filter/series/")
    }

    private var homeURL: URL {
        baseURL.appendingPathComponent("putlocker")
    }

    enum PutlockerProviderError: Error {
        case movieIDNotFound
    }

    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select(".ml-item")
        return try rows.array().map { info in
            let row = try info.select(".mli-poster > a")
            let path: String = try row.attr("href")
            let url = baseURL.appendingPathComponent(path)
            let title: String = try row.attr("title")
            let posterPath: String = try row.select("img").attr("data-original")
            let posterURL = URL(string: posterPath)!
            let typeRaw = try info.select(".mim-type").text()
            let type: MediaContent.MediaContentType = typeRaw == "TV" ? .tvShow :  .movie
            return MediaContent(title: title, webURL: url, posterURL: posterURL, type: type, provider: .putlocker)
        }
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appendingPathComponent(page))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appendingPathComponent(page))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        // https://ww7.putlocker.vip/film/wham-98023/
        let pageURL = url.appendingPathComponent("watching.html")
        let content = try await Utilities.downloadPage(url: pageURL)
        let document = try SwiftSoup.parse(content)
        let title = try document.select(".mvic-desc > h3").html()
        let posterPath = try document.select("[property=og:image]").first()?.attr("content") ?? ""
        let posterURL = try URL(posterPath)

        var year: Int?
        if let releaseYear = try document.select(".mvici-right a").last()?.text(), let yearInt = releaseYear.components(separatedBy: "-").first {
            year = Int(yearInt) ?? 2023
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let movieID = components.path.components(separatedBy: "-").last?.dropLast() else {
            throw PutlockerProviderError.movieIDNotFound
        }

        let movieEpisodesURL = baseURL.appendingPathComponent("ajax/movie/episode/servers").appendingPathComponent(movieID + "_1_full")
        let data = try await Utilities.requestData(url: movieEpisodesURL)
        let serversContent = try JSONDecoder().decode(Response.self, from: data)

        let serversDocument = try SwiftSoup.parse(serversContent.html)
        let rows: Elements = try serversDocument.select(".nav-item a")
        let sources = try rows.array().map { row -> Source in
            let eposideNumber: String = try row.attr("data-id")
            // https://ww7.putlocker.vip/ajax/movie/episode/server/sources/304a594956677552656b7a744b447342434866727649575671764b6632663851424167377354624d6167383d_1
            let sourceURL = baseURL.appendingPathComponent("ajax/movie/episode/server/sources").appendingPathComponent(eposideNumber + "_1")
            return Source(hostURL: sourceURL)
        }
        return Movie(title: title, webURL: url, posterURL: posterURL, year: year, sources: sources)

    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        let pageURL = url.appendingPathComponent("watching.html")
        let content = try await Utilities.downloadPage(url: pageURL)
        let document = try SwiftSoup.parse(content)
        let details = try document.select(".mvic-desc > h3").text()
        let title = details.trimmingCharacters(in: .whitespaces)
        let posterPath = try document.select("[property=og:image]").first()?.attr("content") ?? ""
        let posterURL = try URL(posterPath)

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let id = components.path.components(separatedBy: "-").last?.dropLast() else {
            throw PutlockerProviderError.movieIDNotFound
        }

        let seriesID = String(id)
        let seasonsURL = baseURL.appendingPathComponent("ajax/movie/seasons").appendingPathComponent(seriesID)
        let data = try await Utilities.requestData(url: seasonsURL)
        let serversContent = try JSONDecoder().decode(Response.self, from: data)
        var year: Int?
        if let releaseYear = try document.select(".mvici-right a").last()?.text(), let yearInt = releaseYear.components(separatedBy: "-").first {
            year = Int(yearInt) ?? 2023
        }

        let serversDocument = try SwiftSoup.parse(serversContent.html)
        let rows: Elements = try serversDocument.select("a")

        let seasons = try await rows.array().concurrentMap { row -> Season? in

            let seasonNumber = try row.attr("data-id")
            // https://ww7.putlocker.vip/ajax/movie/season/episodes/97711_1

            let epsURL = self.baseURL.appendingPathComponent("ajax/movie/season/episodes").appendingPathComponent(seriesID + "_" + seasonNumber)
            let epsData = try await Utilities.requestData(url: epsURL)
            guard let epsContent = try? JSONDecoder().decode(Response.self, from: epsData) else {
                return nil
            }
            let epsDocument = try SwiftSoup.parse(epsContent.html)
            let epsRows: Elements = try epsDocument.select("a")
            let eposides = try epsRows.array().map { ep in
                let dataId = try ep.attr("data-id")
                let epNumber = dataId.components(separatedBy: "_").last ?? ""
                // https://ww7.putlocker.vip/ajax/movie/episode/servers/97711_1_1
                let sourceURL = self.baseURL.appendingPathComponent("ajax/movie/season/episodes").appendingPathComponent(seriesID + "_" + seasonNumber + "_" + epNumber)
                return Episode(number: Int(epNumber) ?? 1, sources: [.init(hostURL: sourceURL)])
            }

            return Season(seasonNumber: Int(seasonNumber) ?? 1, webURL: epsURL, episodes: eposides)
        }.compactMap { $0 }
        return TVshow(title: title, webURL: url, posterURL: posterURL, year: year, seasons: seasons)
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let keyword = keyword.replacingOccurrences(of: " ", with: "-")
        let pageURL = baseURL.appendingPathComponent("/movie/search/\(keyword)").appending("page", value: "\(page)")
        return try await parsePage(url: pageURL)
    }

    public func home() async throws -> [MediaContentSection] {
        var items = try await parsePage(url: homeURL)
        guard items.count >= 64 else {
            return []
        }

        let recommendedMovies = MediaContentSection(title: NSLocalizedString("Featured Movies", comment: ""), media: Array(items.prefix(20)))
        items.removeFirst(20)
        let recommendedTVShows = MediaContentSection(title: NSLocalizedString("Featured TV Series", comment: ""), media: Array(items.prefix(20)))
        items.removeFirst(20)
        let latestMovies = MediaContentSection(title: NSLocalizedString("Latest Movies", comment: ""), media: Array(items.prefix(16)))
        items.removeFirst(16)
        let latestTVSeries = MediaContentSection(title: NSLocalizedString("Latest TV Series", comment: ""), media: items)
        return [recommendedMovies, recommendedTVShows, latestMovies, latestTVSeries]
    }

    private struct Response: Codable {
        let status: Bool
        let html: String
    }
    private struct MovieEmbedResponse: Codable {
        let status: Bool
        let src: String
    }

}
