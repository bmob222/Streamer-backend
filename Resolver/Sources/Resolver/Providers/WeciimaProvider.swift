import Foundation
import SwiftSoup

public struct WeCimaProvider: Provider {
    public init() {}

    public let locale: Locale = Locale(identifier: "ar_SA")
    public let type: ProviderType = .init(.wecima)
    public let title: String = "WeCima"
    public let langauge: String = "🇸🇦"

    public let baseURL: URL = URL(staticString: "https://weciimaa.online/")
    public var moviesURL: URL {
        baseURL.appendingPathComponent("category/أفلام/افلام-عربي-arabic-movies/")
    }
    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("category/مسلسلات/13-مسلسلات-عربيه-arabic-series/")
    }

    private var homeURL: URL {
        baseURL
    }
    enum AkwamProviderError: Error {
        case missingMovieInformation
    }

    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.downloadPage(url: Utilities.workerURL(url))
        return try await parsePage(content: content, query: ".Grid--WecimaPosts .GridItem")
    }

    func parsePage(content: String, query: String) async throws -> [MediaContent] {
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select(query)
        return try rows.array().compactMap { row -> MediaContent? in
            let content = try row.select("a")
            let url = try content.attr("href")

            let posterPath: String = try content.select(".BG--GridItem").attr("data-lazy-style")
                .replacingOccurrences(of: "--image:url(", with: "")
                .replacingOccurrences(of: ");", with: "")
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

            var title: String = try row.select(".hasyear").text()
            var year: String = try row.select(".year").text()

            title = title.replacingOccurrences(of: "مسلسل", with: "")
            title = title.replacingOccurrences(of: "مشاهدة", with: "")
            title = title.replacingOccurrences(of: "فيلم", with: "")
            title = title.replacingOccurrences(of: "والاخيرة", with: "")
            title = title.replacingOccurrences(of: "مترجم", with: "")
            title = title.replacingOccurrences(of: "موسم \\d+ حلقة \\d+", with: "", options: .regularExpression)
            title = title.replacingOccurrences(of: year, with: "").strip()
            if let webURL = URL(string: url), let posterURL = URL(string: posterPath) {
                let type: MediaContent.MediaContentType = url.contains("%d9%81%d9%8a%d9%84%d9%85") ? .movie :  .tvShow
                return MediaContent(title: title, webURL: webURL, posterURL: posterURL, type: type, provider: self.type)
            } else {
                return nil
            }
        }

    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appendingPathComponent("page").appendingPathComponent(page))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appendingPathComponent("page").appendingPathComponent(page))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        let content = try await Utilities.downloadPage(url: Utilities.workerURL(url))
        let document = try SwiftSoup.parse(content)
        let posterPath = try document.select("wecima")
            .attr("data-lazy-style")
            .replacingOccurrences(of: "--img:url(", with: "")
            .replacingOccurrences(of: ");", with: "")
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let posterURL = try URL(posterPath)

        let yearElement = try document.select("a[href*=release-year]").first()
        let yearString = try yearElement?.text() ?? ""
        let year = Int(yearString) ?? 0

        let titleElement = try document.select("h1[itemprop=name]").first()
        var title = try titleElement?.text() ?? ""
        title = title.replacingOccurrences(of: "(\(year))", with: "").strip()

        return Movie(title: title, webURL: url, posterURL: posterURL, year: year, sources: [Source(hostURL: url.appending("resolver", value: "weciimaa"))])

    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        var content = try await Utilities.downloadPage(url: Utilities.workerURL(url))
        var document = try SwiftSoup.parse(content)

        let breadCrumbs = try document.select("li[itemprop=itemListElement]").array()
        let lastBreadCrumb = try breadCrumbs[breadCrumbs.count-1].text()
        if lastBreadCrumb.contains("موسم") || lastBreadCrumb.contains("حلقة") {
            let showPath = try breadCrumbs[3].select("a").attr("href")
            let showURL = try URL(showPath)
            content = try await Utilities.downloadPage(url: showURL)
            document = try SwiftSoup.parse(content)
        }

        let seasonsRows: Elements = try document.select(".List--Seasons--Episodes a")
        var seasons = try seasonsRows.array().enumerated().map { (index, row) -> Season in
            let path: String = try row.attr("href")
            let url = try URL(path)
            if try row.className() == "selected" {
                let epRows: Elements = try document.select(".Episodes--Seasons--Episodes a")
                let epRowsCount = epRows.array().count
                let episodes = try epRows.array().enumerated().map { (index, row) -> Episode in
                    let path: String = try row.attr("href")
                    let url = try URL(path)
                    let episodeNumber = epRowsCount - index
                    return Episode(number: episodeNumber, sources: [.init(hostURL: url.appending("resolver", value: "weciimaa"))])
                }.sorted()
                return Season(seasonNumber: index + 1, webURL: url, episodes: episodes)
            }
            return Season(seasonNumber: index + 1, webURL: url)
        }.sorted()

        if seasons.count == 0 {
            let epRows: Elements = try document.select(".Episodes--Seasons--Episodes a")
            let epRowsCount = epRows.array().count
            let episodes = try epRows.array().enumerated().map { (index, row) -> Episode in
                let path: String = try row.attr("href")
                let url = try URL(path)
                let episodeNumber = epRowsCount - index
                return Episode(number: episodeNumber, sources: [.init(hostURL: url)])
            }.sorted()
            seasons.append(Season(seasonNumber: 1, webURL: url, episodes: episodes))
        }

        let posterPath = try document.select("wecima").attr("style")
            .replacingOccurrences(of: "--img:url(", with: "")
            .replacingOccurrences(of: ");", with: "")
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let posterURL = try URL(posterPath)

        let yearElement = try document.select("a[href*=release-year]").first()
        let yearString = try yearElement?.text() ?? ""
        let year = Int(yearString) ?? 0

        let titleElement = try document.select("h1").first()
        var title = try titleElement?.text() ?? ""
        title = title.replacingOccurrences(of: "(\(year))", with: "").strip()

        return TVshow(title: title, webURL: url, posterURL: posterURL, year: year, seasons: seasons)

    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let pageURL = baseURL
            .appendingPathComponent("AjaxCenter/Searching/")
            .appendingPathComponent(keyword)
        let data = try await Utilities.requestData(url: Utilities.workerURL(pageURL))
        let response = try JSONDecoder().decode(Response.self, from: data)
       return try await parsePage(content: response.output, query: ".GridItem")

    }
    struct Response: Codable {
        let output: String
    }

    public func home() async throws -> [MediaContentSection] {
        let content = try await Utilities.downloadPage(url: Utilities.workerURL(homeURL))
        let movies =  try await parsePage(content: content, query: ".Slider--Grid .GridItem")
        let tv =  try await parsePage(content: content, query: ".Grid--WecimaPosts .GridItem")

        return [
            .init(title: "افلام جديدة", media: movies),
            .init(title: "جديد وى سيما", media: tv)

        ]
    }

}
