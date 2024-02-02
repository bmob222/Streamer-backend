import Foundation
import SwiftSoup

public struct EmpireStreamingProvider: Provider {
    public init() {}

    public let locale: Locale = Locale(identifier: "fr_FR")
    public let type: ProviderType = .init(.empire)
    public let title: String = "EmpireStreaming"
    public let langauge: String = ""
    private let posterBaseURL = URL(staticString: "https://image.tmdb.org/t/p/w342/")

    public let baseURL: URL = URL(staticString: "https://empire-stream.net")
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
        case categoryNotFound
    }
    public func parsePage(url: URL) async throws -> [MediaContent] {
        return []
    }

    public var categories: [Category] = [
        .init(id: 25, name: "Action", url: .init(staticString: "https://google.com/movies")),
        .init(id: 27, name: "Animation", url: .init(staticString: "https://google.com/movies")),
        .init(id: 35, name: "Animes", url: .init(staticString: "https://google.com/movies")),
        .init(id: 26, name: "Aventure", url: .init(staticString: "https://google.com/movies")),
        .init(id: 24, name: "Comédie", url: .init(staticString: "https://google.com/movies")),
        .init(id: 28, name: "Crime", url: .init(staticString: "https://google.com/movies")),
        .init(id: 6, name: "Documentaire", url: .init(staticString: "https://google.com/movies")),
        .init(id: 22, name: "Drame", url: .init(staticString: "https://google.com/movies")),
        .init(id: 29, name: "Familial", url: .init(staticString: "https://google.com/movies")),
        .init(id: 30, name: "Fantastique", url: .init(staticString: "https://google.com/movies")),
        .init(id: 18, name: "Guerre", url: .init(staticString: "https://google.com/movies")),
        .init(id: 10, name: "Histoire", url: .init(staticString: "https://google.com/movies")),
        .init(id: 23, name: "Horreur", url: .init(staticString: "https://google.com/movies")),
        .init(id: 12, name: "Musique", url: .init(staticString: "https://google.com/movies")),
        .init(id: 36, name: "Mystère", url: .init(staticString: "https://google.com/movies")),
        .init(id: 31, name: "Romance", url: .init(staticString: "https://google.com/movies")),
        .init(id: 32, name: "Science-Fiction", url: .init(staticString: "https://google.com/movies")),
        .init(id: 34, name: "Thriller", url: .init(staticString: "https://google.com/movies")),
        .init(id: 21, name: "Télé-Réalité", url: .init(staticString: "https://google.com/movies")),
        .init(id: 33, name: "Téléfilm", url: .init(staticString: "https://google.com/movies")),
        .init(id: 19, name: "Western", url: .init(staticString: "https://google.com/movies")),

        
        .init(id: 125, name: "Action", url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 127, name: "Animation", url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 135, name: "Animes", url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 126, name: "Aventure", url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 124, name: "Comédie", url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 128, name: "Crime", url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 106, name: "Documentaire", url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 122, name: "Drame", url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 129, name: "Familial", url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 130, name: "Fantastique", url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 118, name: "Guerre", url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 110, name: "Histoire", url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 123, name: "Horreur", url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 112, name: "Musique", url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 136, name: "Mystère", url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 131, name: "Romance", url: .init(staticString: "https://google.com/tvshows")),    
        .init(id: 132, name: "Science-Fiction", url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 134, name: "Thriller", url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 121, name: "Télé-Réalité", url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 133, name: "Téléfilm", url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 119, name: "Western", url: .init(staticString: "https://google.com/tvshows")),

        
        .init(id: 5, name: "Marvel Studios", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/hUzeosd33nzE5MCNsZxCGEKTXaQ.png"), url: .init(staticString: "https://google.com/movies")),
        .init(id: 6, name: "DC Entertainment", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/2Tc1P3Ac8M479naPp1kYT3izLS5.png"), url: .init(staticString: "https://google.com/movies")),
        .init(id: 7, name: "Warner Bros. Pictures", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/ky0xOc5OrhzkZ1N6KyUxacfQsCk.png"), url: .init(staticString: "https://google.com/movies")),
        .init(id: 9, name: "HBO", poster: .init(staticString: "https://www.themoviedb.org/t/p/w300_filter(negate,000,666)/tuomPhY2UtuPTqqFnKMVHvSb724.png"), url: .init(staticString: "https://google.com/movies")),
        .init(id: 11, name: "Pixar", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/1TjvGVDMYsj6JBxOAkUHpPEwLf7.png"), url: .init(staticString: "https://google.com/movies")),
        .init(id: 18, name: "Nat geo", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/q9rPBG1rHbUjII1Qn98VG2v7cFa.png"), url: .init(staticString: "https://google.com/movies")),
        .init(id: 19, name: "Paramount+", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/fi83B1oztoS47xxcemFdPMhIzK.png"), url: .init(staticString: "https://google.com/movies")),
        .init(id: 20, name: "Canal +", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/9aotxauvc9685tq9pTcRJszuT06.png"), url: .init(staticString: "https://google.com/movies")),
        .init(id: 21, name: "Netflix", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/wwemzKWzjKYJFfCeiB57q3r4Bcm.png"), url: .init(staticString: "https://google.com/movies")),
        .init(id: 22, name: "Disney +", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/q1ZcgL6W1F0yyEcTr2ribADzuLr.png"), url: .init(staticString: "https://google.com/movies")),
        .init(id: 23, name: "Apple TV", poster: .init(staticString: "https://image.tmdb.org/t/p/w300_filter(negate,000,666)/4KAy34EHvRM25Ih8wb82AuGU7zJ.png"), url: .init(staticString: "https://google.com/movies")),
        .init(id: 24, name: "OCS", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/f3hRdCaK1w9qH1Qs8nLd2L2bae1.png"), url: .init(staticString: "https://google.com/movies")),
        .init(id: 25, name: "StarzPlay", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/xwJCudY7u7w3brf4JDeeBHXKfix.png"), url: .init(staticString: "https://google.com/movies")),
        .init(id: 26, name: "Hulu", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/pqUTCleNUiTLAVlelGxUgWn1ELh.png"), url: .init(staticString: "https://google.com/movies")),
        .init(id: 27, name: "Anime", poster: .init(staticString: "https://pnghq.com/wp-content/uploads/2023/02/anime-word-clip-art-png-6772.png"), url: .init(staticString: "https://google.com/movies")),
        .init(id: 28, name: "Amazon prime video", poster: .init(staticString: "https://www.themoviedb.org/t/p/w300/ifhbNuuVnlwYy5oXA5VIb2YR8AZ.png"), url: .init(staticString: "https://google.com/movies")),

        .init(id: 105, name: "Marvel Studios", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/hUzeosd33nzE5MCNsZxCGEKTXaQ.png"), url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 106, name: "DC Entertainment", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/2Tc1P3Ac8M479naPp1kYT3izLS5.png"), url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 107, name: "Warner Bros. Pictures", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/ky0xOc5OrhzkZ1N6KyUxacfQsCk.png"), url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 109, name: "HBO", poster: .init(staticString: "https://www.themoviedb.org/t/p/w300_filter(negate,000,666)/tuomPhY2UtuPTqqFnKMVHvSb724.png"), url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 111, name: "Pixar", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/1TjvGVDMYsj6JBxOAkUHpPEwLf7.png"), url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 118, name: "Nat geo", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/q9rPBG1rHbUjII1Qn98VG2v7cFa.png"), url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 119, name: "Paramount+", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/fi83B1oztoS47xxcemFdPMhIzK.png"), url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 120, name: "Canal +", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/9aotxauvc9685tq9pTcRJszuT06.png"), url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 121, name: "Netflix", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/wwemzKWzjKYJFfCeiB57q3r4Bcm.png"), url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 122, name: "Disney +", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/q1ZcgL6W1F0yyEcTr2ribADzuLr.png"), url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 123, name: "Apple TV", poster: .init(staticString: "https://image.tmdb.org/t/p/w300_filter(negate,000,666)/4KAy34EHvRM25Ih8wb82AuGU7zJ.png"), url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 124, name: "OCS", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/f3hRdCaK1w9qH1Qs8nLd2L2bae1.png"), url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 125, name: "StarzPlay", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/xwJCudY7u7w3brf4JDeeBHXKfix.png"), url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 126, name: "Hulu", poster: .init(staticString: "https://image.tmdb.org/t/p/w300/pqUTCleNUiTLAVlelGxUgWn1ELh.png"), url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 127, name: "Anime", poster: .init(staticString: "https://pnghq.com/wp-content/uploads/2023/02/anime-word-clip-art-png-6772.png"), url: .init(staticString: "https://google.com/tvshows")),
        .init(id: 128, name: "Amazon prime video", poster: .init(staticString: "https://www.themoviedb.org/t/p/w300/ifhbNuuVnlwYy5oXA5VIb2YR8AZ.png"), url: .init(staticString: "https://google.com/tvshows")),

    ]
    static var contentItemsResponse: ContentItemsResponse?

    func trigger() async throws {
        _ = try await Utilities.requestCloudFlareCookies(url: .init(staticString: "https://empire-stream.net"))

        let url = URL(staticString: "https://empire-stream.net/api/views/contenitem")
        let headers = [
            "Accept": "application/json, text/plain, */*",
            "Pragma": "no-cache",
            "sec-ch-ua-mobile": "?0",
            "Sec-Fetch-Site": "same-origin",
            "Accept-Language": "en-US,en;q=0.9,ar;q=0.8",
            "Cache-Control": "no-cache",
            "Sec-Fetch-Mode": "cors",
            "authority": "https://empire-stream.net/api/views/contenitem",
            "Referer": "https://empire-streaming.net/",
            "Connection": "keep-alive",
            "DNT": "1",
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36",
            "Sec-Fetch-Dest": "empty",
            "Host": "empire-stream.net"
        ]

        let data = try await Utilities.requestData(url: url, extraHeaders: headers)
        Self.contentItemsResponse = try JSONDecoder().decode(ContentItemsResponse.self, from: data)
    }

    public func parsePage(type: String, page: Int, univers: Int? = nil, categories: Int? = nil) async throws -> [MediaContent] {
        let jsonData = [
            "data": [
                "type": type,
                "page": page,
                "univers": univers,
                "categories": categories.map { [$0] } ?? nil,
                "note": nil,
                "year": nil
            ]
        ] as [String: Any]
        let postData = try! JSONSerialization.data(withJSONObject: jsonData, options: [])

        let url = URL(string: "https://empire-stream.net/api/views/search_explorateur")!
        let headers = [
            "Accept": "application/json, text/plain, */*",
            "Accept-Language": "en-US,en;q=0.9,ar;q=0.8",
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "Content-Type": "application/json;charset=UTF-8",
            "DNT": "1",
            "Origin": "https://empire-stream.net",
            "Pragma": "no-cache",
            "Referer": "https://empire-stream.net/explorateur",
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

    public func latestCategory(id: Int, page: Int) async throws -> [MediaContent] {
        guard let category = categories.first(where: { $0.id == id }) else {
            throw EmpireStreamingProviderError.categoryNotFound
        }

        var type = ""
        var cat: Int?
        var universe: Int?

        if category.poster != nil {
            if category.url?.lastPathComponent == "movies" {
                type = "films"
                universe = id
            } else if category.url?.lastPathComponent == "tvshows" {
                type = "series"
                universe = id - 100
            }
        }else {
            if category.url?.lastPathComponent == "movies" {
                type = "films"
                cat = id
            } else if category.url?.lastPathComponent == "tvshows" {
                type = "series"
                cat = id - 100
            }
        }
        return try await parsePage(type: type, page: page, univers: universe, categories: cat)
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

        let keyword = keyword.lowercased().trimmingCharacters(in: .whitespaces)
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
        var home: [MediaContentSection] =  try sectionRows.array().compactMap { section -> MediaContentSection?  in
            let title = try section.select(".mr-3").text().replacingOccurrences(of: "Empire-streaming", with: "").strip()
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
                return MediaContentSection(title: title.isEmpty ? "À L'AFFICHE" : title, media: media)
            } else {
                return nil
            }
        }

        var all = categories
        let moviesCategries = Array(all.prefix(21))
        all.removeFirst(21)

        
        let tvCategries =  Array(all.prefix(21))
        all.removeFirst(21)
        
        let moviesUniverses =  Array(all.prefix(16))
        all.removeFirst(16)        
        let tvUniverses =  Array(all.prefix(16))

        home.append(MediaContentSection(title: "Film Univers", media: [], categories: moviesUniverses))
        home.append(MediaContentSection(title: "Film Catégories", media: [], categories: moviesCategries))
        home.append(MediaContentSection(title: "Series Universe", media: [], categories: tvUniverses))
        home.append(MediaContentSection(title: "Series Catégories", media: [], categories: tvCategries))

        return home

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
