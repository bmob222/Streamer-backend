import Foundation

public struct ProviderConfig: Codable {
    public enum ProviderType: String, Codable {
        case remote
        case local
    }
    public let id: String
    public let locale: String
    public let title: String
    public let emoji: String
    public let iconURL: URL
    public let type: ProviderType

    public init(id: String, locale: String, title: String, emoji: String, iconURL: URL, type: ProviderConfig.ProviderType) {
        self.id = id
        self.locale = locale
        self.title = title
        self.emoji = emoji
        self.iconURL = iconURL
        self.type = type
    }
}

public class RemoteProvider: Provider {

    public var type: ProviderType
    public var title: String
    public var langauge: String
    public var locale: Locale

    public enum RemoteProviderError: Error {
        case decryptionFailed
    }

    public init(providerConfig: ProviderConfig) {
        self.type = ProviderType.remote(id: providerConfig.id)
        self.title = providerConfig.title
        self.langauge = providerConfig.emoji
        self.locale = Locale(identifier: providerConfig.locale)
    }

    @EnviromentValue(key: "streamer_backend", defaultValue: URL(staticString: "https://google.com"))
    private var baseURL: URL

    @EnviromentValue(key: "streamer_backend_1", defaultValue: "")
    public var key: String

    @EnviromentValue(key: "streamer_backend_2", defaultValue: "")
    public var iv: String

    private var moviesURL: URL {
        baseURL.appendingPathComponent("providers").appendingPathComponent(type.rawValue).appendingPathComponent("movies")
    }

    private var tvShowsURL: URL {
        baseURL.appendingPathComponent("providers").appendingPathComponent(type.rawValue).appendingPathComponent("tv")
    }

    private var homeURL: URL {
        baseURL.appendingPathComponent("providers").appendingPathComponent(type.rawValue).appendingPathComponent("home")
    }

    public func parsePage(url: URL) async throws -> [MediaContent] {
        let encryptedContent = try await Utilities.downloadPage(url: url)
        guard let content = encryptedContent.aesDecrypt(key: key, iv: iv),
              let data = content.data(using: .utf8) else {
            throw RemoteProviderError.decryptionFailed
        }
        return try JSONDecoder().decode([MediaContent].self, from: data)
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appendingQueryItem(name: "page", value: page))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appendingQueryItem(name: "page", value: page))
    }

    public func latestCategory(id: Int, page: Int) async throws -> [MediaContent] {
        let url = baseURL.appendingPathComponent("providers").appendingPathComponent(type.rawValue).appendingPathComponent("categories").appendingPathComponent(id)
        return try await parsePage(url: url.appendingQueryItem(name: "page", value: page))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        let url = moviesURL.appendingPathComponent(url.absoluteString.toBase64URL())
        let encryptedContent = try await Utilities.downloadPage(url: url)
        guard let content = encryptedContent.aesDecrypt(key: key, iv: iv),
              let data = content.data(using: .utf8) else {
            throw RemoteProviderError.decryptionFailed
        }
        return try JSONDecoder().decode(Movie.self, from: data)
    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        let url = tvShowsURL.appendingPathComponent(url.absoluteString.toBase64URL())
        let encryptedContent = try await Utilities.downloadPage(url: url)
        guard let content = encryptedContent.aesDecrypt(key: key, iv: iv),
              let data = content.data(using: .utf8) else {
            throw RemoteProviderError.decryptionFailed
        }
        return try JSONDecoder().decode(TVshow.self, from: data)
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let keyword = keyword.replacingOccurrences(of: " ", with: "+")
        let pageURL = baseURL
            .appendingPathComponent("providers")
            .appendingPathComponent(type.rawValue)
            .appendingPathComponent("search")
            .appending("query", value: keyword)
        return try await parsePage(url: pageURL)

    }

    public func home() async throws -> [MediaContentSection] {
        let encryptedContent = try await Utilities.downloadPage(url: homeURL)
        guard let content = encryptedContent.aesDecrypt(key: key, iv: iv),
              let data = content.data(using: .utf8) else {
            throw RemoteProviderError.decryptionFailed
        }
        return try JSONDecoder().decode([MediaContentSection].self, from: data)
    }

    public func update(_ k1: String, _ k2: String) {
        self._iv.defaultValue = k2
        self._key.defaultValue = k1
    }
}
