import Foundation
import SwiftSoup

public struct TMDBProvider {

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
            .init(hostURL: superStreamURL),
            .init(hostURL: embedURL),
            .init(hostURL: animetv),
            .init(hostURL: vidsrcURL),
            .init(hostURL: databasegdriveplayerURL),
            .init(hostURL: myfilestorageURL)
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
            .init(hostURL: superStreamURL),
            .init(hostURL: embedURL),
            .init(hostURL: animetv),
            .init(hostURL: vidsrcURL),
            .init(hostURL: databasegdriveplayerURL)
    ]
    }
}
