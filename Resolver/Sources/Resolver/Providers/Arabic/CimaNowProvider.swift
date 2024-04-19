import Foundation
import SwiftSoup

public struct CimaNowProvider: Provider {
    public init() {}

    public let locale: Locale = Locale(identifier: "ar_SA")
    public let type: ProviderType = .init(.cimaNow)
    public let title: String = "CimaNow.cc"
    public let langauge: String = "🇸🇦"

    public let baseURL: URL = URL(staticString: "https://cimanow.cc/")
    public var moviesURL: URL {
        baseURL.appendingPathComponent("category/افلام-عربية/")
    }
    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("category/مسلسلات-عربية/")
    }

    private var homeURL: URL {
        baseURL.appendingPathComponent("home")
    }

    public var tvProgramURL: URL {
        baseURL.appendingPathComponent("category/برامج-التلفزيونية/")
    }

    enum CimaNowProviderError: Error {
        case missingMovieInformation
    }

    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.requestCloudFlare(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select("[aria-label=post]")
        return try rows.array().map { row in
            let content = try row.select("a")
            let url = try content.attr("href")
            let posterPath: String = try row.select("img").attr("data-src").addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed)!
            let posterURL = URL(string: posterPath)!
            let webURL = URL(string: url)!
            let title: String = try content.select("[aria-label=title]").html().components(separatedBy: "<em>").first ?? ""
            let type: MediaContent.MediaContentType = url.contains("%d9%81%d9%8a%d9%84%d9%85") ? .movie :  .tvShow
            return MediaContent(title: title, webURL: webURL, posterURL: posterURL, type: type, provider: self.type)
        }
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appendingPathComponent("page").appendingPathComponent("\(page)"))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appendingPathComponent("page").appendingPathComponent("\(page)"))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        let content = try await Utilities.requestCloudFlare(url: url)
        let document = try SwiftSoup.parse(content)

        guard let posterPath = try document.select("[property=og:image]").first()?.attr("content").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let posterURL = URL(string: posterPath) else {
            throw CimaNowProviderError.missingMovieInformation
        }
        let components = url.lastPathComponent.components(separatedBy: "-")
        let title = components.dropLast().dropFirst().joined(separator: " ")

        return Movie(title: title, webURL: url, posterURL: posterURL, sources: [Source(hostURL: url.appendingPathComponent("watching"))])

    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        let content = try await Utilities.requestCloudFlare(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select("#eps > li > a")
        let episodes = try rows.array().reversed().enumerated().map { (index, row) -> Episode in
            let path: String = try row.attr("href")
            let url = URL(string: path)!.appendingPathComponent("watching")
            let eposideNumber: Int = index + 1
            return Episode(number: eposideNumber, sources: [Source(hostURL: url)])
        }

        guard let posterPath = try document.select("[property=og:image]").first()?.attr("content").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let posterURL = URL(string: posterPath) else {
            throw CimaNowProviderError.missingMovieInformation
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        formatter.locale = .init(identifier: "ar_EG")

        let components = url.lastPathComponent.components(separatedBy: "-")
        let query = components.dropLast().dropFirst().joined(separator: " ")
        var seasonNumber: Int = 1
        if let season = components.last?.replacingOccurrences(of: "ج", with: "") {
            seasonNumber = Int(truncating: formatter.number(from: season) ?? 1)
        }
        let season = Season(seasonNumber: seasonNumber, webURL: url, episodes: episodes)
        let overview = try document.select("#details > li:nth-child(1) > p").text()
        return TVshow(title: query,
                      webURL: url,
                      posterURL: posterURL,
                      overview: overview,
                      seasons: [season])
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let moviesSearchURL = moviesURL.appendingPathComponent("page").appendingPathComponent("\(page)").appending("s", value: keyword)
        var searchResults =  try await parsePage(url: moviesSearchURL)
        let tvSearchURL = tvShowsURL.appendingPathComponent("page").appendingPathComponent("\(page)").appending("s", value: keyword)
        searchResults +=  try await parsePage(url: tvSearchURL)
        let tvshowsURL = tvProgramURL.appendingPathComponent("page").appendingPathComponent("\(page)").appending("s", value: keyword)
        searchResults +=  try await parsePage(url: tvshowsURL)
        return searchResults

    }

    public func home() async throws -> [MediaContentSection] {
        let content = try await Utilities.requestCloudFlare(url: homeURL)
        let document = try SwiftSoup.parse(content)
        let sectionRows: Elements = try document.select("section")
        return try sectionRows.array().compactMap { section -> MediaContentSection?  in
            let title = try section.select("span").text()
                .replacingOccurrences(of: "شاهد الكل", with: "")
                .replacingOccurrences(of: "جديد", with: "")
                .replacingOccurrences(of: "‹ ›", with: "")
                .strip()
            let rows: Elements = try section.select(".owl-body a")

            let media = try rows.array().compactMap { row -> MediaContent? in
                let content = try row.select("a")
                let url = try content.attr("href")
                let posterPath: String = try row.select("img").attr("data-src").addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed)!
                let posterURL = try URL(posterPath)
                let webURL = try URL(url)
                let title: String = try content.select("[aria-label=title]").html().components(separatedBy: "<em>").first?.strip() ?? ""
                let type: MediaContent.MediaContentType
                if url.contains("فيلم") {
                    type = .movie
                } else if url.contains("selary") {
                    type = .tvShow
                } else {
                    return nil
                }
                return MediaContent(title: title, webURL: webURL, posterURL: posterURL, type: type, provider: self.type)
            }
            if media.isEmpty {
                return nil
            } else {
                return MediaContentSection(title: title, media: media)
            }
        }

    }

}
