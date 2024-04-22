import Foundation
import SwiftSoup
// https://www.tanti.icu/serie-tv/
public class TantifilmProvider: Provider {
    public init() {}

    enum TantifilmError: Error {
        case missingFirstEpURL
        case embedLinkMissing
    }
    public let type: ProviderType = .init(.tantifilm)
    public let title: String = "tantifilm"
    public let langauge: String = "🇮🇹"
    public let baseURL: URL = URL(staticString: "https://www.tanti.icu")
    public var moviesURL: URL {
        baseURL.appendingPathComponent("film-1")
    }
    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("serie-tv")
    }
    public var homeURL: URL {
        baseURL
    }

    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select(".list-movie")

        return try rows.array().map { row in
            let path: String = try row.select("a").attr("href")
            let url = try URL(path)

            let year: String = try row.select(".list-year").text()
            let title: String = try row.select(".list-title").text().replacingOccurrences(of: year, with: "").strip()
            let posterPath: String = try row.select(".media-cover").attr("data-src")
            let posterURL = try URL(posterPath)
            let type: MediaContent.MediaContentType = path.contains("guarda") ? .movie : .tvShow
            return MediaContent(title: title, webURL: url, posterURL: posterURL, type: type, provider: self.type)
        }
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appending(["page": String(page)]))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appending(["page": String(page)]))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)

        let posterPath = try document.select("meta[property=og:image]").attr("content")
        let posterURL = try URL(posterPath)
        let title = try document.select(".breadcrumb-item").array().last?.text() ?? ""

        var year: Int?
        if let yearText = try document.select(".video-attr").array().filter({ try $0.text().contains("Data")}).first?.select(".text").text() {
            year = Int(yearText)
        }

        let dataId = try document.select("[data-embed]").attr("data-embed")
        let sourceURL = URL(staticString: "https://www.tanti.icu/ajax/embed").appending(["data-embed": dataId])
        let data = ("id=" + dataId).data(using: .utf8) ?? Data()
        let headers = [
            "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
            "Accept": "*/*",
            "Referer": url.absoluteString,
            "X-Requested-With": "XMLHttpRequest"
        ]

        let embedResponse = try await Utilities.downloadPage(url: sourceURL, httpMethod: "POST", data: data, extraHeaders: headers)
        guard let embed = Utilities.extractURLs(content: embedResponse).first else {
            throw TantifilmError.embedLinkMissing
        }
        return Movie(title: title, webURL: url, posterURL: posterURL, year: year, sources: [.init(hostURL: embed)])
    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)

        guard let firstEpPath = try pageDocument.select(".episodes a").array().first?.attr("href"), let firstEpURL = URL(string: firstEpPath)  else {
            throw TantifilmError.missingFirstEpURL
        }

        let content = try await Utilities.downloadPage(url: firstEpURL)
        let document = try SwiftSoup.parse(content)

        let posterPath = try document.select("meta[property=og:image]").attr("content")
        let posterURL = try URL(posterPath)
        let title = try document.select(".breadcrumb-item").array().last?.text() ?? ""

        var year: Int?
        if let yearText = try document.select(".video-attr").array().filter({ try $0.text().contains("Data")}).first?.select(".text").text() {
            year = Int(yearText)
        }

        let dataId = try document.select("[data-embed]").attr("data-embed")
        let sourceURL = URL(staticString: "https://www.tanti.icu/ajax/embed").appending(["data-embed": dataId])
        let data = ("id=" + dataId).data(using: .utf8) ?? Data()
        let headers = [
            "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
            "Accept": "*/*",
            "Referer": firstEpURL.absoluteString,
            "X-Requested-With": "XMLHttpRequest"
        ]

        let embedResponse = try await Utilities.downloadPage(url: sourceURL, httpMethod: "POST", data: data, extraHeaders: headers)
        guard let embed = Utilities.extractURLs(content: embedResponse).first else {
            throw TantifilmError.embedLinkMissing

        }
        let iframeContent = try await Utilities.downloadPage(url: embed)
        let iframeDocument = try SwiftSoup.parse(iframeContent)
        let rows: Elements = try iframeDocument.select("ul.nav.navbar-nav > li.dropdown")

        var isFirstLink = true // Flag to skip the first link
        var episodes = [Episode]()
        for element in rows.array() {
            // Skip the first link
            if isFirstLink {
                isFirstLink = false
                continue
            }

            let episodeLinkTag = try element.select("a").first() // Get the first <a> tag inside the <li> element
            guard let numberString = try episodeLinkTag?.text().trimmingCharacters(in: .whitespacesAndNewlines),
                  let episodeNumber = Int(numberString), // Assuming the text of <a> is the episode number
                  let episodeURLString = try episodeLinkTag?.attr("href"),
                  let episodeURL = URL(string: episodeURLString) else {
                continue // Skip this iteration if the episode is the one to exclude
            }

            let source = Source(hostURL: episodeURL)
            episodes.append(Episode(number: episodeNumber, sources: [source]))
        }

        // Sort episodes and initialize the TV show
        episodes.sort(by: { $0.number < $1.number })
        let season = Season(seasonNumber: 1, webURL: url, episodes: episodes)
        return TVshow(title: cleanTitle(title), webURL: url, posterURL: posterURL, year: year, seasons: [season])
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        // Encode the keyword to be URL safe
        let query = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        // Construct the search URL. Adjust the query parameter as per your actual search URL's requirement
        let url = baseURL.appendingPathComponent("?s=\(query)")

        // Call the parsePage function with the constructed URL to get the search results
        return try await parsePage(url: url)
    }

    public func home() async throws -> [MediaContentSection] {
        // Define static categories and their corresponding URLs
        let categories: [(title: String, url: String)] = [
            ("Ultimi Film Aggiornati", "https://www.tanti.icu/watch-genre/film-aggiornati"),
            ("3D", "https://www.tanti.icu/watch-genre/3d"),
            ("Al Cinema", "https://www.tanti.icu/watch-genre/al-cinema"),
            ("HD AltaDefinizione", "https://www.tanti.icu/watch-genre/altadefinizione"),
            ("Serie TV Altadefinizione", "https://www.tanti.icu/watch-genre/serie-altadefinizione"),
            ("Sub-ITA", "https://www.tanti.icu/watch-genre/sub-ita"),
            ("Anime", "https://www.tanti.icu/watch-genre/anime"),
            ("Azione", "https://www.tanti.icu/watch-genre/azione"),
            ("Avventura", "https://www.tanti.icu/watch-genre/avventura"),
            ("Avventura Fantasy", "https://www.tanti.icu/watch-genre/avventura-fantasy"),
            ("Biografico", "https://www.tanti.icu/watch-genre/biografico"),
            ("Cartoni Animati", "https://www.tanti.icu/watch-genre/cartoni-animati"),
            ("Comico", "https://www.tanti.icu/watch-genre/comico"),
            ("Commedia", "https://www.tanti.icu/watch-genre/commedia"),
            ("Documentari", "https://www.tanti.icu/watch-genre/documentari"),
            ("Drammatico", "https://www.tanti.icu/watch-genre/drammatico"),
            ("Erotici", "https://www.tanti.icu/watch-genre/erotici"),
            ("Fantascienza", "https://www.tanti.icu/watch-genre/fantascienza"),
            ("Gangster", "https://www.tanti.icu/watch-genre/gangster-1"),
            ("Giallo", "https://www.tanti.icu/watch-genre/giallo"),
            ("Grottesco", "https://www.tanti.icu/watch-genre/grotesto"),
            ("Guerra", "https://www.tanti.icu/watch-genre/guerra"),
            ("Musicale", "https://www.tanti.icu/watch-genre/musicale"),
            ("Noir", "https://www.tanti.icu/watch-genre/noir"),
            ("Poliziesco", "https://www.tanti.icu/watch-genre/poliziesco"),
            ("Horror", "https://www.tanti.icu/watch-genre/horror"),
            ("Romantico", "https://www.tanti.icu/watch-genre/romantico"),
            ("Sportivo", "https://www.tanti.icu/watch-genre/sportivo"),
            ("Storico", "https://www.tanti.icu/watch-genre/storico"),
            ("Thriller", "https://www.tanti.icu/watch-genre/thriller-1"),
            ("Western", "https://www.tanti.icu/watch-genre/western"),
            ("Serie TV", "https://www.tanti.icu/watch-genre/serie-tv"),
            ("Miniserie", "https://www.tanti.icu/watch-genre/miniserie-1"),
            ("Programmi Tv", "https://www.tanti.icu/watch-genre/programmi-tv"),
            ("Live", "https://www.tanti.icu/watch-genre/live"),
            ("Trailers", "https://www.tanti.icu/watch-genre/trailers"),
            ("Serie TV Aggiornate", "https://www.tanti.icu/watch-genre/series-tv-featured"),
            ("Aggiornamenti", "https://www.tanti.icu/watch-genre/recommended"),
            ("Featured", "https://www.tanti.icu/watch-genre/featured")
        ]

        // Convert categories into MediaContentSections
        var sections: [MediaContentSection] = []

           // Loop through each category, fetching and parsing the media content
           for category in categories {
               if let url = URL(string: category.url) {
                   do {
                       let mediaContent = try await parsePage(url: url)
                       let section = MediaContentSection(title: category.title, media: mediaContent)
                       sections.append(section)
                   } catch {
                       // Handle or log error, or append an empty section if necessary
                       print("Error fetching or parsing media content for \(category.title): \(error)")
                       let emptySection = MediaContentSection(title: category.title, media: [])
                       sections.append(emptySection)
                   }
               }
           }

           return sections
       }
}

private extension TantifilmProvider {
    // Assuming you have a baseURL defined elsewhere in your code
    // private let baseURL = URL(staticString: "https://www.tanti.icu")

    private func parsePageContent(_ content: String) throws -> [MediaContent] {
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select("#main_col .media3")

        return try rows.array().compactMap { row in
            let path: String = try row.select("a").attr("href")
            if let url = URL(string: path, relativeTo: baseURL),
               let title: String = try? row.select(".title-film").text(),
               let posterPath: String = try? row.select("img").attr("src"),
               let posterURL = URL(string: posterPath, relativeTo: baseURL) {
                return MediaContent(title: cleanTitle(title), webURL: url, posterURL: posterURL, type: .tvShow, provider: .tantifilm)
            } else {
                return nil // Skip this entry if URL or other attributes are invalid
            }
        }
    }

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
