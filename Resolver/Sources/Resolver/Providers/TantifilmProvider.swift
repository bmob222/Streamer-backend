import Foundation
import SwiftSoup
//https://www.tantifilm.farm/serie-tv/
public class TantifilmProvider: Provider {
    public init() {}
    enum TantifilmError: Error {
        case invalidIframeURL, posterURLIsNil, parsingError
    }
    public let type: ProviderType = .init(.tantifilm)
    public let title: String = "tantifilm"
    public let langauge: String = "it"
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
   
    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.downloadPage(url: url)
        return try parsePageContent(content)
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appendingPathComponent("page").appendingPathComponent(page))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appendingPathComponent("page").appendingPathComponent(page))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        // Not used
        return Movie(title: "", webURL: url, posterURL: url, sources: [], subtitles: nil)
    }
    enum yourErrorType: Error {
        case posterURLIsNil
    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        // Fetch and parse the main page
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)

        // Extracting title and poster URL from the main page
        let title = try pageDocument.select("title").text()
        let posterPath = try pageDocument.select("meta[property=og:image]").attr("content")
        guard let posterURL = URL(string: posterPath) else {
            throw TantifilmError.posterURLIsNil
        }

        // Extracting iframe URL from the main page
        let iframeURL = try pageDocument.select("iframe").attr("src")
        guard let requestUrl = URL(string: iframeURL) else {
            throw TantifilmError.invalidIframeURL
        }

        // Fetch and parse the iframe content to get the list of episodes
        let iframeContent = try await Utilities.downloadPage(url: requestUrl)
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
        return TVshow(title: cleanTitle(title), webURL: url, posterURL: posterURL, seasons: [season])
    }

    


    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let query = keyword.replacingOccurrences(of: " ", with: "+")
        let url = baseURL.appendingPathComponent("search")
            .appending("keyword", value: query)
        return try await parsePage(url: url)
    }

    public func home() async throws -> [MediaContentSection] {
        var items = try await parsePage(url: homeURL)
        guard items.count >= 24 else {
            return []
        }
        let recommendedMovies = MediaContentSection(title: NSLocalizedString("Latest Episode", comment: ""),
                                                    media: Array(items.prefix(12)))
        items.removeFirst(12)
        let recommendedTVShows = MediaContentSection(title: NSLocalizedString("New On Tantifilm", comment: ""),
                                                     media: Array(items.prefix(12)))
        return [recommendedMovies, recommendedTVShows]

    }
}

private extension TantifilmProvider {
    // Assuming you have a baseURL defined elsewhere in your code
    // private let baseURL = URL(staticString: "https://www.tantifilm.farm")

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
    
    func cleanTitle(_ title: String) ->String {
        return title.replacingOccurrences(of: "streaming", with: "")
            .replacingOccurrences(of: "streaming", with: "")
            .replacingOccurrences(of: "– Serie TV", with: "")
            .replacingOccurrences(of: "| Tantifilm", with: "")
            .removingRegexMatches(pattern: "\\(\\d{4}-\\d{4}\\)", replaceWith: "") //(2022-20023)
            .removingRegexMatches(pattern: "\\(\\d{4}-\\)", replaceWith: "") //(2022-)
            .removingRegexMatches(pattern: "\\(\\d{4}\\)", replaceWith: "") //(2022)
            .strip()
            .components(separatedBy: " – ")
            .last?.strip() ?? ""
    }
}
