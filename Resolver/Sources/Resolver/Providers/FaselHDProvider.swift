import Foundation
import SwiftSoup

public struct FaselHDProvider: Provider {
    public let locale: Locale = Locale(identifier: "ar_SA")
    public let type: ProviderType = .init(.faselHD)

    public let title: String = "FaselHD"
    public let langauge: String = "🇸🇦"

    public let baseURL: URL = URL(staticString: "https://faselhd.express/")
    public var moviesURL: URL {
        baseURL.appendingPathComponent("all-movies")
    }
    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("series")
    }
    private var homeURL: URL {
        baseURL
    }

    enum FaselHDProviderError: Error {
        case missingMovieInformation
        case errorLoadingHome
    }
    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select("div[class^=\"col-xl-2 col-lg-2\"]")
        return try rows.array().map { row in
            let content = try row.select("div.postDiv a")
            let url = try content.attr("href")
            let title: String = try content.select("div img").attr("alt")
            let posterPath: String = try content.select("div img").attr("data-src")
            let posterURL = try URL(posterPath)
            let webURL = try URL(url)
            let type: MediaContent.MediaContentType = title.contains("فيلم") ? .movie :  .tvShow
            return MediaContent(
                title: cleanTitle(title),
                webURL: webURL,
                posterURL: posterURL,
                type: type,
                provider: self.type
            )
        }
    }

    private func cleanTitle(_ title: String) -> String {
        return title
            .replacingOccurrences(of: "أنمي", with: "")
            .replacingOccurrences(of: "انمي", with: "")
            .replacingOccurrences(of: "مشاهدة", with: "")
            .replacingOccurrences(of: "مسلسل", with: "")
            .replacingOccurrences(of: "اون لاين", with: "")
            .replacingOccurrences(of: "مترجم", with: "")
            .replacingOccurrences(of: "فيلم", with: "")
            .replacingOccurrences(of: "برنامج", with: "")
            .replacingOccurrences(of: "الموسم الأول", with: "")
            .strip()
            .removingRegexMatches(pattern: "\\d{4}$", replaceWith: "")

    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appendingPathComponent("page").appendingPathComponent(page))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appendingPathComponent("page").appendingPathComponent(page))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        guard let posterPath = try document.select("div.posterImg img").first()?.attr("src"),
              let posterURL = URL(string: posterPath) else {
            throw FaselHDProviderError.missingMovieInformation
        }

        let fullTitle = try document.select("title")[0].text().replacingOccurrences(of: " - فاصل إعلاني", with: "")
        let title = cleanTitle(fullTitle)
        return Movie(title: title, webURL: url, posterURL: posterURL, sources: [Source(hostURL: url)])

    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)

        guard let posterPath = try document.select("img[data-src]").first()?.attr("data-src"),
              let posterURL = URL(string: posterPath) else {
            throw FaselHDProviderError.missingMovieInformation
        }

        let fullTitle = try document.select("title")[0].text().replacingOccurrences(of: " - فاصل إعلاني", with: "")
        let title = cleanTitle(fullTitle)

        let seasonsRows: Elements = try document.select(".seasonDiv ")
        let seasons = try await seasonsRows.array().enumerated().concurrentMap { (index, row) -> Season in
            let seasonNumber: Int = index + 1
            let onClick: String = try row.attr("onclick")
            let id = onClick.components(separatedBy: "p=").last ?? ""
            let seasonURL = url.appendingQueryItem(name: "p", value: id)

            let seasonContent = try await Utilities.downloadPage(url: seasonURL)
            let seasonDocument = try SwiftSoup.parse(seasonContent)
            let seasonsRows: Elements = try seasonDocument.select(".epAll a")
            let episodes = try seasonsRows.array().enumerated().map { (indexx, roww) -> Episode in
                let eposideNumber: Int = indexx + 1
                let path: String = try roww.attr("href")
                let url = try URL(path)
                return Episode(number: eposideNumber, sources: [Source(hostURL: url)])
            }.sorted()

            return Season(seasonNumber: seasonNumber, webURL: seasonURL, episodes: episodes)
        }

        return TVshow(title: title,
                      webURL: url,
                      posterURL: posterURL, seasons: seasons)
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let keyword = keyword.replacingOccurrences(of: " ", with: "+")
        let pageURL = baseURL.appending("s", value: keyword)
        return try await parsePage(url: pageURL)

    }

    public func home() async throws -> [MediaContentSection] {

        let content = try await Utilities.downloadPage(url: homeURL)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select("div[class^=\"col-xl-2 col-lg-2\"] .blockMovie")
        var items =  try rows.array().map { row in
            let url = try row.select("a").attr("href")
            let title: String = try row.select(".h5").text()
            let posterPath: String = try row.select("img").attr("data-src")
            let posterURL = try URL(posterPath)
            let webURL = try URL(url)
            let type: MediaContent.MediaContentType = title.contains("فيلم") ? .movie :  .tvShow
            return MediaContent(
                title: cleanTitle(title),
                webURL: webURL,
                posterURL: posterURL,
                type: type,
                provider: self.type
            )
        }

        guard items.count >= 36 else { throw FaselHDProviderError.errorLoadingHome }

        let recommendedMovies = MediaContentSection(title: NSLocalizedString("آخر الأفلام المضافة", comment: ""),
                                                    media: Array(items.prefix(12)))
        items.removeFirst(12)
        let recommendedTVShows = MediaContentSection(title: NSLocalizedString("آخر الحلقات الأسيوية المضافة", comment: ""),
                                                     media: Array(items.prefix(12)))
        items.removeFirst(12)
        let trending = MediaContentSection(title: NSLocalizedString("أفضل مسلسلات هذا الشهر", comment: ""),
                                           media: Array(items.prefix(12)))

        return [recommendedMovies, recommendedTVShows, trending]    }

}
