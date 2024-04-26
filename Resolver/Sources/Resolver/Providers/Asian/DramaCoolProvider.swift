import Foundation
import SwiftSoup

public struct DramaCoolProvider: Provider {
    public init() {}

    public var type: ProviderType = .init(.dramacool)

    public let title: String = "DramaCool"
    public let langauge: String = ""

    public let baseURL: URL = URL(staticString: "https://asianc.to/")
    public var moviesURL: URL {
        baseURL.appendingPathComponent("recently-added-movie")
    }
    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("recently-added")
    }
    private var homeURL: URL {
        baseURL
    }

    @EnviromentValue(key: "consumet_url", defaultValue: URL(staticString: "https://api.consumet.org"))
    private var consumetURL: URL
    private var detailsURL: URL { consumetURL.appendingPathComponent("movies/dramacool/info") }

    enum ViewAsianProviderError: Error {
        case episodeURLNotFound
    }

    public func parsePage(url: URL, type: MediaContent.MediaContentType = .tvShow) async throws -> [MediaContent] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select(".list-episode-item li a")
        return try rows.array().compactMap { row in
            let path: String = try row.attr("href")
            let url: URL?
            if path.hasPrefix("https://") {
                url = try? URL(path)
            } else {
                url = baseURL.appendingPathComponent(path)
            }
            let title: String = try row.select("h3").text()
            let posterPath: String = try row.select("img").attr("data-original")
            guard let url, let posterURL = try? URL(posterPath) else {
                return nil
            }
            return MediaContent(title: title, webURL: url, posterURL: posterURL, type: type, provider: self.type)
        }
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appending("page", value: String(page)), type: .movie)
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appending("page", value: String(page)))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        var mediaId: String
        if url.absoluteString.contains("/drama-detail/") {
            mediaId = "/drama-detail/" + url.lastPathComponent
        } else {
            let content = try await Utilities.downloadPage(url: url)
            let document = try SwiftSoup.parse(content)
            guard let id = try document.select(".category a").array().map({ try $0.attr("href") }).first(where: { $0.contains("/drama-detail/")}) else {
                throw ViewAsianProviderError.episodeURLNotFound
            }
            mediaId = id
        }

        let detailsURL = detailsURL.appendingQueryItem(name: "id", value: mediaId)
        let data = try await Utilities.requestData(url: detailsURL)
        let media = try JSONDecoder().decode(ConsumetMedia.self, from: data)
        guard let ep = media.episodes.first else {
            throw ViewAsianProviderError.episodeURLNotFound
        }
        let idURL = ep.url.appending("mediaId", value: media.id).appending("episodeId", value: ep.id)

        let posterURL = media.image ?? .init(staticString: "https://eticketsolutions.com/demo/themes/e-ticket/img/movie.jpg")
        var year: Int?
        if let releaseDate = media.releaseDate, let releaseYear = releaseDate.components(separatedBy: "-").first, let yearInt = Int(releaseYear) {
            year = yearInt
        }

        return Movie(title: media.title, webURL: url, posterURL: posterURL, year: year, sources: [.init(hostURL: idURL )])

    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        var mediaId: String
        if url.absoluteString.contains("/drama-detail/") {
            mediaId = "/drama-detail/" + url.lastPathComponent
        } else {
            let content = try await Utilities.downloadPage(url: url)
            let document = try SwiftSoup.parse(content)
            guard let id = try document.select(".category a").array().map({ try $0.attr("href") }).first(where: { $0.contains("/drama-detail/")}) else {
                throw ViewAsianProviderError.episodeURLNotFound
            }
            mediaId = id
        }

        let detailsURL = detailsURL.appendingQueryItem(name: "id", value: mediaId)
        let data = try await Utilities.requestData(url: detailsURL)
        let media = try JSONDecoder().decode(ConsumetMedia.self, from: data)

        var seasonsDict: [Int: [Episode]] = [:]
        media.episodes.forEach { ep in
            guard let epNumber = ep.episode else { return }
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

        return TVshow(
            title: media.title,
            webURL: url,
            posterURL: media.image ?? .init(staticString: "https://eticketsolutions.com/demo/themes/e-ticket/img/movie.jpg"),
            overview: media.description,
            seasons: seasons,
            actors: media.otherNames?.map { .init(name: $0, profileURL: nil)}
        )
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        //https://asianc.to/search?type=movies&keyword=test
        let pageURL = baseURL.appendingPathComponent("/search").appending("page", value: "\(page)").appending("type", value: "movies").appending("keyword", value: keyword)
        return try await parsePage(url: pageURL)
    }

    public func home() async throws -> [MediaContentSection] {
        var items = try await parsePage(url: homeURL)
        guard items.count >= 72 else {
            return []
        }

        let RecentlyDrama = MediaContentSection(title: NSLocalizedString("Recently Drama", comment: ""), media: Array(items.prefix(36)))
        items.removeFirst(36)
        let RecentlyMovie = MediaContentSection(title: NSLocalizedString("Recently Movie", comment: ""), media: Array(items.prefix(36)))
        items.removeFirst(36)
        let RecentlyKshow = MediaContentSection(title: NSLocalizedString("Recently Kshow", comment: ""), media: Array(items))
        return [RecentlyDrama, RecentlyMovie, RecentlyKshow]
    }

    // MARK: - ListProjects
    struct ConsumetMedia: Codable, Equatable {
        public let id: String
        public let title: String
        public let image: URL?
        public let description: String
        public let otherNames: [String]?
        public let episodes: [ConsumetEpisode]
        public let releaseDate: String?
    }

    // MARK: - Episode
    struct ConsumetEpisode: Codable, Equatable {
        public let id: String
        public let title: String
        public let url: URL
        public let number: Int?
        public let episode: Int?
        public let season: Int?
    }

}
