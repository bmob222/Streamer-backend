import Foundation
import SwiftSoup

public class StreamingCommunityProvider: Provider {
    public var locale: Locale {
        return Locale(identifier: "it_IT")
    }

    public enum StreamingCommunityProviderError: Error {
        case wrongURL
    }
    public var type: ProviderType = .local(id: .streamingcommunity)
    public let title: String = "StreamingCommunity"
    public let langauge: String = "🇮🇹"
    public var subtitle: String = ""
    public var moviesURL: URL {
        baseURL.appendingPathComponent("film")
    }
    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("serie-tv")
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

    @EnviromentValue(key: "streamingcommunity_url", defaultValue: URL(staticString: "https://streamingcommunity.estate"))
    public var baseURL: URL
    
    @EnviromentValue(key: "streamingcommunity_url_cdn", defaultValue: URL(staticString: "https://cdn.streamingcommunity.estate/images"))
    public var cdnBaseURL: URL
    public init() {}

    var _inhertia: String = ""

    func getInhertia() async throws {
        let page = try await Utilities.downloadPage(url: baseURL)
        let matches = page.matches(for: "version&quot;:&quot;(?<inertia>[a-z0-9]+)&quot;")
        _inhertia = matches.first ?? ""
    }

    public func parsePage(url: URL) async throws -> [MediaContent] {
        throw StreamingCommunityProviderError.wrongURL
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        if page > 3 {
            return []
        }
        try await getInhertia()
        let url = baseURL.appendingPathComponent("api/browse/latest")
        let headers = [
            "X-Inertia": "true",
            "Accept": "text/html, application/xhtml+xml",
            "X-Inertia-Version": _inhertia,
            "X-Requested-With": "XMLHttpRequest",
            "Referer": baseURL.absoluteString,
            "Content-Type": "application/json"
        ]

        let data = try await Utilities.requestData(
            url: url.appending("offset", value: String((page - 1)*60)),
            extraHeaders: headers
        )
        let response = try decoder.decode(Listing.self, from: data)
        return response.titles.filter {
            $0.type == .movie
        }.map {
            let webURL = baseURL.appendingPathComponent("titles").appendingPathComponent("\($0.id)-\($0.slug)")
            var posterURL = URL(staticString: "https://eticketsolutions.com/demo/themes/e-ticket/img/movie.jpg")
            if let posterName = $0.images.filter { $0.type == .poster }.first?.filename {
                posterURL = cdnBaseURL.appendingPathComponent(posterName)
            }
            return MediaContent(title: $0.name, webURL: webURL, posterURL: posterURL, type: .movie, provider: type)
        }
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        if page > 3 {
            return []
        }
        try await getInhertia()
        let url = baseURL.appendingPathComponent("api/browse/latest")
        let headers = [
            "X-Inertia": "true",
            "Accept": "text/html, application/xhtml+xml",
            "X-Inertia-Version": _inhertia,
            "X-Requested-With": "XMLHttpRequest",
            "Referer": baseURL.absoluteString,
            "Content-Type": "application/json"
        ]

        let data = try await Utilities.requestData(
            url: url.appending("offset", value: String((page - 1)*60)),
            extraHeaders: headers
        )
        let response = try decoder.decode(Listing.self, from: data)
        return response.titles.filter {
            $0.type == .tv
        }.map {
            // https://streamingcommunity.cz/titles/367-the-amazing-spider-man-2-il-potere-di-electro
            let webURL = baseURL.appendingPathComponent("titles").appendingPathComponent("\($0.id)-\($0.slug)")
            var posterURL = URL(staticString: "https://eticketsolutions.com/demo/themes/e-ticket/img/movie.jpg")
            if let posterName = $0.images.filter { $0.type == .poster }.first?.filename {
                posterURL = cdnBaseURL.appendingPathComponent(posterName)
            }
            return MediaContent(title: $0.name, webURL: webURL, posterURL: posterURL, type: .tvShow, provider: type)
        }
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        try await getInhertia()
        let headers = [
            "X-Inertia": "true",
            "Accept": "text/html, application/xhtml+xml",
            "X-Inertia-Version": _inhertia,
            "X-Requested-With": "XMLHttpRequest",
            "Referer": baseURL.absoluteString,
            "Content-Type": "application/json"
        ]

        let data = try await Utilities.requestData(
            url: url,
            extraHeaders: headers
        )
        let response = try decoder.decode(Details.self, from: data).props.title
        var posterURL = URL(staticString: "https://eticketsolutions.com/demo/themes/e-ticket/img/movie.jpg")
        var year: Int?

        if let posterName = response.images.filter { $0.type == .poster }.first?.filename {
            posterURL = cdnBaseURL.appendingPathComponent(posterName)
            if let lastAirDate = response.releaseDate {
                year = Calendar.current.component(.year, from: lastAirDate)
            }
        }

        return Movie(title: response.name, webURL: url, posterURL: posterURL, year: year, sources: [.init(hostURL: baseURL.appendingPathComponent("iframe").appendingPathComponent(response.id))])
    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        try await getInhertia()
        let headers = [
            "X-Inertia": "true",
            "Accept": "text/html, application/xhtml+xml",
            "X-Inertia-Version": _inhertia,
            "X-Requested-With": "XMLHttpRequest",
            "Referer": baseURL.absoluteString,
            "Content-Type": "application/json"
        ]

        let data = try await Utilities.requestData(
            url: url,
            extraHeaders: headers
        )
        let response = try decoder.decode(Details.self, from: data).props.title
        var posterURL = URL(staticString: "https://eticketsolutions.com/demo/themes/e-ticket/img/movie.jpg")
        var year: Int?

        if let posterName = response.images.filter { $0.type == .poster }.first?.filename {
            posterURL = cdnBaseURL.appendingPathComponent(posterName)
            if let lastAirDate = response.releaseDate {
                year = Calendar.current.component(.year, from: lastAirDate)
            }
        }

        let seasons = try await response.seasons.concurrentMap { season in
            let seasonUrl = url.appendingPathComponent("stagione-\(season.number)")
            try await self.getInhertia()
            let headers = [
                "X-Inertia": "true",
                "Accept": "text/html, application/xhtml+xml",
                "X-Inertia-Version": self._inhertia,
                "X-Requested-With": "XMLHttpRequest",
                "Referer": self.baseURL.absoluteString,
                "Content-Type": "application/json"
            ]

            let data = try await Utilities.requestData(
                url: seasonUrl,
                extraHeaders: headers
            )

            let seasonResponse = try self.decoder.decode(SeasonResponse.self, from: data)
            let episodes = seasonResponse.props.loadedSeason.episodes.map { episode in
                return Episode(
                    number: episode.number,
                    sources: [.init(
                        hostURL: self.baseURL.appendingPathComponent("iframe").appendingPathComponent(response.id).appending("episode_id", value: "\(episode.id)")
                    )]
                )
            } ?? []

            return Season(seasonNumber: season.number, webURL: url.appendingPathComponent(season.id), episodes: episodes)
        }

        return TVshow(title: response.name, webURL: url, posterURL: posterURL, year: year, seasons: seasons)
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        try await getInhertia()
        let url = baseURL.appendingPathComponent("search").appending("q", value: keyword)
        let headers = [
            "X-Inertia": "true",
            "Accept": "text/html, application/xhtml+xml",
            "X-Inertia-Version": _inhertia,
            "X-Requested-With": "XMLHttpRequest",
            "Referer": baseURL.absoluteString,
            "Content-Type": "application/json"
        ]

        let data = try await Utilities.requestData(
            url: url,
            extraHeaders: headers
        )
        let response = try decoder.decode(Search.self, from: data)
        return response.props.titles.map {
            let webURL = baseURL.appendingPathComponent("titles").appendingPathComponent("\($0.id)-\($0.slug)")
            var posterURL = URL(staticString: "https://eticketsolutions.com/demo/themes/e-ticket/img/movie.jpg")
            if let posterName = $0.images.filter { $0.type == .poster }.first?.filename {
                posterURL = cdnBaseURL.appendingPathComponent(posterName)
            }
            return MediaContent(title: $0.name, webURL: webURL, posterURL: posterURL, type: $0.type == .movie ? .movie : .tvShow, provider: type)
        }
    }

