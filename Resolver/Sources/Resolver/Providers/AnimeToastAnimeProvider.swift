
import Foundation
import SwiftSoup

public struct AnimeToastAnimeProvider: Provider {
    public init() {}
    
    public let locale: Locale = Locale(identifier: "de_DE")
    public let type: ProviderType = .init(.animetoast)
    public let title: String = "AnimeToast"
    public let langauge: String = "de_DE"
    
    public let baseURL: URL = URL(staticString: "https://www.animetoast.cc")
    public var moviesURL: URL = URL(staticString: "https://www.animetoast.cc/wochenplan-3")
    
    public var tvShowsURL: URL = URL(staticString: "https://www.animetoast.cc/latest-uploads")
    
    
    private var homeURL: URL {
        baseURL.appendingPathComponent("home")
    }
    
    enum AnimeToastProviderError: Error {
        case missingMovieInformation
        case episodeLinkNotFound
        case invalidURL
        case invalidEpisodeSource
    }
    
    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select(".col-md-4.col-sm-6")
        
        return try rows.array().compactMap { item in
            guard let path = try? item.select("a").attr("href"),
                  let webURL = URL(string: path),
                  let title = try? item.select("h3 a").text().replacingOccurrences(of: " Ger Dub", with: "").replacingOccurrences(of: " Ger Sub", with: ""),
                  let posterPath = try? item.select("img").attr("src"),
                  let posterURL = URL(string: posterPath)
            else {
                throw AnimeToastProviderError.missingMovieInformation
            }
            return MediaContent(
                title: title,
                webURL: webURL,
                posterURL: posterURL,
                type: .tvShow,
                provider: self.type
            )
        }
    }
    
    public func latestMovies(page: Int) async throws -> [MediaContent] {
        if page > 1 {
            return []
        }
        return try await parsePage(url: moviesURL.appending(["page": String(page)]))
    }
    
    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        if page > 1 {
            return []
        }
        return try await parsePage(url: tvShowsURL)
    }
    
    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        throw AnimeToastProviderError.missingMovieInformation
    }
    
    
    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)
        
        let title = try pageDocument.select("title").text()
            .replacingOccurrences(of: "- Anime auf Deutsch - AnimeToast", with: "")
            .replacingOccurrences(of: "Ger Dub", with: "")
            .strip()
        let posterPath = try pageDocument.select("meta[property='og:image']").attr("content")
        let posterURL = try URL(posterPath)
        
        // Select the tab content for the first season (multi_link_tab1)
        let tabContent = try pageDocument.select(".tab-content #multi_link_tab1").first()
        
        // Extract episode links and episode numbers from the tab content
        let episodeLinks = try tabContent?.select("a").array() ?? []
        
        var episodes: [Episode] = []
        
        for (index, episodeLinkElement) in episodeLinks.enumerated() {
            let episodeLink = try episodeLinkElement.attr("href").replacingOccurrences(of: "..", with: "")
            
            // Extract episode number from the link text
            let episodeNumberText = try episodeLinkElement.text().replacingOccurrences(of: "Ep:", with: "")
            let episodeNumber = Int(episodeNumberText) ?? (index + 1)
            
            // Unwrap the optional URL
            if let episodeURL = URL(string: episodeLink, relativeTo: url) {
                // Assuming you have a Source structure
                let source = Source(hostURL: episodeURL)
                episodes.append(Episode(number: episodeNumber, sources: [source]))
            }
        }
        
        // Create the TVshow object with extracted data
        return TVshow(title: title, webURL: url, posterURL: posterURL, seasons: [Season(seasonNumber: 1, webURL: url, episodes: episodes)])
    }
    
    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let url = baseURL.appending("s", value: keyword)
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select(".blog-item")
        
        return try rows.array().compactMap { item in
            guard let path = try? item.select("a").attr("href"),
                  let webURL = URL(string: path),
                  let title = try? item.select("h3 a").text().replacingOccurrences(of: " Ger Dub", with: "").replacingOccurrences(of: " Ger Sub", with: ""),
                  let posterPath = try? item.select("img").attr("src"),
                  let posterURL = URL(string: posterPath)
            else {
                throw AnimeToastProviderError.missingMovieInformation
            }
            return MediaContent(
                title: title,
                webURL: webURL,
                posterURL: posterURL,
                type: .tvShow,
                provider: self.type
            )
        }

    }

    enum MediaType {
        case movie
        case tvShow
    }
    
    public func home() async throws -> [MediaContentSection] {
        
        let latestUploads = URL(staticString: "https://www.animetoast.cc/latest-uploads").appending(["page": String(1), "type": String(1)])
        let latest = try await parsePage(url: latestUploads)
        let weeklyPlanner = URL(staticString: "https://www.animetoast.cc/wochenplan-3").appending(["page": String(1), "type": String(2)])
        let weekly = try await parsePage(url: weeklyPlanner)
        
        
        return [.init(title: "Zuletzt Hinzugefügt", media: latest), .init(title: "Dub", media: weekly)]
    }
    private struct Response: Codable {
        let html: String
    }
}
