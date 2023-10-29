import Foundation
import SwiftSoup
import TMDb

public class TMDBProvider: Provider {
    public var type: ProviderType = .local(id: .tmdb)
    public var title: String = "TMDB"
    public let langauge: String = ""
    public var subtitle: String = "English content"
    public var moviesURL: URL = URL(staticString: "https://api.themoviedb.org/3/discover/movie/")
    public var tvShowsURL: URL = URL(staticString: "https://api.themoviedb.org/3/discover/tv/")
    
    public var homeURL: URL = URL(staticString: "https://api.themoviedb.org")
    
    var imagesConfiguration: ImagesConfiguration?
    
    enum TMDBProvider: Error {
        case missingPoster
    }

    public init() {
        let tmdbConfiguration = TMDbConfiguration(apiKey: Constants.TMDbAPIKey)
        TMDb.configure(tmdbConfiguration)
    }
    
    func setupImagesConfiguration() async throws {
        let configurationService = ConfigurationService()
        let apiConfiguration = try await configurationService.apiConfiguration()
        self.imagesConfiguration = apiConfiguration.images
    }
    
    public func parsePage(url: URL) async throws -> [MediaContent] {
        return []
    }
    
    public func latestMovies(page: Int) async throws -> [MediaContent] {
        if imagesConfiguration == nil {
            try await setupImagesConfiguration()
        }
        let movieService = MovieService()
        return try await movieService.popular(page: page).results.compactMap { movie -> MediaContent? in
            return convert(movie)
        }
    }
    
    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        if imagesConfiguration == nil {
            try await setupImagesConfiguration()
        }