    public func home() async throws -> [MediaContentSection] {
        // app
        let pageContent = try await Utilities.downloadPage(url: baseURL)
        let document = try SwiftSoup.parse(pageContent)

        guard let data = try document.select("#app").attr("data-page").htmlUnescape().data(using: .utf8) else {
            return []
        }
        let response = try decoder.decode(HomeResponse.self, from: data)
        return response.props.sliders.map { section in

            let media = section.titles.map {
                // https://streamingcommunity.cz/titles/367-the-amazing-spider-man-2-il-potere-di-electro
                let webURL = baseURL.appendingPathComponent("titles").appendingPathComponent("\($0.id)-\($0.slug)")
                var posterURL = URL(staticString: "https://eticketsolutions.com/demo/themes/e-ticket/img/movie.jpg")
                if let posterName = $0.images.filter { $0.type == .poster }.first?.filename {
                    posterURL = cdnBaseURL.appendingPathComponent(posterName)
                }
                return MediaContent(title: $0.name, webURL: webURL, posterURL: posterURL, type: $0.type == .movie ? .movie : .tvShow, provider: type)
            }
            return MediaContentSection(title: section.label, media: media)
        }
    }
}

struct HomeResponse: Codable {
    let props: HomeProps

    enum CodingKeys: String, CodingKey {
        case props
    }
}

