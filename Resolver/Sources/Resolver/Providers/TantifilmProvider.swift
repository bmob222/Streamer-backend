import Foundation
import SwiftSoup
// https://www.tantifilm.farm/serie-tv/
public class TantifilmProvider: Provider {
    public let locale: Locale = Locale(identifier: "it_IT")
    public init() {}
    enum TantifilmError: Error {
        case invalidIframeURL, posterURLIsNil, parsingError
    }
    public let type: ProviderType = .init(.tantifilm)
    public let title: String = "Tantifilm"
    public let langauge: String = "🇮🇹"
    public let baseURL: URL = URL(staticString: "https://www.tantifilm.farm")
    public var moviesURL: URL {
        baseURL.appendingPathComponent("film-1")
    }
    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("serie-tv")
    }
    public var homeURL: URL {
        baseURL
    }
    public var categories: [Category] = [
        .init(id: 1, name: "Ultimi Film Aggiornati", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/film-aggiornati")),
        .init(id: 2, name: "3D", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/3d")),
        .init(id: 3, name: "Al Cinema", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/al-cinema")),
        .init(id: 4, name: "HD AltaDefinizione", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/altadefinizione")),
        .init(id: 5, name: "Serie TV Altadefinizione", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/serie-altadefinizione")),
        .init(id: 6, name: "Sub-ITA", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/sub-ita")),
        .init(id: 7, name: "Anime", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/anime")),
        .init(id: 8, name: "Azione", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/azione")),
        .init(id: 9, name: "Avventura", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/avventura")),
        .init(id: 10, name: "Avventura Fantasy", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/avventura-fantasy")),
        .init(id: 11, name: "Biografico", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/biografico")),
        .init(id: 12, name: "Cartoni Animati", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/cartoni-animati")),
        .init(id: 13, name: "Comico", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/comico")),
        .init(id: 14, name: "Commedia", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/commedia")),
        .init(id: 15, name: "Documentari", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/documentari")),
        .init(id: 16, name: "Drammatico", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/drammatico")),
        .init(id: 17, name: "Erotici", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/erotici")),
        .init(id: 18, name: "Fantascienza", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/fantascienza")),
        .init(id: 19, name: "Gangster", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/gangster-1")),
        .init(id: 20, name: "Giallo", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/giallo")),
        .init(id: 21, name: "Grottesco", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/grotesto")),
        .init(id: 22, name: "Guerra", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/guerra")),
        .init(id: 23, name: "Musicale", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/musicale")),
        .init(id: 24, name: "Noir", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/noir")),
        .init(id: 25, name: "Poliziesco", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/poliziesco")),
        .init(id: 26, name: "Horror", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/horror")),
        .init(id: 27, name: "Romantico", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/romantico")),
        .init(id: 28, name: "Sportivo", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/sportivo")),
        .init(id: 29, name: "Storico", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/storico")),
        .init(id: 30, name: "Thriller", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/thriller-1")),
        .init(id: 31, name: "Western", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/western")),
        .init(id: 32, name: "Serie TV", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/serie-tv")),
        .init(id: 33, name: "Miniserie", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/miniserie-1")),
        .init(id: 34, name: "Programmi Tv", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/programmi-tv")),
        .init(id: 35, name: "Live", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/live")),
        .init(id: 36, name: "Trailers", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/trailers")),
        .init(id: 37, name: "Serie TV Aggiornate", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/series-tv-featured")),
        .init(id: 38, name: "Aggiornamenti", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/recommended")),
        .init(id: 39, name: "Featured", url: URL(staticString: "https://www.tantifilm.farm/watch-genre/featured"))
    ]

    private func parsePage(url: URL, div: String = "#main_col .media3") async throws -> [MediaContent] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        var type: MediaContent.MediaContentType = .movie
        let rows: Elements = try document.select(div)

        if let pageTitle = try document.select("title").first(), try pageTitle.text().contains("Film") {
            type = .movie
        } else {
            type = .tvShow
        }

        return try rows.array().map { row in
            if try row.classNames().contains("genre-serie-tv") {
                type = .tvShow
            }
            if try row.classNames().contains("genre-film-aggiornati") {
                type = .movie
            }
            let path: String = try row.select("a").attr("href")
            let url: URL
            if path.hasPrefix("https") {
                url = try URL(path)
            } else {
                url = baseURL.appendingPathComponent(path)
            }

            var title: String = try row.select(".title-film").text()
            if title.isEmpty {
                title = try row.select("img").attr("alt")
            }
            let posterPath: String = try row.select("img").attr("src").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let posterURL = try URL(posterPath)
            return MediaContent(title: cleanTitle(title), webURL: url, posterURL: posterURL, type: type, provider: self.type)
        }
    }

    public func latestCategory(id: Int, page: Int) async throws -> [MediaContent] {
        guard let category = categories.first(where: { $0.id == id }), let url = category.url else {
            return []
        }
        return try await parsePage(url: url.appending("page", value: String(page)))
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

        let title = try document.select("title").text()
        let posterPath = try document.select("meta[property=og:image]").attr("content")
        let movieIframe = try document.select("iframe").attr("src")

        let posterURL = try URL(posterPath)
        let protectedLink = try URL(movieIframe)
        let source: Source = Source(hostURL: protectedLink)

        return Movie(title: cleanTitle(title), webURL: url, posterURL: posterURL, sources: [source])
    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        // Fetch and parse the main page
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)

        // Extracting title and poster URL from the main page
        let title = try pageDocument.select("title").text()
        let posterPath = try pageDocument.select("meta[property=og:image]").attr("content")
        let posterURL = try URL(posterPath)

        // Extracting iframe URL from the main page
        let iframeURL = try pageDocument.select("iframe").attr("src")
        let requestUrl = try URL(iframeURL)
        // Fetch and parse the iframe content to get the list of episodes
        let iframeContent = try await Utilities.downloadPage(url: requestUrl)
        let iframeDocument = try SwiftSoup.parse(iframeContent)
        let seasons = try await iframeDocument.select(".nav1 .navbar-nav a").array().concurrentMap { selement -> Season? in

            let spath = try selement.attr("href").strip()
            let seasonsText = try selement.text()
            let season = Int(seasonsText) ?? 1
            let sURL = try URL(spath)
            let sContent = try await Utilities.downloadPage(url: sURL)
            let sDocument = try SwiftSoup.parse(sContent)

            let episodes = try sDocument.select(".second_nav > ul.nav.navbar-nav > li.dropdown").array().compactMap { element -> Episode? in
                let episodeLinkTag = try element.select("a").first()
                guard let numberString = try episodeLinkTag?.text().trimmingCharacters(in: .whitespacesAndNewlines),
                      let episodeNumber = Int(numberString),
                      let episodeURLString = try episodeLinkTag?.attr("href"),
                      let episodeURL = URL(string: episodeURLString) else {
                    return nil
                }
                let source = Source(hostURL: episodeURL)
                return Episode(number: episodeNumber, sources: [source])
            }.sorted()

            return Season(seasonNumber: season, webURL: sURL, episodes: episodes)
        }.compactMap { $0 }
        return TVshow(title: cleanTitle(title), webURL: url, posterURL: posterURL, seasons: seasons)
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let url = baseURL.appending("s", value: keyword)
        return try await parsePage(url: url, div: ".search_post")
    }

    public func home() async throws -> [MediaContentSection] {
        let movies = try await parsePage(url: moviesURL, div: ".col")
        let tvshow = try await parsePage(url: tvShowsURL, div: ".col")
        return [
            .init(title: "", categories: categories),
            .init(title: "Film", media: movies),
            .init(title: "Serie TV", media: tvshow)
        ]
    }
}

private extension TantifilmProvider {

    private struct Response: Codable {
        let html: String
    }

    func cleanTitle(_ title: String) -> String {
        return title.replacingOccurrences(of: "streaming", with: "")
            .replacingOccurrences(of: "streaming", with: "")
            .replacingOccurrences(of: "– Serie TV", with: "")
            .replacingOccurrences(of: "| Tantifilm", with: "")
            .removingRegexMatches(pattern: "\\(\\d{4}-\\d{4}\\)", replaceWith: "") // (2022-20023)
            .removingRegexMatches(pattern: "\\(\\d{4}-\\)", replaceWith: "") // (2022-)
            .removingRegexMatches(pattern: "\\(\\d{4}\\)", replaceWith: "") // (2022)
            .strip()
            .components(separatedBy: " – ")
            .last?.strip() ?? ""
    }
}
