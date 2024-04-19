import Foundation
import SwiftSoup

public struct KinokisteProvider: Provider {
    public init() {}

    public let locale: Locale = Locale(identifier: "de_DE")
    public var type: ProviderType = .init(.kinokiste)

    public let title: String = "KinoKiste"
    public let langauge: String = "🇩🇪"

    private let moviesURL: URL = URL(staticString: "https://api.kinokiste.eu/data/browse/?lang=2&type=movies")
    private let tvShowsURL: URL = URL(staticString: "https://api.kinokiste.eu/data/browse/?lang=2&type=tvseries")
    private let baseURL = URL(staticString: "https://kinokiste.eu")
    private let posterBaseURL = URL(staticString: "https://image.tmdb.org/t/p/w342/")

    private enum KinokisteProviderError: Error {
        case idNotFound
    }
    private let decoder: JSONDecoder  = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let encodedDate = try container.decode(String.self)

            guard let date = DateCoder.decode(string: encodedDate) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported date format!")
            }

            return date
        }
        return decoder
    }()
    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.requestData(url: url)
        let response = try decoder.decode(KinoResponse.self, from: content)
        return response.movies.map { movie in
            let url = baseURL.appending("id", value: movie._id).appending("title", value: movie.original_title ?? movie.title)
            let title: String = movie.original_title ?? movie.title
            let posterURL = posterBaseURL.appendingPathComponent(movie.poster_path)
            let type: MediaContent.MediaContentType = movie.title.contains("Staffel") ? .tvShow :  .movie
            return MediaContent(title: title, webURL: url, posterURL: posterURL, type: type, provider: self.type)
        }
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appending("order_by", value: "releases").appending("page", value: String(page)))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appending("order_by", value: "releases").appending("page", value: String(page)))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        guard let _id = url.queryParameters?["id"] else {
            throw KinokisteProviderError.idNotFound
        }

        let requestURL = URL(staticString: "https://api.kinokiste.eu/data/watch/").appending("_id", value: _id)
        let content = try await Utilities.requestData(url: requestURL)
        let response = try decoder.decode(KinoDetails.self, from: content)
        let sources = response.streams.sorted {
            $0.added ?? Date() > $1.added ?? Date()
        }.prefix(20).compactMap { $0.stream }.map { Source(hostURL: $0)}
        let posterURL = posterBaseURL.appendingPathComponent(response.poster_path ?? "")
        return Movie(title: response.original_title ?? response.title, webURL: url, posterURL: posterURL, sources: Array(sources))

    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {

        // https://streamcloud.at/{id}/{original_title}
        guard let _id = url.queryParameters?["id"] else {
            throw KinokisteProviderError.idNotFound
        }

        let requestURL = URL(staticString: "https://api.kinokiste.eu/data/watch/").appending("_id", value: _id)
        let content = try await Utilities.requestData(url: requestURL)
        let response = try decoder.decode(KinoDetails.self, from: content)

        guard let original_title = response.original_title else {
            throw KinokisteProviderError.idNotFound
        }
        let seasonsURL = URL(staticString: "https://api.kinokiste.eu/data/seasons/?lang=2").appending("original_title", value: original_title)
        let seasonsData = try await Utilities.requestData(url: seasonsURL)

        let seasonsResponse = try decoder.decode(TVKinoDetailsResponse.self, from: seasonsData)

        let seasons = try await seasonsResponse.movies.concurrentMap { seasonResponse -> Season in
            // https://api.kinokiste.eu/pending_streams?_id=6492b18a0c897c64e6006212&lang=de
            let streamsURL = URL(staticString: "https://api.kinokiste.eu/pending_streams").appending("_id", value: seasonResponse._id)
            let steamData = try await Utilities.requestData(url: streamsURL)
            let streamResponse = try decoder.decode(TVKinoStreams.self, from: steamData)

            let episodesNumber = streamResponse.streams
                .compactMap { $0.e }

                .uniqued()

            let episodes = episodesNumber.map { ep -> Episode in
                let sources = streamResponse.streams.filter { $0.e == ep}.sorted {
                    $0.added ?? Date() > $1.added ?? Date()
                }.compactMap { $0.stream }.map { Source(hostURL: $0)}
                return Episode(number: ep, sources: sources)
            }
            return Season(seasonNumber: seasonResponse.s ?? 1, webURL: url, episodes: episodes)
        }.filter {
            ($0.episodes?.count ?? 0) > 0
        }

        let posterURL = posterBaseURL.appendingPathComponent(response.poster_path ?? "")
        return TVshow(title: response.original_title ?? response.title, webURL: url, posterURL: posterURL, seasons: seasons)
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let url = URL(staticString: "https://api.kinokiste.eu/data/browse/?lang=2")
            .appending("keyword", value: keyword.replacingOccurrences(of: " ", with: "+"))
            .appending("page", value: String(page))
        return try await parsePage(url: url)

    }

    public func home() async throws -> [MediaContentSection] {
        let trendingMovies =  try await parsePage(url: moviesURL.appending("order_by", value: "trending").appending("page", value: "1"))
        let trendingTVShows =  try await parsePage(url: tvShowsURL.appending("order_by", value: "trending").appending("page", value: "1"))
        return [.init(title: "Trending Filme", media: trendingMovies), .init(title: "Trending Serien", media: trendingTVShows)]
    }

    // MARK: - Welcome
    private struct KinoResponse: Decodable {
        @FailableDecodableArray var movies: [KinoMovie]
    }

    // MARK: - Movie
    private struct KinoMovie: Decodable {
        var _id: String
        var title: String
        var original_title: String?
        var poster_path: String
//        @FailableDecodableArray var streams: [KinoStream]
    }

    private struct KinoDetailsResponse: Decodable {
        @FailableDecodableArray var movies: [KinoDetails]

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.movies = try container.decode(FailableDecodableArray<KinoDetails>.self).wrappedValue
        }

    }

    private struct TVKinoDetailsResponse: Decodable {
        @FailableDecodableArray var movies: [TVKinoDetails]

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.movies = try container.decode(FailableDecodableArray<TVKinoDetails>.self).wrappedValue
        }

    }
    // MARK: - Welcome
    private struct KinoDetails: Decodable {
        var s: Int?
        var title: String
        var original_title: String?
        var poster_path: String?
        @FailableDecodableArray var streams: [KinoStream]

    }

    // MARK: - Welcome
    private struct TVKinoDetails: Decodable {
        var _id: String
        var s: Int?
        var title: String
        var original_title: String?
        var poster_path: String?
    }

    // MARK: - Welcome
    private struct TVKinoStreams: Decodable {
        @FailableDecodableArray var streams: [KinoStream]
    }

    // MARK: - Stream
    private struct KinoStream: Decodable {
        var stream: URL?
        var e: Int?
        var added: Date?

        private enum CodingKeys: String, CodingKey {
            case stream, e, added
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            stream = try container.decodeIfPresent(URL.self, forKey: .stream)
            added = try container.decodeIfPresent(Date.self, forKey: .added)

            if let eValue = try? container.decode(Int.self, forKey: .e) {
                e = eValue
            } else if let eString = try? container.decode(String.self, forKey: .e) {
                e = Int(eString)
            }
        }
    }

}
