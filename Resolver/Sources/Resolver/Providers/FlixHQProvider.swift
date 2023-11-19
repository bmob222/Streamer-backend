import Foundation
import SwiftSoup

public struct FlixHQProvider: Provider {
    public var type: ProviderType = .init(.flixHQ)
    public let title: String = "FlixHQ.to"
    public let langauge: String = "🇺🇸"
    public let baseURL: URL = URL(staticString: "https://flixhq.pe")
    public var moviesURL: URL {
        baseURL.appendingPathComponent("movie")
    }
    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("tv-show")
    }
    private var homeURL: URL {
        baseURL.appendingPathComponent("home")
    }

    @EnviromentValue(key: "consumet_url", defaultValue: URL(staticString: "https://api.consumet.org"))
    private var consumetURL: URL

    private var detailsURL: URL { consumetURL.appendingPathComponent("movies/flixhq/info") }

    enum FlixHQProviderError: Error {
        case episodeURLNotFound
    }

    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select(".flw-item")
        return try rows.array().map { row in
            let path: String = try row.select(".film-name a").attr("href")
            let url: URL
            if path.hasPrefix("https") {
                url = try URL(path)
            } else {
                url = baseURL.appendingPathComponent(path)
            }
            let title: String = try row.select(".film-name a").text()
            let posterPath: String = try row.select(".film-poster img").attr("data-src")
            let posterURL = try URL(posterPath)
            let type: MediaContent.MediaContentType = path.contains("/movie/") ? .movie :  .tvShow
            return MediaContent(title: title, webURL: url, posterURL: posterURL, type: type, provider: self.type)
        }
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appending("page", value: String(page)))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appending("page", value: String(page)))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        let detailsURL = detailsURL.appendingQueryItem(name: "id", value: url.relativePath.removeprefix("//"))
        let data = try await Utilities.requestData(url: detailsURL)
        let media = try JSONCoder.decoder.decode(ConsumetMedia.self, from: data)
        guard let sourceURL = media.episodes.first?.url else {
            throw FlixHQProviderError.episodeURLNotFound
        }
        let idURL = sourceURL.appending("id", value: media.id)
        let posterURL = media.image ?? URL(staticString: "https://feelagain.ca/images/placeholder-poster-sm.png")
        var year: Int?
        if let releaseDate = media.releaseDate, let releaseYear = releaseDate.components(separatedBy: "-").first, let yearInt = Int(releaseYear){
            year = yearInt
        }
        return Movie(title: media.title, webURL: url, posterURL: posterURL, year: year, sources: [.init(hostURL: idURL )])

    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        let detailsURL = detailsURL.appendingQueryItem(name: "id", value: url.relativePath.removeprefix("/"))
        let data = try await Utilities.requestData(url: detailsURL)
        let media = try JSONCoder.decoder.decode(ConsumetMedia.self, from: data)

        var seasonsDict: [Int: [Episode]] = [:]
        media.episodes.forEach { ep in
            guard let epNumber = ep.number, let seasonNumber = ep.season else { return }
            if !seasonsDict.keys.contains(seasonNumber) {
                seasonsDict[seasonNumber] = []
            }
            let idURL = ep.url.appending("id", value: media.id)
            seasonsDict[seasonNumber]?.append(Episode(number: epNumber, sources: [.init(hostURL: idURL)]))
        }
        let seasons = seasonsDict.map { number, ep in
            Season(seasonNumber: number, webURL: url, episodes: ep)
        }
        let posterURL = media.image ?? URL(staticString: "https://feelagain.ca/images/placeholder-poster-sm.png")
        var year: Int?
        if let releaseDate = media.releaseDate, let releaseYear = releaseDate.components(separatedBy: "-").first, let yearInt = Int(releaseYear){
            year = yearInt
        }

        return TVshow(title: media.title, webURL: url, posterURL: posterURL,year: year, seasons: seasons)
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let keyword = keyword.replacingOccurrences(of: " ", with: "-")
        let pageURL = baseURL.appendingPathComponent("search/\(keyword)").appending("page", value: "\(page)")
        return try await parsePage(url: pageURL)
    }

    public func home() async throws -> [MediaContentSection] {
        var items = try await parsePage(url: homeURL)
        guard items.count >= 64 else {
            return []
        }

        let recommendedMovies = MediaContentSection(title: NSLocalizedString("Trending Movies", comment: ""), media: Array(items.prefix(24)))
        items.removeFirst(24)
        let recommendedTVShows = MediaContentSection(title: NSLocalizedString("Trending TV Shows", comment: ""), media: Array(items.prefix(24)))
        items.removeFirst(24)
        let latestMovies = MediaContentSection(title: NSLocalizedString("Latest Movies", comment: ""), media: Array(items.prefix(24)))
        items.removeFirst(24)
        let latestTVSeries = MediaContentSection(title: NSLocalizedString("Latest TV Shows", comment: ""), media: Array(items.prefix(24)))
        return [recommendedMovies, recommendedTVShows, latestMovies, latestTVSeries]
    }
}

// MARK: - ListProjects
public struct ConsumetMedia: Codable, Equatable {
    public let id: String
    public let title: String
    public let image: URL?
    public let description: String
    public let otherNames: [String]?
    public let episodes: [ConsumetEpisode]
    public let releaseDate: String?
}

// MARK: - Episode
public struct ConsumetEpisode: Codable, Equatable {
    public let id: String
    public let title: String
    public let url: URL
    public let number: Int?
    public let episode: String?
    public let season: Int?
}
