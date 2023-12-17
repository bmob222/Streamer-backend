import Foundation
import SwiftSoup

public struct ArabseedProvider: Provider {
    public init() {}

    public let locale: Locale = Locale(identifier: "ar_SA")
    public let type: ProviderType = .init(.arabseed)

    public let title: String = "ArabSeed"
    public let langauge: String = "🇸🇦"

    public let moviesURL: URL =  ArabseedProvider.baseURL
    public let tvShowsURL: URL = ArabseedProvider.baseURL
    public let baseURL: URL = ArabseedProvider.baseURL

    private let homeURL: URL = ArabseedProvider.baseURL.appendingPathComponent("main")

    @EnviromentValue(key: "arabseed_url", defaultValue: URL(staticString: "https://k5o.arabseed.ink"))
    static var baseURL: URL

    enum ArabseedProviderError: Error {
        case missingMovieInformation
    }

    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.downloadPage(url: url)
        return try parsePage(content: content)
    }

    private func parsePage(content: String, onlyType: MediaContent.MediaContentType? = nil) throws -> [MediaContent] {
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select(".MovieBlock")
        return try rows.array().compactMap { row -> MediaContent? in
            let category = try row.select(".BottomBar > .category").text()
            guard category.contains("افلام") || category.contains("مسلسل") || category.contains("برامج") else {
                return nil
            }

            let content = try row.select("a")
            let url = try content.attr("href")
            let title: String = try row.select("h4").text().replacingOccurrences(of: "فيلم", with: "").replacingOccurrences(of: "مترجم", with: "")
            var posterPath: String
            let poster1: String = try row.select("img.imgOptimzer").attr("data-image")
            if !poster1.isEmpty {
                posterPath = poster1
            } else {
                posterPath = try row.select(".Poster > img").attr("data-src")

            }
            guard let posterURL = try? URL(posterPath), let webURL = try? URL(url) else {
                return nil
            }
            let type: MediaContent.MediaContentType
            if category.contains("برامج") && title.contains("الحلقة") {
                type = .movie
            } else {
                type = category.contains("افلام") ? .movie :  .tvShow
            }
            if let onlyType, type != onlyType {
                return nil
            }
            return MediaContent(title: title, webURL: webURL, posterURL: posterURL, type: type, provider: self.type)
        }

    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        let url = Self.baseURL
            .appendingPathComponent("/category/arabic-movies-5")
            .appending(["page": String(page)])

        let content = try await Utilities.downloadPage(url: url)
        return try parsePage(content: content, onlyType: .movie)
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        let url = Self.baseURL
            .appendingPathComponent("category/arabic-series")
            .appending(["page": String(page)])
        let content = try await Utilities.downloadPage(url: url)
        return try parsePage(content: content, onlyType: .tvShow)
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)

        let title = try document.select(".InfoPartOne > h2").first()?
            .text()
            .replacingOccurrences(of: "فيلم", with: "")
            .replacingOccurrences(of: "مترجم", with: "")
            .replacingOccurrences(of: "فيديو: ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .dropLast(4)

        guard let posterPath = try document.select(".Poster img").first()?.attr("data-src").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let posterURL = URL(string: posterPath),
              let title = title else {
            throw ArabseedProviderError.missingMovieInformation
        }
        return Movie(title: String(title), webURL: url, posterURL: posterURL, sources: [Source(hostURL: url)])
    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {

        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let breadCrumbs = try document.select(".BreadCrumbs li").array()

        let lastBreadCrumb = try breadCrumbs[breadCrumbs.count-1].text()

        if lastBreadCrumb.contains("الحلقة") {
            let showPath = try breadCrumbs[breadCrumbs.count-2].select("a").attr("href")
            let showURL = try URL(showPath)
            return try await fetchTVShowDetails(for: showURL)
        }

        let title = lastBreadCrumb.replacingOccurrences(of: "مسلسل", with: "")
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        formatter.locale = .init(identifier: "ar_EG")
        let sesaonsEl: Elements = try document.select(".SeasonsListHolder li")
        var seasons: [Season] = []
        if sesaonsEl.array().count == 0 {
            let rows: Elements = try document.select(".ContainerEpisodesList a")
            let rowsCount = rows.array().count
            let episodes = try rows.array().enumerated().map { (index, row) -> Episode in
                let eposideNumber: Int = rowsCount - index
                let path: String = try row.attr("href")
                let url = try URL(path)
                return Episode(number: eposideNumber, sources: [Source(hostURL: url)])
            }.sorted()
            seasons = [Season(seasonNumber: 1, webURL: url, episodes: episodes)]
        } else {
            seasons = try await sesaonsEl.array().reversed().concurrentMap { element in
                let seasonId = try element.attr("data-season")
                let dataId = try element.attr("data-id")
                let payload = "season=\(seasonId)&post_id=\(dataId)".data(using: .utf8)
                let headers = [
                    "accept": "text/html, */*; q=0.01",
                    "accept-language": "en-US,en;q=0.9,ar;q=0.8",
                    "cache-control": "no-cache",
                    "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
                    "dnt": "1",
                    "origin": baseURL.absoluteString,
                    "pragma": "no-cache",
                    "referer": url.absoluteString,
                    "sec-ch-ua": "\"Not.A/Brand\";v=\"8\", \"Chromium\";v=\"114\", \"Google Chrome\";v=\"114\"",
                    "sec-ch-ua-mobile": "?0",
                    "sec-ch-ua-platform": "\"macOS\"",
                    "sec-fetch-dest": "empty",
                    "sec-fetch-mode": "cors",
                    "sec-fetch-site": "same-origin",
                    "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36",
                    "x-requested-with": "XMLHttpRequest"
                ]
                let contents = try await Utilities.downloadPage(
                    url: baseURL.appendingPathComponent("/wp-content/themes/Elshaikh2021/Ajaxat/Single/Episodes.php"),
                    httpMethod: "POST",
                    data: payload,
                    extraHeaders: headers
                )
                let seasonDoc = try SwiftSoup.parse(contents)
                let rows: Elements = try seasonDoc.select("a")
                let rowsCount = rows.array().count
                let episodes = try rows.array().enumerated().map { (index, row) -> Episode in
                    let eposideNumber: Int = rowsCount - index
                    let path: String = try row.attr("href")
                    let url = try URL(path)
                    return Episode(number: eposideNumber, sources: [Source(hostURL: url)])
                }.sorted()
                var seasonName = try element.text()

                seasonName = seasonName
                    .replacingOccurrences(of: "مترجم", with: "")
                    .replacingOccurrences(of: "الموسم", with: "")

                var seasonNumber: Int = 1
                if let seasonNumberInt = formatter.number(from: seasonName) {
                    seasonNumber = Int(truncating: seasonNumberInt)
                } else {
                    seasonNumber = 1
                }

                return Season(seasonNumber: seasonNumber, webURL: url, episodes: episodes)
            }
        }

        guard let posterPath = try document.select(".Poster  img").first()?.attr("data-lazy-src").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let posterURL = URL(string: posterPath) else {
            throw ArabseedProviderError.missingMovieInformation
        }

        let components = title.components(separatedBy: "الموسم")
        let query = components.dropLast().first ?? title

        return TVshow(title: query,
                      webURL: url,
                      posterURL: posterURL,
                      seasons: seasons)

    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        // let keyword = keyword.replace(" ", new: "+")
        let arabseedURL = try await Utilities.getRedirect(url: ArabseedProvider.baseURL)
        let searchURL = arabseedURL.appendingPathComponent("wp-content/themes/Elshaikh2021/Ajaxat/SearchingTwo.php")
        let payloadSeries = "search=\(keyword)&type=series"
        let contentSeries = try await Utilities.downloadPage(
            url: searchURL,
            httpMethod: "POST",
            data: payloadSeries.data(using: .utf8),
            extraHeaders: ["Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"]
        )
        let payloadMovies = "search=\(keyword)&type=movies"
        let contentMovies = try await Utilities.downloadPage(
            url: searchURL,
            httpMethod: "POST",
            data: payloadMovies.data(using: .utf8),
            extraHeaders: ["Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"]
        )

        let payloadAdvanced = "search=\(keyword)&type=advanced"
        let contentAdvanced = try await Utilities.downloadPage(
            url: searchURL,
            httpMethod: "POST",
            data: payloadAdvanced.data(using: .utf8),
            extraHeaders: ["Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"]
        )
        return try parsePage(content: contentMovies + contentSeries + contentAdvanced)

    }

    public func home() async throws -> [MediaContentSection] {
        let content = try await Utilities.downloadPage(url: homeURL)

        let document = try SwiftSoup.parse(content)
        let sectionRows: Elements = try document.select(".HomeSections .SectionMaster")
        let home =  try sectionRows.array().compactMap { section -> MediaContentSection?  in
            let title = try section.select(".rightTitleSection").text()
            let content = try section.select(".SlidesHold").html()
            let media = try parsePage(content: content)
            if media.isEmpty {
                return nil
            } else {
                return MediaContentSection(title: title, media: media.unique())
            }
        }

        let latestContent = try await Utilities.downloadPage(url: ArabseedProvider.baseURL.appendingPathComponent("latest1"))
        let media = try parsePage(content: latestContent)
        return [.init(title: "المضاف حديثًا", media: media)] + home

    }

}
