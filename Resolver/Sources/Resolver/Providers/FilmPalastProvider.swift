import Foundation
import SwiftSoup

public struct FilmPalastProvider: Provider {
    public init() {}

    public let locale: Locale = Locale(identifier: "de_DE")
    public let type: ProviderType = .init(.filmPalast)
    public let title: String = "FilmPalast.so"
    public let langauge: String = "🇩🇪"

    public let baseURL: URL = URL(staticString: "https://filmpalast.to/")
    public var moviesURL: URL {
        baseURL.appendingPathComponent("movies/new/page")
    }
    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("serien/view/page")
    }
    private var homeURL: URL {
        baseURL
    }

    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select("article")
        return try rows.array().map { row in
            let path: String = try row.select("a").attr("href")
            let url = try URL("https:\(path)")
            let title: String = try row.select("h2").text()
            let posterPath: String = try row.select("a img").attr("src")
            let posterURL = baseURL.appendingPathComponent(posterPath)
            let type: MediaContent.MediaContentType
            let pattern = "S\\d+E\\d+"
            if let _ = title.range(of: pattern, options: .regularExpression) {
                type = .tvShow
            } else {
                type = .movie
            }
            return MediaContent(title: title, webURL: url, posterURL: posterURL, type: type, provider: .filmPalast)
        }
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appendingPathComponent(String(page)))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appendingPathComponent(String(page)))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let title = try document.select("h2").text().replacingOccurrences(of: "*ENGLISH*", with: "")
        let posterPath = try document.select("img[itemprop=image]").first()?.attr("src") ?? ""
        return Movie(title: title, webURL: url, posterURL: baseURL.appendingPathComponent(posterPath), sources: [.init(hostURL: url)])
    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {

        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let title = try document.select("h2").text().replacingOccurrences(of: "*ENGLISH*", with: "")
        let posterPath = try document.select("img[itemprop=image]").first()?.attr("src") ?? ""
        let seasons = try document.select(".staffelWrapperLoop").array().compactMap { season -> Season in
            var seasonNumber: Int = 1
            let episodes = try season.select("a.getStaffelStream").array().compactMap { episode -> Episode? in
                let episodeText: String = try episode.text()
                let episodePath: String = try episode.attr("href")
                let episodeURL = try URL("https:\(episodePath)")
                guard let seasonAndEp = extractSeasonAndEpisode(from: episodeText) else {
                    return nil
                }
                seasonNumber = seasonAndEp.season
                return Episode(number: seasonAndEp.episode, sources: [.init(hostURL: episodeURL)])
            }

            return Season(seasonNumber: seasonNumber, webURL: url, episodes: episodes)
        }

        return TVshow(title: removeSeasonAndEpisode(from: title), webURL: url, posterURL: baseURL.appendingPathComponent(posterPath), seasons: seasons)
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let keyword = keyword.encodeURIComponent()
        let pageURL = baseURL.appendingPathComponent("/search/title/\(keyword)")
        return try await parsePage(url: pageURL)
    }

    public func home() async throws -> [MediaContentSection] {
        let neu = try await parsePage(url: homeURL)
        let section1 = MediaContentSection(title: NSLocalizedString("Neu", comment: ""), media: neu)

        let top = try await parsePage(url: .init(staticString: "https://filmpalast.to/movies/top"))
        let section2 = MediaContentSection(title: NSLocalizedString("Top", comment: ""), media: top)

        let englisch = try await parsePage(url: .init("https://filmpalast.to/search/genre/Englisch/"))
        let section3 = MediaContentSection(title: NSLocalizedString("Englisch", comment: ""), media: englisch)

        return [section1, section2, section3]
    }

    func extractSeasonAndEpisode(from text: String) -> (season: Int, episode: Int)? {
        let pattern = "S(\\d+)E(\\d+)"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let seasonRange = Range(match.range(at: 1), in: text),
           let episodeRange = Range(match.range(at: 2), in: text) {
            let seasonNumber = Int(text[seasonRange]) ?? 1
            let episodeNumber = Int(text[episodeRange]) ?? 1
            return (seasonNumber, episodeNumber)
        }
        return nil
    }

    func removeSeasonAndEpisode(from text: String) -> String {
        let pattern = "S\\d+E\\d+"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            return regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
        }
        return text
    }
}
