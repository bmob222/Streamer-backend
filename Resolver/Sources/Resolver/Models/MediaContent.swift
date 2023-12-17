import Foundation

public struct MediaContentSection: Codable, Identifiable, Comparable, Hashable {
    public var id: String {
        title
    }

    public static func < (lhs: MediaContentSection, rhs: MediaContentSection) -> Bool {
        lhs.title < lhs.title
    }

    public let title: String
    public let media: [MediaContent]
    public let categories: [Category]?

    init(title: String, media: [MediaContent] = [], categories: [Category]? = nil) {
        self.title = title
        self.media = media
        self.categories = categories
    }
}

public struct MediaContent: Codable, Identifiable, Comparable, Hashable {
    public enum MediaContentType: String, Codable {
        case tvShow
        case movie
    }
    public var id: String {
        return webURL.absoluteString.base64Encoded() ?? ""
    }
    public let title: String
    public let webURL: URL
    public let posterURL: URL
    public let type: MediaContentType
    public let provider: ProviderType?

    public init(title: String, webURL: URL, posterURL: URL, type: MediaContent.MediaContentType, provider: LocalProvider? = nil) {
        self.title = title
        self.webURL = webURL
        self.posterURL = posterURL
        self.type = type
        if let provider {
            self.provider = ProviderType(provider)
        } else {
            self.provider = nil
        }
    }
    public init(title: String, webURL: URL, posterURL: URL, type: MediaContent.MediaContentType, provider: ProviderType? = nil) {
        self.title = title
        self.webURL = webURL
        self.posterURL = posterURL
        self.type = type
        self.provider = provider
    }

    enum CodingKeys: CodingKey {
        case id
        case title
        case webURL
        case posterURL
        case type
        case provider
    }

    public init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<MediaContent.CodingKeys> = try decoder.container(keyedBy: MediaContent.CodingKeys.self)

        self.title = try container.decode(String.self, forKey: MediaContent.CodingKeys.title)
        self.webURL = try container.decode(URL.self, forKey: MediaContent.CodingKeys.webURL)
        self.posterURL = try container.decode(URL.self, forKey: MediaContent.CodingKeys.posterURL)
        self.type = try container.decode(MediaContent.MediaContentType.self, forKey: MediaContent.CodingKeys.type)
        self.provider = try container.decodeIfPresent(ProviderType.self, forKey: MediaContent.CodingKeys.provider)

    }

    public func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<MediaContent.CodingKeys> = encoder.container(keyedBy: MediaContent.CodingKeys.self)
        try container.encode(self.id, forKey: MediaContent.CodingKeys.id)
        try container.encode(self.title, forKey: MediaContent.CodingKeys.title)
        try container.encode(self.webURL, forKey: MediaContent.CodingKeys.webURL)
        try container.encode(self.posterURL, forKey: MediaContent.CodingKeys.posterURL)
        try container.encode(self.type, forKey: MediaContent.CodingKeys.type)
        try container.encodeIfPresent(self.provider, forKey: MediaContent.CodingKeys.provider)
    }
}

extension MediaContent {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.title < rhs.title
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public var deeplink: URL? {
        guard  let data = try? JSONEncoder().encode(self),
               let content = String(data: data, encoding: .utf8)?.base64Encoded(),
               let url = URL(string: "streamer://details?content=\(content)") else {
            return nil
        }
        return url
    }

}

public extension MediaContent {
    init(tvShow: TVshow, provider: ProviderType? = nil) {
        self.title = tvShow.title
        self.webURL = tvShow.webURL
        self.posterURL = tvShow.posterURL
        self.type = .tvShow
        self.provider = provider
    }

    init(movie: Movie, provider: ProviderType? = nil) {
        self.title = movie.title
        self.webURL = movie.webURL
        self.posterURL = movie.posterURL
        self.type = .movie
        self.provider = provider
    }

}
