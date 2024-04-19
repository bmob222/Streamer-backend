import Foundation
import SwiftSoup

public struct WeCimaProvider: Provider {
    public init() {}

    public let locale: Locale = Locale(identifier: "ar_SA")
    public let type: ProviderType = .init(.wecima)
    public let title: String = "WeCima"
    public let langauge: String = "🇸🇦"

    @EnviromentValue(key: "wecima_baseURL", defaultValue: URL(staticString: "https://mycima.wecima.show/"))
    static public var baseURL: URL

    public var moviesURL: URL {
        Self.baseURL.appendingPathComponent("category/أفلام/افلام-عربي-arabic-movies/")
    }
    public var tvShowsURL: URL {
        Self.baseURL.appendingPathComponent("category/مسلسلات/مسلسلات-رمضان-2024/")
    }

    private var homeURL: URL {
        Self.baseURL
    }
    enum AkwamProviderError: Error {
        case missingMovieInformation
    }

    public var categories: [Category] = [
        .init(
            id: 1,
            name: "مسلسلات-هندية",
            url: baseURL.appendingPathComponent("category/%D9%85%D8%B3%D9%84%D8%B3%D9%84%D8%A7%D8%AA/9-series-indian-%D9%85%D8%B3%D9%84%D8%B3%D9%84%D8%A7%D8%AA-%D9%87%D9%86%D8%AF%D9%8A%D8%A9")
        ),
        .init(
            id: 2,
            name: "مسلسلات-اسيوية",
            url: baseURL.appendingPathComponent("category/%d9%85%d8%b3%d9%84%d8%b3%d9%84%d8%a7%d8%aa/%d9%85%d8%b3%d9%84%d8%b3%d9%84%d8%a7%d8%aa-%d8%a7%d8%b3%d9%8a%d9%88%d9%8a%d8%a9/")
        ),
        .init(
            id: 3,
            name: "مسلسلات-تركية",
            url: baseURL.appendingPathComponent("category/%d9%85%d8%b3%d9%84%d8%b3%d9%84%d8%a7%d8%aa/8-%d9%85%d8%b3%d9%84%d8%b3%d9%84%d8%a7%d8%aa-%d8%aa%d8%b1%d9%83%d9%8a%d8%a9-turkish-series/")
        ),
        .init(
            id: 4,
            name: "مسلسلات-وثائقية",
            url: baseURL.appendingPathComponent("category/%d9%85%d8%b3%d9%84%d8%b3%d9%84%d8%a7%d8%aa/%d9%85%d8%b3%d9%84%d8%b3%d9%84%d8%a7%d8%aa-%d9%88%d8%ab%d8%a7%d8%a6%d9%82%d9%8a%d8%a9-documentary-series/")
        ),
        .init(
            id: 7,
            name: "مسلسلات-كرتون",
            url: baseURL.appendingPathComponent("category/%d9%85%d8%b3%d9%84%d8%b3%d9%84%d8%a7%d8%aa-%d9%83%d8%b1%d8%aa%d9%88%d9%86/")
        ),
        .init(
            id: 8,
            name: "برامج-تليفزيونية",
            url: baseURL.appendingPathComponent("category/%d8%a8%d8%b1%d8%a7%d9%85%d8%ac-%d8%aa%d9%84%d9%8a%d9%81%d8%b2%d9%8a%d9%88%d9%86%d9%8a%d8%a9/")
        ),
        .init(
            id: 9,
            name: "افلام-اجنبي",
            url: baseURL.appendingPathComponent("category/%d8%a3%d9%81%d9%84%d8%a7%d9%85/10-movies-english-%d8%a7%d9%81%d9%84%d8%a7%d9%85-%d8%a7%d8%ac%d9%86%d8%a8%d9%8a/")
        ),
        .init(
            id: 10,
            name: "افلام-هندي",
            url: baseURL.appendingPathComponent("category/%d8%a3%d9%81%d9%84%d8%a7%d9%85/%d8%a7%d9%81%d9%84%d8%a7%d9%85-%d9%87%d9%86%d8%af%d9%8a-indian-movies/")
        ),
        .init(
            id: 11,
            name: "افلام-تركى",
            url: baseURL.appendingPathComponent("category/%d8%a3%d9%81%d9%84%d8%a7%d9%85/%d8%a7%d9%81%d9%84%d8%a7%d9%85-%d8%aa%d8%b1%d9%83%d9%89-turkish-films/")
        ),
        .init(
            id: 12,
            name: "افلام-وثائقية",
            url: baseURL.appendingPathComponent("category/%d8%a3%d9%81%d9%84%d8%a7%d9%85/%d8%a7%d9%81%d9%84%d8%a7%d9%85-%d9%88%d8%ab%d8%a7%d8%a6%d9%82%d9%8a%d8%a9-documentary-films/")
        ),
        .init(
            id: 13,
            name: "افلام-كرتون",
            url: baseURL.appendingPathComponent("category/%d8%a7%d9%81%d9%84%d8%a7%d9%85-%d9%83%d8%b1%d8%aa%d9%88%d9%86/")
        )
    ]

    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.downloadPage(url: url)
        return try await parsePage(content: content, query: ".Grid--WecimaPosts .GridItem")
    }

    func parsePage(content: String, query: String) async throws -> [MediaContent] {
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select(query)
        let content = try rows.array().compactMap { row -> MediaContent? in
            let content = try row.select("a")
            var url = try content.attr("href")
            if let tempURL = try? URL(url), let host1 = tempURL.host, let host2 = Self.baseURL.host {
                url = url.replacingOccurrences(of: host1, with: host2)
            }

            let posterPath: String = try content.select(".BG--GridItem").attr("data-lazy-style")
                .replacingOccurrences(of: "--image:url(", with: "")
                .replacingOccurrences(of: ");", with: "")
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

            var title: String = try row.select(".hasyear").text()
            let year: String = try row.select(".year").text()

            title = title.replacingOccurrences(of: "مسلسل", with: "")
            title = title.replacingOccurrences(of: "مشاهدة", with: "")
            title = title.replacingOccurrences(of: "فيلم", with: "")
            title = title.replacingOccurrences(of: "والاخيرة", with: "")
            title = title.replacingOccurrences(of: "مترجم", with: "")
            title = title.replacingOccurrences(of: "مدبلجة", with: "")
            title = title.replacingOccurrences(of: "مدبلج", with: "")
            title = title.replacingOccurrences(of: "موسم \\d+ حلقة \\d+", with: "", options: .regularExpression)
            title = title.replacingOccurrences(of: "حلقة \\d+", with: "", options: .regularExpression)

            title = title.replacingOccurrences(of: year, with: "").strip()
            if let webURL = URL(string: url) {
                let posterURL = URL(string: posterPath) ?? URL(staticString: "https://eticketsolutions.com/demo/themes/e-ticket/img/movie.jpg")
                let type: MediaContent.MediaContentType = url.contains("%d9%81%d9%8a%d9%84%d9%85") ? .movie :  .tvShow
                return MediaContent(title: title, webURL: webURL, posterURL: posterURL, type: type, provider: self.type)
            } else {
                return nil
            }
        }

        // remove duplicate content with the same title
        var uniqueContent: [MediaContent] = []
        for item in content {
            if !uniqueContent.contains(where: { $0.title == item.title }) {
                uniqueContent.append(item)
            }
        }
        return uniqueContent
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appendingPathComponent("page").appendingPathComponent(page))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appendingPathComponent("page").appendingPathComponent(page))
    }

    public func latestCategory(id: Int, page: Int) async throws -> [MediaContent] {
        guard let category = categories.first(where: { $0.id == id }), let url = category.url else {
            return []
        }
        return try await parsePage(url: url.appendingPathComponent("page").appendingPathComponent(page))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        let content = try await Utilities.downloadPage(url: url)
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
        var url = url
        var content = try await Utilities.downloadPage(url: url)
        var document = try SwiftSoup.parse(content)

        let breadCrumbs = try document.select("li[itemprop=itemListElement]").array()
        let lastBreadCrumb = try breadCrumbs[safe: breadCrumbs.count-1]?.text()
        if (lastBreadCrumb?.contains("موسم") == true || lastBreadCrumb?.contains("حلقة") == true ) && !url.absoluteString.contains("resolver=weciimaa") {
            let showPath = try breadCrumbs[3].select("a").attr("href")
            let showURL = try URL(showPath)
            url = showURL
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
                return Season(seasonNumber: index + 1, webURL: url.appending("resolver", value: "weciimaa"), episodes: episodes)
            }
            return Season(seasonNumber: index + 1, webURL: url.appending("resolver", value: "weciimaa"))
        }.sorted()

        if seasons.count == 0 {
            let epRows: Elements = try document.select(".Episodes--Seasons--Episodes a")
            let epRowsCount = epRows.array().count
            let episodes = try epRows.array().enumerated().map { (index, row) -> Episode in
                let path: String = try row.attr("href")
                let url = try URL(path)
                let episodeNumber = epRowsCount - index
                return Episode(number: episodeNumber, sources: [.init(hostURL: url.appending("resolver", value: "weciimaa"))])
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
        let pageURL = Self.baseURL
            .appendingPathComponent("AjaxCenter/Searching/")
            .appendingPathComponent(keyword)
        let data = try await Utilities.requestData(url: pageURL)
        let response = try JSONDecoder().decode(Response.self, from: data)
        return try await parsePage(content: response.output, query: ".GridItem")

    }
    struct Response: Codable {
        let output: String
    }

    public func home() async throws -> [MediaContentSection] {
        let content = try await Utilities.downloadPage(url: homeURL)
        let movies =  try await parsePage(content: content, query: ".Slider--Grid .GridItem")
        let tv =  try await parsePage(content: content, query: ".Grid--WecimaPosts .GridItem")
        let tvshows = MediaContentSection(title: "مسلسلات", media: [], categories: Array(categories[0...5]))
        let moviess = MediaContentSection(title: "افلام", media: [], categories: Array(categories[6...]))
        return [
            .init(title: "افلام جديدة", media: movies),
            .init(title: "جديد وى سيما", media: tv),
            tvshows,
            moviess

        ]
    }

}
