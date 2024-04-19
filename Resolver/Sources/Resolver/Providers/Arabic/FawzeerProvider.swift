import Foundation
import SwiftSoup

public class FawzeerProvider: Provider {
    public init() {}

    public let locale: Locale = Locale(identifier: "ar_SA")
    public let type: ProviderType = .init(.fawzeer)
    public let title: String = "Fawzeer"
    public let langauge: String = "🇸🇦"
    public let baseURL: URL = URL(staticString: "https://eldolary.com/ios/?api-key=7f8d4d6e-ppdt-7349-ikpb&v=kaster/")
    public var moviesURL: URL {
        baseURL
    }
    public var tvShowsURL: URL {
        baseURL
    }

    private var homeURL: URL {
        baseURL
    }

    enum CimaNowProviderError: Error {
        case missingMovieInformation
    }

    public func parsePage(url: URL) async throws -> [MediaContent] {
        return []
    }

    var _catalog: Catalog?
    func requestSplash() async throws -> Catalog {
        if let _catalog {
            return _catalog
        }

        let url = baseURL.appendingPathComponent("splash")
        let data = try await Utilities.requestData(url: url)
        let catalog = try JSONDecoder().decode(Catalog.self, from: data)
        self._catalog = catalog
        return catalog
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        if page > 1 {
            return []
        }
        let content = try await requestSplash()
        let cats = content.catAll.filter { !$0.title.contains("مسلسلات") && !$0.title.contains("رمضان") && !$0.title.contains("انمي")}.map { $0.id }
        return content.serAll.filter { cats.contains($0.ctg)}.map {
            let url = baseURL.appendingPathComponent("episodes").appendingQueryItem(name: "id", value: $0.id)
            return MediaContent(title: $0.title, webURL: url, posterURL: $0.portrait, type: .movie, provider: self.type)
        }
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        if page > 1 {
            return []
        }
        let content = try await requestSplash()
        let cats = content.catAll.filter { $0.title.contains("مسلسلات") || $0.title.contains("رمضان") || $0.title.contains("انمي")}.map { $0.id }
        return content.serAll.filter { cats.contains($0.ctg)}.map {
            let url = baseURL.appendingPathComponent("episodes").appendingQueryItem(name: "id", value: $0.id)
            return MediaContent(title: $0.title, webURL: url, posterURL: $0.portrait, type: .tvShow, provider: self.type)
        }
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        guard !url.absoluteString.contains("liveLink") else {
            let title = url.queryParameters?["name"] ?? ""
            let photoPath = url.queryParameters?["photo"] ?? ""
            let posterURL = try URL(photoPath)
            return Movie(
                title: title,
                webURL: url,
                posterURL: posterURL,
                sources: [Source(hostURL: url)]
            )
        }
        let data = try await Utilities.requestData(url: url)
        let content = try JSONDecoder().decode(DetailsResponse.self, from: data)
        let sourceURL = baseURL.appendingPathComponent("getLink").appendingQueryItem(name: "id", value: content.epiks.first?.id ?? "")
        return Movie(
            title: content.details.name,
            webURL: url,
            posterURL: content.details.portrait,
            sources: [Source(hostURL: sourceURL)]
        )
    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {

        let data = try await Utilities.requestData(url: url)
        let content = try JSONDecoder().decode(DetailsResponse.self, from: data)

        let episodes = content.epiks.map { ep -> Episode in
            let sourceURL = baseURL.appendingPathComponent("getLink").appendingQueryItem(name: "id", value: ep.id)
            return Episode(number: ep.sort, screenshot: ep.photo, sources: [Source(hostURL: sourceURL)])
        }
        let seasonNumber = content.details.name.replacingOccurrences(of: "[^0-9٠-٩]", with: "", options: .regularExpression)
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ar_SA")
        let englishSeasonNumber = formatter.number(from: seasonNumber)?.intValue  ?? 1
        let season = Season(seasonNumber: englishSeasonNumber, webURL: url, episodes: episodes)

        return TVshow(title: content.details.name,
                      webURL: url,
                      posterURL: content.details.portrait,
                      overview: content.details.overview,
                      seasons: [season]
        )

    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let keyword = keyword.lowercased().trimmingCharacters(in: .whitespaces)
        let content = try await requestSplash()
        let tv = content.catAll.filter { $0.title.contains("مسلسلات") || $0.title.contains("رمضان") || $0.title.contains("انمي")}.map { $0.id }
        return content.serAll.filter {$0.title.lowercased().contains(keyword)}.map {
            let url = baseURL.appendingPathComponent("episodes").appendingQueryItem(name: "id", value: $0.id)
            return MediaContent(title: $0.title, webURL: url, posterURL: $0.portrait, type: tv.contains($0.ctg) ? .tvShow : .movie, provider: self.type)
        }
    }
    public func home() async throws -> [MediaContentSection] {
        let content = try await requestSplash()
        let tv = content.catAll.filter { $0.title.contains("مسلسلات") || $0.title.contains("رمضان") || $0.title.contains("انمي")}.map { $0.id }

        var sections =  content.catAll.map { section in
            let media = content.serAll.filter { $0.ctg == section.id }.map {
                let url = baseURL.appendingPathComponent("episodes").appendingQueryItem(name: "id", value: $0.id)
                return MediaContent(title: $0.title, webURL: url, posterURL: $0.portrait, type: tv.contains($0.ctg) ? .tvShow : .movie, provider: self.type)
            }
            return MediaContentSection(title: section.title, media: media)
        }

        let url = baseURL.appendingPathComponent("live")
        let data = try await Utilities.requestData(url: url)
        let live = try JSONDecoder().decode(LiveResponse.self, from: data)
        let media = live.map {
            let sourceURL = baseURL.appendingPathComponent("liveLink")
                .appendingQueryItem(name: "id", value: $0.id)
                .appendingQueryItem(name: "name", value: $0.name)
                .appendingQueryItem(name: "photo", value: $0.photo.absoluteString)

            return MediaContent(title: $0.name, webURL: sourceURL, posterURL: $0.photo, type: .movie, provider: self.type)
        }

        sections.insert(.init(title: "Live", media: media), at: 1)
        return sections
    }

    struct LiveResponseElement: Codable {
        let id: Int
        let name: String
        let photo: URL

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case photo
        }
    }

