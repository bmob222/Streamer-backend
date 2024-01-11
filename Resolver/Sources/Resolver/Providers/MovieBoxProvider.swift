import Foundation
import SwiftSoup

public struct MovieBoxProvider: Provider {
    public init() {}

    public var type: ProviderType = .init(.moviebox)
    public let title: String = "Moviebox"
    public let langauge: String = "🇺🇸"
    @EnviromentValue(key: "movieboxprovider_url", defaultValue: URL(staticString: "https://google.com/"))
    public var baseURL: URL
    public var moviesURL: URL {
        baseURL.appendingPathComponent("movies")
    }
    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("tvshows")
    }
    private var homeURL: URL {
        baseURL.appendingPathComponent("home")
    }
    public var categories: [Category] = [
        .init(id: 0, name: "4K Movies"),
        .init(id: 1, name: "Action"),
        .init(id: 2, name: "Adventure"),
        .init(id: 3, name: "Animation"),
        .init(id: 4, name: "Biography"),
        .init(id: 5, name: "Comedy"),
        .init(id: 6, name: "Crime"),
        .init(id: 7, name: "Documentary"),
        .init(id: 8, name: "Drama"),
        .init(id: 9, name: "Family"),
        .init(id: 10, name: "Fantasy"),
        .init(id: 11, name: "Film-Noir"),
        .init(id: 12, name: "History"),
        .init(id: 13, name: "Horror"),
        .init(id: 14, name: "Music"),
        .init(id: 15, name: "Mystery"),
        .init(id: 16, name: "Romance"),
        .init(id: 17, name: "Sci-Fi"),
        .init(id: 18, name: "Sport"),
        .init(id: 19, name: "Thriller"),
        .init(id: 20, name: "War"),
        .init(id: 21, name: "Western"),
        .init(id: 22, name: "Christmas"),
        .init(id: 24, name: "Reality-TV"),
        .init(id: 45, name: "News"),
        .init(id: 51, name: "Game-Show"),
        .init(id: 52, name: "Talk-Show"),
        .init(id: 53, name: "Short")
    ]

    enum MovieBoxProviderError: Error {
        case episodeURLNotFound
    }

    public func parsePage(url: URL) async throws -> [MediaContent] {
        let data = try await Utilities.requestData(url: url)
        let response = try JSONDecoder().decode(ListingResponse.self, from: data)
        return response.data.map { row in
            let type: MediaContent.MediaContentType = row.boxType == 1 ? .movie :  .tvShow
            let url = baseURL.appendingPathComponent(type == .movie ? "movie" : "tvshow").appendingPathComponent(row.id)
            let posterURL = row.poster ?? .init(staticString: "https://eticketsolutions.com/demo/themes/e-ticket/img/movie.jpg")
            return MediaContent(title: row.title, webURL: url, posterURL: posterURL, type: type, provider: self.type)
        }
    }

    public func latestCategory(id: Int, page: Int) async throws -> [MediaContent] {
        guard let category = categories.first(where: { $0.id == id }) else {
            return []
        }
        let url: URL
        if id == 0 {
            url = baseURL.appendingPathComponent("4k/movies").appendingPathComponent(page)
        } else {
            url = baseURL.appendingPathComponent("category/movies").appendingPathComponent(id).appendingPathComponent(page)
        }
        return try await parsePage(url: url)
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appendingPathComponent(page))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appendingPathComponent(page))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        let data = try await Utilities.requestData(url: url)
        let media = try JSONDecoder().decode(MovieResponse.self, from: data)
        let id = url.lastPathComponent
        let hostURL = baseURL.appendingPathComponent("movie").appendingPathComponent("play").appendingPathComponent(id)
        let posterURL = media.data.poster ?? .init(staticString: "https://eticketsolutions.com/demo/themes/e-ticket/img/movie.jpg")

        return Movie(title: media.data.title, webURL: url, posterURL: posterURL, year: media.data.year, sources: [.init(hostURL: hostURL )])

    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        let data = try await Utilities.requestData(url: url)
        let media = try JSONDecoder().decode(TVShowResponse.self, from: data)
        let id = url.lastPathComponent

        let playURL = baseURL.appendingPathComponent("tvshow").appendingPathComponent("play")
        guard var maxSeason = media.data.max_season else {
            throw MovieBoxProviderError.episodeURLNotFound
        }

        maxSeason = maxSeason < 1 ? 1 : maxSeason

        let seasons = try await (1...maxSeason).concurrentMap { seasonNumber in
            let seasonURL = baseURL.appendingPathComponent("tvshow").appendingPathComponent(id).appendingPathComponent(seasonNumber)
            let data = try await Utilities.requestData(url: seasonURL)
            let season = try JSONDecoder().decode(SeasonResponse.self, from: data)

            let ep = season.data.compactMap { ep -> Episode? in
                guard ep.source_file > 0 else { return nil }
                let hostURLs = playURL.appendingPathComponent(id).appendingPathComponent(seasonNumber).appendingPathComponent(ep.episode)
                return Episode(number: ep.episode, sources: [.init(hostURL: hostURLs)])
            }
            if ep.count > 0 {
                return Season(seasonNumber: seasonNumber, webURL: url, episodes: ep)
            } else {
                return nil
            }
        }.compactMap { $0 }
        let posterURL = media.data.poster ?? .init(staticString: "https://eticketsolutions.com/demo/themes/e-ticket/img/movie.jpg")
        return TVshow(title: media.data.title, webURL: url, posterURL: posterURL, year: media.data.year, seasons: seasons)
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let keyword = keyword.replacingOccurrences(of: " ", with: "-")
        let pageURL = baseURL.appendingPathComponent("search/\(keyword)")
        return try await parsePage(url: pageURL)
    }

    public func home() async throws -> [MediaContentSection] {
        let data = try await Utilities.requestData(url: homeURL)
        var response = try JSONDecoder().decode(HomeResponse.self, from: data).data
        response.removeFirst(2)
        var homeSections: [MediaContentSection] = response.compactMap {
            guard $0.box_type != 6, $0.list.count > 0 else { return nil }
            let media =  $0.list.map { row in
                let type: MediaContent.MediaContentType = row.boxType == 1 ? .movie :  .tvShow
                let url = baseURL.appendingPathComponent(type == .movie ? "movie" : "tvshow").appendingPathComponent(row.id)
                let posterURL = row.poster ?? .init(staticString: "https://eticketsolutions.com/demo/themes/e-ticket/img/movie.jpg")
                return MediaContent(title: row.title, webURL: url, posterURL: posterURL, type: type, provider: self.type)
            }
            return MediaContentSection(title: $0.name, media: media)
        }

        homeSections.insert(MediaContentSection(title: "Genres", media: [], categories: categories), at: 2)

        return homeSections
    }

    struct ListingResponse: Codable {
        let data: [Datum]
    }
    struct Datum: Codable {
        let id: Int
        let title: String
        let poster: URL?
        let boxType: Int
        let max_season: Int?
        let year: Int?
        enum CodingKeys: String, CodingKey {
            case id, title, poster
            case year
            case boxType = "box_type"
            case max_season = "max_season"

        }

        init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<MovieBoxProvider.Datum.CodingKeys> = try decoder.container(keyedBy: MovieBoxProvider.Datum.CodingKeys.self)

            self.id = try container.decode(Int.self, forKey: MovieBoxProvider.Datum.CodingKeys.id)
            self.title = try container.decode(String.self, forKey: MovieBoxProvider.Datum.CodingKeys.title)
            let posterPath = try container.decodeIfPresent(String.self, forKey: MovieBoxProvider.Datum.CodingKeys.poster)
            if let posterPath, let url = URL(string: posterPath) {
                self.poster = url
            } else {
                self.poster = nil
            }
            self.boxType = try container.decode(Int.self, forKey: MovieBoxProvider.Datum.CodingKeys.boxType)
            self.max_season = try container.decodeIfPresent(Int.self, forKey: MovieBoxProvider.Datum.CodingKeys.max_season)

            do {
                self.year = try container.decodeIfPresent(Int.self, forKey: MovieBoxProvider.Datum.CodingKeys.year)
            } catch {
                let sYear = try container.decodeIfPresent(String.self, forKey: MovieBoxProvider.Datum.CodingKeys.year)
                self.year = Int(sYear ?? "")
            }

        }

        func encode(to encoder: Encoder) throws {
            var container: KeyedEncodingContainer<MovieBoxProvider.Datum.CodingKeys> = encoder.container(keyedBy: MovieBoxProvider.Datum.CodingKeys.self)

            try container.encode(self.id, forKey: MovieBoxProvider.Datum.CodingKeys.id)
            try container.encode(self.title, forKey: MovieBoxProvider.Datum.CodingKeys.title)
            try container.encodeIfPresent(self.poster, forKey: MovieBoxProvider.Datum.CodingKeys.poster)
            try container.encode(self.boxType, forKey: MovieBoxProvider.Datum.CodingKeys.boxType)
            try container.encodeIfPresent(self.max_season, forKey: MovieBoxProvider.Datum.CodingKeys.max_season)
            try container.encodeIfPresent(self.year, forKey: MovieBoxProvider.Datum.CodingKeys.year)
        }

    }

    // MARK: - HomeResponse
    struct HomeResponse: Decodable {
        let msg: String
        let data: [HomeSection]
    }

    // MARK: - Datum
    struct HomeSection: Decodable {
        let name: String
        let box_type: Int
        @FailableDecodableArray var list: [Datum]

        enum CodingKeys: String, CodingKey {
            case name
            case box_type = "box_type"
            case list
        }

        init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<MovieBoxProvider.HomeSection.CodingKeys> = try decoder.container(keyedBy: MovieBoxProvider.HomeSection.CodingKeys.self)

            self.name = try container.decode(String.self, forKey: MovieBoxProvider.HomeSection.CodingKeys.name)
            self.box_type = try container.decode(Int.self, forKey: MovieBoxProvider.HomeSection.CodingKeys.box_type)
            self._list = try container.decode(FailableDecodableArray<MovieBoxProvider.Datum>.self, forKey: MovieBoxProvider.HomeSection.CodingKeys.list)

        }
    }

    // MARK: - Datum
    struct MovieResponse: Decodable {
        let data: Datum
    }

    struct TVShowResponse: Decodable {
        let data: Datum
    }
    struct SeasonResponse: Decodable {
        let data: [MEpisode]
    }

    struct MEpisode: Codable {
        let season, episode: Int
        let source_file: Int

        enum CodingKeys: String, CodingKey {
            case season, episode
            case source_file = "source_file"
        }
    }
}
