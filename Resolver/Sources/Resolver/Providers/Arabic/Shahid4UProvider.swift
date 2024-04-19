import Foundation
import SwiftSoup

public struct Shahid4UProvider: Provider {
    public init() {}

    public let locale: Locale = Locale(identifier: "ar_SA")
    public let type: ProviderType = .init(.shahid4u)
    public let title: String = "Akwam.us"
    public let langauge: String = "🇸🇦"

    public let baseURL: URL = URL(staticString: "https://shahee4u.cam")
    public var moviesURL: URL {
        baseURL.appendingPathComponent("category/افلام-عربي")
    }
    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("category/مسلسلات-رمضان-2024")
    }

    private var homeURL: URL {
        baseURL.appendingPathComponent("one")
    }

    enum AkwamProviderError: Error {
        case missingMovieInformation
    }

    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.downloadPage(url: Utilities.workerURL(url))
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select(".shows-container > div")
        return try rows.array().map { row in
            let content = try row.select("a")
            let url = try content.attr("href").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let title: String = try row.select(".title").text()
            let posterPath: String = try content.attr("style").replacingOccurrences(of: "background-image: url(", with: "").replacingOccurrences(of: "); --br: 10px;", with: "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let posterURL = try URL(posterPath)
            let webURL = try URL(url)
            let type: MediaContent.MediaContentType = url.contains("/episode/") ? .tvShow :  .movie
            return MediaContent(title: title, webURL: webURL, posterURL: posterURL, type: type, provider: self.type)
        }.uniqued()
    }

    private func cleanTitle(_ title: String) -> String {
        return title
            .replacingOccurrences(of: "أنمي", with: "")
            .replacingOccurrences(of: "انمي", with: "")
            .replacingOccurrences(of: "مشاهدة", with: "")
            .replacingOccurrences(of: "مسلسل", with: "")
            .replacingOccurrences(of: "اون لاين", with: "")
            .replacingOccurrences(of: "مترجم", with: "")
            .replacingOccurrences(of: "مدبلجة", with: "")
            .replacingOccurrences(of: "مدبلج", with: "")
            .replacingOccurrences(of: "فيلم", with: "")
            .replacingOccurrences(of: "برنامج", with: "")
            .replacingOccurrences(of: "الموسم الأول", with: "")
            .strip()
            .removingRegexMatches(pattern: "\\d{4}$", replaceWith: "")
            .removingRegexMatches(pattern: "الموسم .+", replaceWith: "")
            .removingRegexMatches(pattern: "الحلقة \\d+ .+", replaceWith: "")
            .strip()

    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appending("page", value: String(page)))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appending("page", value: String(page)))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        let content = try await Utilities.downloadPage(url: Utilities.workerURL(url))
        let document = try SwiftSoup.parse(content)
        let posterPath = try document.select(".poster").attr("style").replacingOccurrences(of: "--background-image-url: url(", with: "").replacingOccurrences(of: ")", with: "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let posterURL = try URL(posterPath)
        let title  = try document.select(".info-side .title").text()
        // https://shahee4u.cam/watch/%D9%81%D9%8A%D9%84%D9%85-%D9%82%D8%B5%D8%A9-%D8%AD%D8%A8-2019
        let sourcePath = url.absoluteString.replace("film", new: "watch")
        let sourceURL = try URL(sourcePath)
        return Movie(title: cleanTitle(title), webURL: url, posterURL: posterURL, sources: [Source(hostURL: sourceURL)])
    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        var url = url
        var content = try await Utilities.downloadPage(url: Utilities.workerURL(url))
        var document = try SwiftSoup.parse(content)

        let breadCrumbs = try document.select("nav a").array()
        let lastBreadCrumb = try breadCrumbs.last?.text()
        if (lastBreadCrumb?.contains("موسم") == true || lastBreadCrumb?.contains("حلقة") == true ) && !url.absoluteString.contains("resolver=weciimaa") {
            let showPath = try breadCrumbs[2].attr("href").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let showURL = try URL(showPath)
            url = showURL
            content = try await Utilities.downloadPage(url: Utilities.workerURL(showURL))
            document = try SwiftSoup.parse(content)
        }

        let posterPath = try document.select(".poster").attr("style").replacingOccurrences(of: "--background-image-url: url(", with: "").replacingOccurrences(of: ")", with: "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let posterURL = try URL(posterPath)
        let title  = try document.select(".info-side .title").text()
        let seasonsRows: Elements = try document.select("a[href*=season/]")
        let seasons = try await seasonsRows.array().map { row in
            let path = try row.attr("href").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let seasonURL = path.startswith("https") ? try URL(path) : baseURL.appendingPathComponent(path)
            let seasonNumber = try row.select("span.fs-2").text()
            return Season(seasonNumber: Int(seasonNumber) ?? 1, webURL: seasonURL, episodes: [])
        }.concurrentMap { season in
            let c = try await Utilities.downloadPage(url: Utilities.workerURL(season.webURL))
            let d = try SwiftSoup.parse(c)
            let episodesRows: Elements = try d.select("a[href*=episode/]")
            let episodes = try episodesRows.array().enumerated().map { (index, row) -> Episode in
                let eposideNumber: Int = index + 1
                let path: String = try row.attr("href").replace("episode", new: "watch").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                let url = path.startswith("https") ? try URL(path) : baseURL.appendingPathComponent(path)
                return Episode(number: eposideNumber, sources: [Source(hostURL: url)])
            }
            .sorted()
            return Season(seasonNumber: season.seasonNumber, webURL: season.webURL, episodes: episodes)
        }

        return TVshow(title: cleanTitle(title),
                      webURL: url,
                      posterURL: posterURL,
                      seasons: seasons)

    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let keyword = keyword.replacingOccurrences(of: " ", with: "+")
        let pageURL = baseURL.appendingPathComponent("search")
            .appending("page", value: "\(page)")
            .appending("s", value: keyword)
        return try await parsePage(url: pageURL)

    }

    public func home() async throws -> [MediaContentSection] {
        let media = try await parsePage(url: baseURL)

        let sections =
        [
            "برامج-تلفزيونية",
            "مسلسلات-عربي",
            "افلام-عربي"
        ]

        let mediaSections = try await sections.concurrentMap { title in
            let url = baseURL.appendingPathComponent("category").appendingPathComponent(title)
            let media = try await parsePage(url: url)
            return MediaContentSection(title: title, media: media)

        }
        return [.init(title: "الأحدث", media: media)] + mediaSections
    }

}