    typealias LiveResponse = [LiveResponseElement]

    struct Catalog: Codable {
        let catAll: [CatAll]
        let banner: [Banner]
        let serAll: [Banner]

        enum CodingKeys: String, CodingKey {
            case catAll = "cat_all"
            case banner
            case serAll = "ser_all"
        }
    }

    // MARK: - Banner
    struct Banner: Codable {
        let id: Int
        let portrait: URL
        let ctg: Int
        let title: String

        enum CodingKeys: String, CodingKey {
            case id
            case portrait
            case ctg
            case title
        }
    }

    // MARK: - CatAll
    struct CatAll: Codable {
        let title: String
        let id: Int

        enum CodingKeys: String, CodingKey {
            case title
            case id
        }
    }

    // MARK: - DetailsResponse
    struct DetailsResponse: Codable {
        let epiks: [Epik]
        let details: Details

        enum CodingKeys: String, CodingKey {
            case epiks
            case details
        }
    }

    // MARK: - Details
    struct Details: Codable {
        let kind: String
        let clip: String
        let overview: String
        let stars: String
        let cat: Int
        let portrait: URL
        let name: String
        let id: Int

        enum CodingKeys: String, CodingKey {
            case kind
            case clip
            case overview
            case stars
            case cat
            case portrait
            case name
            case id
        }
    }

    // MARK: - Epik
    struct Epik: Codable {
        let id: Int
        let sort: Int
        let ser: Int
        let file: String
        let photo: URL
        let long: Int

        enum CodingKeys: String, CodingKey {
            case id
            case sort
            case ser
            case file
            case photo
            case long
        }
    }

}