        let tvSeriesService = TVSeriesService()
        return try await tvSeriesService.popular(page: page).results.compactMap { tvseries -> MediaContent? in
            return convert(tvseries)
        }
    }
    
    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        if imagesConfiguration == nil {
            try await setupImagesConfiguration()
        }
        let id = Int(url.lastPathComponent) ?? 0
        
        let movieService = MovieService()
        let response = try await movieService.details(forMovie: id)
        guard let posterURL = imagesConfiguration?.posterURL(for: response.posterPath) else {
            throw TMDBProvider.missingPoster
        }

        return Movie(
            title: response.title,
            webURL: url,
            posterURL: posterURL,
            sources: Self.generateSourcesFor(movieID: id)
        )
    }
    
    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        if imagesConfiguration == nil {
            try await setupImagesConfiguration()
        }

        let id = Int(url.lastPathComponent) ?? 0

        let tvSeriesService = TVSeriesService()
        let tvSeasonService = TVSeasonService()

        let response = try await tvSeriesService.details(forTVSeries: id)
        
        let seasons = try await response.seasons?.concurrentMap{ season in
            let updatedSeason = try await tvSeasonService.details(forSeason: season.seasonNumber, inTVSeries: id)
            let episodes = updatedSeason.episodes?.compactMap { episode -> Episode? in
                let sources = Self.generateSourcesFor(tvShowID: id, seasonNumber: episode.seasonNumber, episodeNumber: episode.episodeNumber)
                return Episode(number: episode.episodeNumber, sources: sources)
            }
            return Season(seasonNumber: season.seasonNumber, webURL: url, episodes: episodes)
        }
        
        
        guard let posterURL = imagesConfiguration?.posterURL(for: response.posterPath) else {
            throw TMDBProvider.missingPoster
        }
        return TVshow(title: response.name, webURL: url, posterURL: posterURL, seasons: seasons)
    }
    
    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        if imagesConfiguration == nil {
            try await setupImagesConfiguration()
        }

        let searchService = SearchService()
        let response = try await searchService.searchAll(query: keyword)

        return response.results.compactMap { media -> MediaContent? in

            switch media {
            case .movie(let movie): 
                return convert(movie)
            case .tvSeries(let tvseries):
                return convert(tvseries)
            case .person(_):
                return nil
                
            }

        }
    }
    
    public func home() async throws -> [MediaContentSection] {
        if imagesConfiguration == nil {
            try await setupImagesConfiguration()
        }

        let trendingService = TrendingService()
        let tendingMoviesWeek = try await trendingService.movies(inTimeWindow: .week).results.compactMap{ convert($0)}
        let tendingMoviesDay = try await trendingService.movies(inTimeWindow: .day).results.compactMap{ convert($0)}

        let tendingTvSeriesWeek = try await trendingService.tvSeries(inTimeWindow: .week).results.compactMap{ convert($0)}
        let tendingTvSeriesDay = try await trendingService.tvSeries(inTimeWindow: .day).results.compactMap{ convert($0)}

        return [
            .init(title: "Tending Movies Today", media: tendingMoviesDay),
            .init(title: "Tending Movies This Week", media: tendingMoviesWeek),
            .init(title: "Tending TV Shows Today", media: tendingTvSeriesDay),
            .init(title: "Tending TV Shows This Week", media: tendingTvSeriesWeek)
        ]
    }
    
   
    
    public static func generateSourcesFor(movieID: Int) -> [Source] {
        // https://us-west2-compute-proxied.streamflix.one/player?id=472054
        let embedURL = URL(staticString: "https://us-west2-compute-proxied.streamflix.one/api/player/movies").appendingQueryItem(name: "id", value: movieID)
        // https://api.9animetv.live/movie/884605
        let animetv = URL(staticString: "https://api.9animetv.live/movie").appendingPathComponent(movieID)
        let vidsrcURL = URL(staticString: "https://v2.vidsrc.me/embed/").appendingPathComponent(movieID)
        let databasegdriveplayerURL = URL(staticString: "https://databasegdriveplayer.xyz/player.php").appendingQueryItem(name: "tmdb", value: movieID)
        // https://myfilestorage.xyz/453395.mp4
        let myfilestorageURL = URL(staticString: "https://myfilestorage.xyz").appendingPathComponent("\(movieID).mp4")
        @EnviromentValue(key: "showbox_url", defaultValue: URL(staticString: "https://google.com/"))
        var movieboxprovider_url
        let superStreamURL = movieboxprovider_url.appendingPathComponent("tmdb/movie/").appendingPathComponent(movieID)
        
        return [
//            .init(hostURL: superStreamURL),
//            .init(hostURL: embedURL),
//            .init(hostURL: animetv),
//            .init(hostURL: vidsrcURL),
//            .init(hostURL: databasegdriveplayerURL),
//            .init(hostURL: myfilestorageURL)
        ]
    }
    
    public static func generateSourcesFor(tvShowID: Int, seasonNumber: Int, episodeNumber: Int) -> [Source] {
        let embedURL = URL(staticString: "https://us-west2-compute-proxied.streamflix.one/api/player/tv")
            .appendingQueryItem(name: "id", value: tvShowID)
            .appendingQueryItem(name: "s", value: seasonNumber)
            .appendingQueryItem(name: "e", value: episodeNumber)
        
        let animetv = URL(staticString: "https://api.9animetv.live/tv")
            .appendingPathComponent("\(tvShowID)-\(seasonNumber)-\(episodeNumber)" )
        
        let vidsrcURL = URL(staticString: "https://v2.vidsrc.me/embed/").appendingPathComponent(tvShowID).appendingPathComponent("\(seasonNumber)-\(episodeNumber)")
        let databasegdriveplayerURL = URL(staticString: "https://databasegdriveplayer.xyz/player.php?type=series")
            .appendingQueryItem(name: "tmdb", value: tvShowID)
            .appendingQueryItem(name: "season", value: seasonNumber)
            .appendingQueryItem(name: "episode", value: episodeNumber)
        @EnviromentValue(key: "showbox_url", defaultValue: URL(staticString: "https://google.com/"))
        var movieboxprovider_url
        let superStreamURL = movieboxprovider_url.appendingPathComponent("tmdb/tv/")
            .appendingPathComponent(tvShowID)
            .appendingPathComponent(seasonNumber)
            .appendingPathComponent(episodeNumber)
        
        return [
//            .init(hostURL: superStreamURL),
//            .init(hostURL: embedURL),
//            .init(hostURL: animetv),
//            .init(hostURL: vidsrcURL),
//            .init(hostURL: databasegdriveplayerURL)
        ]
    }
}
