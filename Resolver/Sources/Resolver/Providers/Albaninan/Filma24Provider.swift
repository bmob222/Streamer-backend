import Foundation
import SwiftSoup

public class Filma24Provider: Provider {
    public init() {}

    public let type: ProviderType = .init(.filma24)

    public let title: String = "filma24.lol"
    public let langauge: String = ""

    public let baseURL: URL = URL(staticString: "https://www.filma24.lol")
    public var moviesURL: URL {
        baseURL
    }
    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("seriale")
    }
    public var homeURL: URL {
        baseURL
    }

    enum FilmaProviderError: Error {
        case missingMovieInformation
        case movieIDNotFound
        case invalidURL
    }
    // done
    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await  Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select(".movie-thumb.col-6")
        return try rows.array().compactMap { row -> MediaContent? in
            let path = try row.select(".movie-thumb.col-6 a").attr("href")
            let title: String = try row.select(".jt").attr("title")
            let posterPath: String = try row.select(".thumb").attr("src")

            guard let posterURL = URL(string: posterPath) else {
                return nil
            }
            let webURL = try URL(path)
            let type: MediaContent.MediaContentType = url.absoluteString.contains("seriale") ? .tvShow :  .movie
            return MediaContent(title: title, webURL: webURL, posterURL: posterURL, type: type, provider: self.type)
        }
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        let url = moviesURL.appendingPathComponent("page/\(page)/")
        return try await parsePage(url: url)
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        let url = tvShowsURL.appendingPathComponent("page/\(page)/")
        return try await parsePage(url: url)
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)

        let aioseoSchema = try pageDocument.select("script[type='application/ld+json']").first()?.html().data(using: .utf8)
        let filmDetails = try JSONDecoder().decode(FilmDetails.self, from: aioseoSchema!)

        let title = filmDetails.graph.first?.headline ?? ""
        let poster = filmDetails.graph.first?.image?.url ?? .init(staticString: "https://google.com")

        return Movie(title: title, webURL: url, posterURL: poster, sources: [Source(hostURL: url)])

    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)

        let title = try pageDocument.select(".category-head").text()
        let posterPath = try pageDocument.select("img").attr("src")
        guard let posterURL = URL(string: posterPath) else {
            throw FilmaProviderError.missingMovieInformation
        }

        // Parse each thumbnail to extract season and episode information
        let thumbnails = try pageDocument.select(".movie-thumb.col-6")
        var seasonsDict = [Int: [Episode]]()
        for thumb in thumbnails {
            let episodeLink = try thumb.select("a[href]").attr("href")
            let episodeInfo = try thumb.select(".under-thumb span").text().components(separatedBy: " ")
            if let seasonIndex = episodeInfo.firstIndex(where: { $0.lowercased().contains("sezoni") }),
               let episodeIndex = episodeInfo.firstIndex(where: { $0.lowercased().contains("episodi") }),
               let seasonNumber = Int(episodeInfo[seasonIndex + 1]),
               let episodeNumber = Int(episodeInfo[episodeIndex + 1]) {
                let episodeURL = URL(string: episodeLink, relativeTo: url)!
                let source = Source(hostURL: episodeURL)
                let episode = Episode(number: episodeNumber, sources: [source])

                seasonsDict[seasonNumber, default: []].append(episode)
            }
        }

        // Create season objects
        let seasons = seasonsDict.map { Season(seasonNumber: $0.key, webURL: url, episodes: $0.value.sorted(by: { $0.number < $1.number })) }

        return TVshow(title: title, webURL: url, posterURL: posterURL, seasons: seasons.sorted(by: { $0.seasonNumber < $1.seasonNumber }))
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let url = baseURL.appendingPathComponent("search/\(keyword)")
        return try await parsePage(url: url)

    }

    public func home() async throws -> [MediaContentSection] {
        let items = try await parsePage(url: homeURL)
        guard items.count >= 1 else {
            return []
        }
        let recommendedMovies = MediaContentSection(title: NSLocalizedString("FILMAT E FUNDIT", comment: ""),
                                                    media: Array(items.prefix(12)))
        let recommendedTVShows = MediaContentSection(title: NSLocalizedString("SERIALET E FUNDIT", comment: ""),
                                                     media: Array(items.prefix(12)))
        return [recommendedMovies, recommendedTVShows]

    }

    // MARK: - FilmDetails
    struct FilmDetails: Codable {
        let graph: [Graph]

        enum CodingKeys: String, CodingKey {
            case graph = "@graph"
        }
    }

    // MARK: - Graph
    struct Graph: Codable {
        let headline: String?
        let image: Image?

        enum CodingKeys: String, CodingKey {
            case headline = "headline"
            case image = "image"
        }
    }

    // MARK: - Image
    struct Image: Codable {
        let url: URL

        enum CodingKeys: String, CodingKey {
            case url = "url"
        }
    }

}
