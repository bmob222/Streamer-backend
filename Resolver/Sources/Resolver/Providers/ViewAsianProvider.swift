import Foundation
import SwiftSoup

public struct ViewAsianProvider: Provider {
    public var type: ProviderType = .init(.viewAsian)

    public let title: String = "ViewAsian.co"
    public let langauge: String = ""

    public let baseURL: URL = URL(staticString: "https://viewasian.co/")
    public var moviesURL: URL {
        baseURL.appendingPathComponent("movie/filter/series/all/all/all/all/latest/")
    }
    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("movie/filter/series/all/all/all/all/latest/")
    }
    private var homeURL: URL {
        baseURL
    }

    @EnviromentValue(key: "consumet_url", defaultValue: URL(staticString: "https://api.consumet.org"))
    private var consumetURL: URL
    private var detailsURL: URL { consumetURL.appendingPathComponent("movies/viewasian/info") }

    enum ViewAsianProviderError: Error {
        case episodeURLNotFound
    }

    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select("div.ml-item > a")
        return try rows.array().compactMap { row in
            let path: String = try row.attr("href")
            var url = baseURL.appendingPathComponent(path)
            let title: String = try row.attr("title")
            let posterPath: String = try row.select("img").attr("data-original")
            guard let posterURL = try? URL(posterPath) else {
                return nil
            }
            url = url.appending(["poster": posterURL.absoluteString.encodeURIComponent() ])
            return MediaContent(title: title, webURL: url, posterURL: posterURL, type: .tvShow, provider: self.type)
        }
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return []
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appending("page", value: String(page)))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        let detailsURL = detailsURL.appendingQueryItem(name: "id", value: url.relativePath.removeprefix("//"))
        let data = try await Utilities.requestData(url: detailsURL)
        let media = try JSONCoder.decoder.decode(ConsumetMedia.self, from: data)
        guard let sourceURL = media.episodes.first?.url else {
            throw ViewAsianProviderError.episodeURLNotFound
        }
        let idURL = sourceURL.appending("id", value: media.id)

        let posterPath = url.queryParameters?["poster"] ?? ""
        let posterURL = try URL(posterPath)
        var year: Int?
        if let releaseDate = media.releaseDate, let releaseYear = releaseDate.components(separatedBy: "-").first, let yearInt = Int(releaseYear) {
            year = yearInt
        }

        return Movie(title: media.title, webURL: url, posterURL: posterURL, year: year, sources: [.init(hostURL: idURL )])

    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        let detailsURL = detailsURL.appendingQueryItem(name: "id", value: url.relativePath.removeprefix("//"))
        let data = try await Utilities.requestData(url: detailsURL)
        let media = try JSONCoder.decoder.decode(ConsumetMedia.self, from: data)

        var seasonsDict: [Int: [Episode]] = [:]
        media.episodes.forEach { ep in
            guard let episode = ep.episode, let epNumber = Int(episode) else { return }
            let seasonNumber = ep.season ?? 1
            if !seasonsDict.keys.contains(seasonNumber) {
                seasonsDict[seasonNumber] = []
            }
            let idURL = ep.url.appending("mediaId", value: media.id).appending("episodeId", value: ep.id)
            seasonsDict[seasonNumber]?.append(Episode(number: epNumber, sources: [.init(hostURL: idURL)]))
        }
        let seasons = seasonsDict.map { number, ep in
            Season(seasonNumber: number, webURL: url, episodes: ep)
        }
        let posterPath = url.queryParameters?["poster"] ?? ""
        let posterURL = try URL(posterPath)

        return TVshow(
            title: media.title,
            webURL: url,
            posterURL: posterURL,
            overview: media.description,
            seasons: seasons,
            actors: media.otherNames?.map { .init(name: $0, profileURL: nil)}
        )
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let keyword = keyword.replacingOccurrences(of: " ", with: "-")
        let pageURL = baseURL.appendingPathComponent("/movie/search/\(keyword)").appending("page", value: "\(page)")
        return try await parsePage(url: pageURL)
    }

    public func home() async throws -> [MediaContentSection] {
        var items = try await parsePage(url: homeURL)
        guard items.count >= 32 else {
            return []
        }

        let recommendedMovies = MediaContentSection(title: NSLocalizedString("Featured Drama", comment: ""), media: Array(items.prefix(16)))
        items.removeFirst(16)
        let recommendedTVShows = MediaContentSection(title: NSLocalizedString("Kshow", comment: ""), media: Array(items.prefix(16)))
        items.removeFirst(16)
        return [recommendedMovies, recommendedTVShows]
    }

}
