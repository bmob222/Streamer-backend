import Foundation
import SwiftSoup

public struct EmpireStreamingProvider: Provider {
    public let locale: Locale = Locale(identifier: "fr_FR")
    public let type: ProviderType = .init(.empire)
    public let title: String = "EmpireStreaming"
    public let langauge: String = ""
    private let posterBaseURL = URL(staticString: "https://image.tmdb.org/t/p/w342/")

    public let baseURL: URL = URL(staticString: "https://empire-streaming.app/")
    public var moviesURL: URL {
        baseURL.appendingPathComponent("movies")
    }
    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("series")
    }

    private var homeURL: URL {
        baseURL.appendingPathComponent("one")
    }

    enum EmpireStreamingProviderError: Error {
        case missingMovieInformation
    }
    public func parsePage(url: URL) async throws -> [MediaContent] {
        return []
    }

    static var contentItemsResponse: ContentItemsResponse?

    func trigger() async throws {
        let url = URL(staticString: "https://empire-streaming.app/api/views/contenitem")
        let headers = [
            "Host": "empire-streaming.app",
            "Connection": "keep-alive",
            "Pragma": "no-cache",
            "Cache-Control": "no-cache",
            "sec-ch-ua": "\"Not/A)Brand\";v=\"99\", \"Google Chrome\";v=\"115\", \"Chromium\";v=\"115\"",
            "Accept": "application/json, text/plain, */*",
            "DNT": "1",
            "sec-ch-ua-mobile": "?0",
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36",
            "sec-ch-ua-platform": "\"macOS\"",
            "Sec-Fetch-Site": "same-origin",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Dest": "empty",
            "Referer": "https://empire-streaming.app/",
            "Accept-Language": "en-US,en;q=0.9,ar;q=0.8",
            "Cookie": "cf_clearance=.7i0986DiW5qmEbgO8gfWuYZnD0dRXuXRvujwez_uwk-1691868138-0-1-979816dd.aa21640c.c099493d-150.0.0"
        ]

        let data = try await Utilities.requestData(url: url, extraHeaders: headers)
        Self.contentItemsResponse = try JSONDecoder().decode(ContentItemsResponse.self, from: data)
    }

    public func parsePage(type: String, page: Int) async throws -> [MediaContent] {
        let jsonData = [
            "data": [
                "type": type,
                "page": page,
                "univers": nil,
                "categories": nil,
                "note": nil,
                "year": nil
            ]
        ] as [String: Any]
        let postData = try! JSONSerialization.data(withJSONObject: jsonData, options: [])

        let url = URL(string: "https://empire-streaming.app/api/views/search_explorateur")!
        let headers = [
            "Accept": "application/json, text/plain, */*",
            "Accept-Language": "en-US,en;q=0.9,ar;q=0.8",
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "Content-Type": "application/json;charset=UTF-8",
            "DNT": "1",
            "Origin": "https://empire-streaming.app",
            "Pragma": "no-cache",
            "Referer": "https://empire-streaming.app/explorateur",
            "Sec-Fetch-Dest": "empty",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Site": "same-origin",
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36",
            "sec-ch-ua": "\"Not/A)Brand\";v=\"99\", \"Google Chrome\";v=\"115\", \"Chromium\";v=\"115\"",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": "\"macOS\""
        ]

        let data = try await Utilities.requestData(url: url, httpMethod: "POST", data: postData, extraHeaders: headers)
        let result = try JSONDecoder().decode(ResultResponse.self, from: data)

        return result.result.map {
            let posterURL = posterBaseURL.appendingPathComponent($0.image.first!.path)

            return .init(title: $0.originalTitle ?? $0.title,
                         webURL: baseURL.appendingPathComponent($0.urlPath),
                         posterURL: posterURL,
                         type: $0.label == "film" ? .movie : .tvShow,
                         provider: self.type
            )
        }
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(type: "films", page: page)
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(type: "series", page: page)
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)

        let script = try document.select("script").filter {
            try $0.html().contains("streamer:")
        }.first?.html() ?? ""
        let stringData = script.matches(for: "data:(.+),").first

        guard let stringData = stringData?.data(using: .utf8) else {
            throw EmpireStreamingProviderError.missingMovieInformation
        }
        let data = try JSONDecoder().decode(MovieResponse.self, from: stringData)
        var sources = data.videoInfoFree?.vf?.map { video in
            let videoUrl = baseURL.appendingPathComponent("player_submit")
                .appendingPathComponent(video.idVideo)
                .appendingPathComponent("vf")
                .appendingQueryItem(name: "title", value: data.titre)
                .appendingQueryItem(name: "type", value: data.label ?? "film")

            return Source(hostURL: videoUrl)

        } ?? [] as [Source]

        let sources2 = data.videoInfoFree?.vostfr?.map { video in
            let videoUrl = baseURL.appendingPathComponent("player_submit")
                .appendingPathComponent(video.idVideo)
                .appendingPathComponent("vostfr")
                .appendingQueryItem(name: "title", value: data.titre)
                .appendingQueryItem(name: "type", value: data.label ?? "film")

            return Source(hostURL: videoUrl)

        } ?? [] as [Source]

        let sources3 = data.videoInfoFree?.vo?.map { video in
            let videoUrl = baseURL.appendingPathComponent("player_submit")
                .appendingPathComponent(video.idVideo)
                .appendingPathComponent("vo")
                .appendingQueryItem(name: "title", value: data.titre)
                .appendingQueryItem(name: "type", value: data.label ?? "film")

            return Source(hostURL: videoUrl)

        } ?? [] as [Source]

        sources.append(contentsOf: sources2)
        sources.append(contentsOf: sources3)

        let posterURL = posterBaseURL.appendingPathComponent(data.poster.path)
        return Movie(title: data.titreOriginal ?? data.titre, webURL: url, posterURL: posterURL, sources: sources)

    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)

        let script = try document.select("script").filter {
            try $0.html().contains("streamer:")
        }.first?.html() ?? ""
        let stringData = script.matches(for: "data:(.+),").first
        guard let stringData = stringData?.data(using: .utf8) else {
            throw EmpireStreamingProviderError.missingMovieInformation
        }
        let data = try JSONDecoder().decode(TVshowResponse.self, from: stringData)
        let seasons = data.saison.map { key, value in
            let seasonNumber = Int(key) ?? 1
            let episodes = value.map {

                let sources = $0.videoInfoFree?.vf?.map { video in
                    let videoUrl = baseURL.appendingPathComponent("player_submit")
                        .appendingPathComponent(video.idVideo)
                        .appendingPathComponent("vf")
                        .appendingQueryItem(name: "title", value: data.titre)
                        .appendingQueryItem(name: "type", value: data.label ?? "film")

                    return Source(hostURL: videoUrl)

                } ?? [] as [Source]

                let sources2 = $0.videoInfoFree?.vostfr?.map { video in
                    let videoUrl = baseURL.appendingPathComponent("player_submit")
                        .appendingPathComponent(video.idVideo)
                        .appendingPathComponent("vostfr")
                        .appendingQueryItem(name: "title", value: data.titre)
                        .appendingQueryItem(name: "type", value: data.label ?? "film")

                    return Source(hostURL: videoUrl)

                } ?? [] as [Source]

                let sources3 = $0.videoInfoFree?.vo?.map { video in
                    let videoUrl = baseURL.appendingPathComponent("player_submit")
                        .appendingPathComponent(video.idVideo)
                        .appendingPathComponent("vo")
                        .appendingQueryItem(name: "title", value: data.titre)
                        .appendingQueryItem(name: "type", value: data.label ?? "film")

                    return Source(hostURL: videoUrl)

                } ?? [] as [Source]

                return Episode(number: $0.episode, sources: sources + sources2 + sources3)
            }
            return Season(seasonNumber: seasonNumber, webURL: url, episodes: episodes)
        }

        let posterURL = posterBaseURL.appendingPathComponent(data.poster.path)

        return TVshow(title: data.titreOriginal ?? data.titre,
                      webURL: url,
                      posterURL: posterURL,
                      seasons: seasons)

    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        if Self.contentItemsResponse == nil {
            try await trigger()
        }
        guard let result = Self.contentItemsResponse else {
            return []
        }

        var keyword = keyword.lowercased()
        let films = result.contentItem.films.filter { $0.title.lowercased().contains(keyword) || $0.originalTitle?.lowercased().contains(keyword) == true}.prefix(10)
        let shows = result.contentItem.series.filter { $0.title.lowercased().contains(keyword) || $0.originalTitle?.lowercased().contains(keyword) == true }.prefix(10)

        return Array(films + shows).map {
            let posterURL = posterBaseURL.appendingPathComponent($0.image.first!.path)

            return .init(title: $0.originalTitle ?? $0.title,
                         webURL: baseURL.appendingPathComponent($0.urlPath),
                         posterURL: posterURL,
                         type: $0.label == "film" ? .movie : .tvShow,
                         provider: self.type
            )
        }
    }

    public func home() async throws -> [MediaContentSection] {
        let content = try await Utilities.downloadPage(url: baseURL)
        let document = try SwiftSoup.parse(content)
        let sectionRows: Elements = try document.select(".block-forme")
        return try sectionRows.array().compactMap { section -> MediaContentSection?  in

            let title = try section.select(".mr-3").text()
            let media = try section.select(".slick-slide").array().compactMap { content -> MediaContent? in
                let posterPath = try content.select("img").attr("data-src").replacingOccurrences(of: "/images/medias/", with: "")
                let posterURL = posterBaseURL.appendingPathComponent(posterPath)
                let path = try content.select("a").attr("href")
                let url = self.baseURL.appendingPathComponent(path)
                let title = try content.select("h3").text().replacingOccurrences(of: "Empire-streaming", with: "")
                if title.isEmpty {
                    return nil
                }
                return MediaContent(title: title,
                                    webURL: url,
                                    posterURL: posterURL,
                                    type: path.contains("film") ? .movie : .tvShow,
                                    provider: self.type)

            }
            if media.count > 0 {
                return MediaContentSection(title: title, media: media)
            } else {
                return nil
            }
        }

    }

    struct ContentItemsResponse: Codable {
        let contentItem: FilmsAndTVResponse
    }

    struct FilmsAndTVResponse: Codable {
        let films: [SearchResponse]
        let series: [SearchResponse]
    }

    struct ResultResponse: Codable {
        let result: [SearchResponse]
    }

    struct SearchResponse: Codable {
        let id: Int
        let title: String
        let originalTitle: String?
        let label: String
        let image: [Poster]
        let urlPath: String

    }

    // MARK: - HomeResponse
    struct MovieResponse: Codable {
        let id: Int
        let titre: String
        let titreOriginal: String?
        let label: String?
        let poster: Poster
        let urlPath: String
        let videoInfoFree: VideoInfo?

        enum CodingKeys: String, CodingKey {
            case id = "id"
            case titre = "Titre"
            case titreOriginal = "TitreOriginal"
            case label = "label"
            case poster = "poster"
            case urlPath = "urlPath"
            case videoInfoFree = "video_info_free"
        }

        init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<EmpireStreamingProvider.MovieResponse.CodingKeys> = try decoder.container(keyedBy: EmpireStreamingProvider.MovieResponse.CodingKeys.self)

            self.id = try container.decode(Int.self, forKey: EmpireStreamingProvider.MovieResponse.CodingKeys.id)
            self.titre = try container.decode(String.self, forKey: EmpireStreamingProvider.MovieResponse.CodingKeys.titre)
            self.titreOriginal = try container.decodeIfPresent(String.self, forKey: EmpireStreamingProvider.MovieResponse.CodingKeys.titreOriginal)
            self.label = try container.decodeIfPresent(String.self, forKey: EmpireStreamingProvider.MovieResponse.CodingKeys.label)
            self.poster = try container.decode(EmpireStreamingProvider.Poster.self, forKey: EmpireStreamingProvider.MovieResponse.CodingKeys.poster)
            self.urlPath = try container.decode(String.self, forKey: EmpireStreamingProvider.MovieResponse.CodingKeys.urlPath)

            if (try? container.decodeIfPresent([EmpireStreamingProvider.VideoInfo].self, forKey: EmpireStreamingProvider.MovieResponse.CodingKeys.videoInfoFree)) != nil {
                self.videoInfoFree = nil
            } else {
                self.videoInfoFree = try container.decodeIfPresent(EmpireStreamingProvider.VideoInfo.self, forKey: EmpireStreamingProvider.MovieResponse.CodingKeys.videoInfoFree)
            }

        }

        func encode(to encoder: Encoder) throws {
            var container: KeyedEncodingContainer<EmpireStreamingProvider.MovieResponse.CodingKeys> = encoder.container(keyedBy: EmpireStreamingProvider.MovieResponse.CodingKeys.self)

            try container.encode(self.id, forKey: EmpireStreamingProvider.MovieResponse.CodingKeys.id)
            try container.encode(self.titre, forKey: EmpireStreamingProvider.MovieResponse.CodingKeys.titre)
            try container.encodeIfPresent(self.titreOriginal, forKey: EmpireStreamingProvider.MovieResponse.CodingKeys.titreOriginal)
            try container.encodeIfPresent(self.label, forKey: EmpireStreamingProvider.MovieResponse.CodingKeys.label)
            try container.encode(self.poster, forKey: EmpireStreamingProvider.MovieResponse.CodingKeys.poster)
            try container.encode(self.urlPath, forKey: EmpireStreamingProvider.MovieResponse.CodingKeys.urlPath)
            try container.encodeIfPresent(self.videoInfoFree, forKey: EmpireStreamingProvider.MovieResponse.CodingKeys.videoInfoFree)
        }
    }

    struct TVshowResponse: Codable {
        let id: Int
        let titre: String
        let titreOriginal: String?
        let label: String?
        let saison: [String: [Saison]]
        let poster: Poster
        let urlPath: String

        enum CodingKeys: String, CodingKey {
            case id = "id"
            case titre = "Titre"
            case titreOriginal = "TitreOriginal"
            case label = "label"
            case saison = "Saison"
            case poster = "poster"
            case urlPath = "urlPath"
        }
    }

    // MARK: - Poster
    struct Poster: Codable {
        let path: String

        enum CodingKeys: String, CodingKey {
            case path = "path"
        }
    }

    // MARK: - Saison
    struct Saison: Codable {
        let id: Int
        let versions: [String]
        let episode: Int
        let saison: Int
        let video: [Video]
        let videoInfoFree: VideoInfo?

        enum CodingKeys: String, CodingKey {
            case id = "id"
            case versions = "versions"
            case episode = "episode"
            case saison = "saison"
            case video = "video"
            case videoInfoFree = "video_info_free"
        }

        init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<EmpireStreamingProvider.Saison.CodingKeys> = try decoder.container(keyedBy: EmpireStreamingProvider.Saison.CodingKeys.self)

            self.id = try container.decode(Int.self, forKey: EmpireStreamingProvider.Saison.CodingKeys.id)
            self.versions = try container.decode([String].self, forKey: EmpireStreamingProvider.Saison.CodingKeys.versions)
            self.episode = try container.decode(Int.self, forKey: EmpireStreamingProvider.Saison.CodingKeys.episode)
            self.saison = try container.decode(Int.self, forKey: EmpireStreamingProvider.Saison.CodingKeys.saison)
            self.video = try container.decode([EmpireStreamingProvider.Video].self, forKey: EmpireStreamingProvider.Saison.CodingKeys.video)

            if (try? container.decodeIfPresent([EmpireStreamingProvider.VideoInfo].self, forKey: EmpireStreamingProvider.Saison.CodingKeys.videoInfoFree)) != nil {
                self.videoInfoFree = nil
            } else {
                self.videoInfoFree = try container.decodeIfPresent(EmpireStreamingProvider.VideoInfo.self, forKey: EmpireStreamingProvider.Saison.CodingKeys.videoInfoFree)
            }

        }

        func encode(to encoder: Encoder) throws {
            var container: KeyedEncodingContainer<EmpireStreamingProvider.Saison.CodingKeys> = encoder.container(keyedBy: EmpireStreamingProvider.Saison.CodingKeys.self)

            try container.encode(self.id, forKey: EmpireStreamingProvider.Saison.CodingKeys.id)
            try container.encode(self.versions, forKey: EmpireStreamingProvider.Saison.CodingKeys.versions)
            try container.encode(self.episode, forKey: EmpireStreamingProvider.Saison.CodingKeys.episode)
            try container.encode(self.saison, forKey: EmpireStreamingProvider.Saison.CodingKeys.saison)
            try container.encode(self.video, forKey: EmpireStreamingProvider.Saison.CodingKeys.video)
            try container.encodeIfPresent(self.videoInfoFree, forKey: EmpireStreamingProvider.Saison.CodingKeys.videoInfoFree)
        }
    }

    // MARK: - Video
    struct Video: Codable {
        let id: Int
        let property: String
        let version: String
        let title: String
        let editMod: Bool
        let isPrem: Bool

        enum CodingKeys: String, CodingKey {
            case id = "id"
            case property = "property"
            case version = "version"
            case title = "title"
            case editMod = "editMod"
            case isPrem = "isPrem"
        }
    }

    // MARK: - VideoInfo
    struct VideoInfo: Codable {
        let vf: [Vf]?
        let vostfr: [Vf]?
        let vo: [Vf]?
        enum CodingKeys: String, CodingKey {
            case vf = "vf"
            case vo = "vo"
            case vostfr = "vostfr"
        }
    }

    // MARK: - Vf
    struct Vf: Codable {
        let property: String
        let idVideo: Int

        enum CodingKeys: String, CodingKey {
            case property = "property"
            case idVideo = "idVideo"
        }
    }

}