struct HomeProps: Codable {
    let sliders: [Slider]

    enum CodingKeys: String, CodingKey {
        case sliders
    }
}
struct Slider: Codable {
    let name: String
    let label: String
    let titles: [Title]

    enum CodingKeys: String, CodingKey {
        case name
        case label
        case titles
    }
}

// MARK: - Listing
struct Listing: Codable {
    let name: String
    let label: String
    let titles: [Title]

    enum CodingKeys: String, CodingKey {
        case name
        case label
        case titles
    }
}

// MARK: - Title
struct Title: Codable {
    let id: Int
    let slug: String
    let name: String
    let type: TitleType
    let subIta: Int
    let lastAirDate: Date?
    let seasonsCount: Int
    let images: [Image]

    enum CodingKeys: String, CodingKey {
        case id
        case slug
        case name
        case type
        case subIta = "sub_ita"
        case lastAirDate = "last_air_date"
        case seasonsCount = "seasons_count"
        case images
    }
}

// MARK: - Image
struct Image: Codable {
    let imageableID: Int
    let imageableType: ImageableType
    let filename: String
    let type: ImageType

    enum CodingKeys: String, CodingKey {
        case imageableID = "imageable_id"
        case imageableType = "imageable_type"
        case filename
        case type
    }
}

enum ImageableType: String, Codable {
    case title = "title"
}

enum ImageType: String, Codable {
    case background = "background"
    case cover = "cover"
    case coverMobile = "cover_mobile"
    case logo = "logo"
    case poster = "poster"
}

enum TitleType: String, Codable {
    case movie = "movie"
    case tv = "tv"
}

// MARK: - Search
struct Search: Codable {
    let props: Props

    enum CodingKeys: String, CodingKey {
        case props
    }
}

// MARK: - Props
struct Props: Codable {
    let titles: [Title]

    enum CodingKeys: String, CodingKey {
        case titles
    }
}

// MARK: - Details
struct Details: Codable {
    let props: DetailProps
}

// MARK: - Props
struct DetailProps: Codable {
    let title: PropsTitle

    enum CodingKeys: String, CodingKey {
        case title
    }
}

struct PropsTitle: Codable {
    let id: Int
    let name: String
    let slug: String
    let scwsID: Int?
    let releaseDate: Date?
    let seasonsCount: Int
    let seasons: [SSeason]
    let images: [Image]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case slug
        case scwsID = "scws_id"
        case releaseDate = "release_date"
        case seasonsCount = "seasons_count"
        case seasons
        case images
    }
}

struct SSeason: Codable {
    let id: Int
    let number: Int
    let episodes: [Episode]?
    let episodesCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case number
        case episodes
        case episodesCount = "episodes_count"
    }
}

// MARK: - Episode
struct SEpisode: Codable {
    let id: Int
    let number: Int

    enum CodingKeys: String, CodingKey {
        case id
        case number
    }
}

struct SeasonResponse: Codable {
    let props: SeasonProps

    enum CodingKeys: String, CodingKey {
        case props
    }
}

struct SeasonProps: Codable {
    let loadedSeason: LoadedSeason

    enum CodingKeys: String, CodingKey {
        case loadedSeason
    }
}
struct LoadedSeason: Codable {
    let id: Int
    let number: Int
    let episodes: [SEpisode]

    enum CodingKeys: String, CodingKey {
        case id
        case number
        case episodes
    }
}
