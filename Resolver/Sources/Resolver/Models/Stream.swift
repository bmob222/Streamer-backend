import Foundation

public struct Stream: Codable, Hashable, Identifiable, Comparable {
    public enum StreamType: Codable {
        case direct
        case realdebrid(Int)

    }
    public var id: String {
        return streamURL.absoluteString
    }
    public let Resolver: String
    public let streamURL: URL
    public let quality: Quality
    public var subtitles: [Subtitle]
    public let headers: [String: String]?
    public let type: StreamType

    public init(
        Resolver: String,
        streamURL: URL,
        quality: Quality? = nil,
        headers: [String: String]? = nil,
        subtitles: [Subtitle] = [],
        type: StreamType = .direct
    ) {
        self.Resolver = Resolver
        self.streamURL = streamURL
        self.quality = quality ?? Quality(url: streamURL)
        self.headers = headers
        self.subtitles = subtitles
        self.type = type
    }

    public static func <(lhs: Stream, rhs: Stream) -> Bool {
        lhs.quality > rhs.quality
    }

    public init(stream: Stream, subtitles: [Subtitle]) {
        self.streamURL = stream.streamURL
        self.Resolver = stream.Resolver
        self.quality = stream.quality
        self.headers = stream.headers
        self.subtitles = subtitles
        self.type = .direct
    }
    public init(stream: Stream, quality: Quality? = nil ) {
        self.streamURL = stream.streamURL
        self.Resolver = stream.Resolver
        self.quality = quality ?? stream.quality
        self.headers = stream.headers
        self.subtitles = stream.subtitles
        self.type = .direct
    }

    public var canBePlayedOnVlc: Bool {
        return (headers?.isEmpty ?? true) && streamURL.pathExtension != "m3u8" && streamURL.pathExtension != "m3u"
    }

    public static func == (lhs: Stream, rhs: Stream) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(Resolver)
        hasher.combine(streamURL)
        hasher.combine(quality)
        hasher.combine(headers)

    }

    enum CodingKeys: CodingKey {
        case Resolver
        case streamURL
        case quality
        case subtitles
        case headers
        case type
    }

    public init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<Stream.CodingKeys> = try decoder.container(keyedBy: Stream.CodingKeys.self)

        self.Resolver = try container.decode(String.self, forKey: Stream.CodingKeys.Resolver)
        self.streamURL = try container.decode(URL.self, forKey: Stream.CodingKeys.streamURL)
        self.quality = try container.decode(Quality.self, forKey: Stream.CodingKeys.quality)
        self.subtitles = try container.decode([Subtitle].self, forKey: Stream.CodingKeys.subtitles)
        self.headers = try container.decodeIfPresent([String: String].self, forKey: Stream.CodingKeys.headers)
        self.type = .direct

    }

    public func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<Stream.CodingKeys> = encoder.container(keyedBy: Stream.CodingKeys.self)

        try container.encode(self.Resolver, forKey: Stream.CodingKeys.Resolver)
        try container.encode(self.streamURL, forKey: Stream.CodingKeys.streamURL)
        try container.encode(self.quality, forKey: Stream.CodingKeys.quality)
        try container.encode(self.subtitles, forKey: Stream.CodingKeys.subtitles)
        try container.encodeIfPresent(self.headers, forKey: Stream.CodingKeys.headers)
        try container.encode(self.type, forKey: Stream.CodingKeys.type)
    }
}

public enum Quality: String, CaseIterable, Comparable, Codable {
    case p360 = "360p"
    case p480 = "480p"
    case p720 = "720p"
    case p1080 = "1080p"
    case k4 = "4k"
    case auto
    case unknown
    case manual = "Manual"

    public var piroirty: Int {
        switch self {
        case .p360:
            return 2
        case .p480:
            return 3
        case .p720:
            return 4
        case .p1080:
            return 5
        case .k4:
            return 6
        case .auto:
            return 1
        case .unknown:
            return 0
        case .manual:
            return 0
        }
    }
    public var height: Int {
        switch self {
        case .p360:
            return 360
        case .p480:
            return 480
        case .p720:
            return 720
        case .p1080:
            return 1080
        case .k4:
            return 2160
        case .auto:
            return 1000000000
        case .unknown:
            return 0
        case .manual:
            return 1000000000
        }
    }

    public var localized: String {
        switch self {
        case .p360:
            return "360p"
        case .p480:
            return "480p"
        case .p720:
            return "720p"
        case .p1080:
            return "1080p"
        case .k4:
            return NSLocalizedString("Max", bundle: Bundle.main, comment: "")
        case .auto:
            return NSLocalizedString("Auto", bundle: Bundle.main, comment: "")
        case .unknown:
            return "Unknown"
        case .manual:
            return NSLocalizedString("Manual", bundle: Bundle.main, comment: "")
        }
    }

    public static var allCases: [Quality] {
        return  [.p360, .p480, .p720, .p1080, .k4, .manual]
    }

    public static func <(lhs: Quality, rhs: Quality) -> Bool {
        lhs.piroirty < rhs.piroirty
    }

    public init?(height: Int) {
        switch height {
        case _ where height >= Self.k4.height:
            self = .k4
        case _ where height >= Self.p1080.height:
            self = .p1080
        case _ where height >= Self.p720.height:
            self = .p720
        case _ where height >= Self.p480.height:
            self = .p480
        case _ where height >= Self.p360.height:
            self = .p360
        default:
            return nil
        }
    }

    public init(url: URL) {
        switch true {
        case url.absoluteString.contains("360"):
            self = .p360
        case url.absoluteString.contains("480"):
            self = .p480
        case url.absoluteString.contains("720"):
            self = .p720
        case url.absoluteString.contains("1080"):
            self = .p1080
        case url.absoluteString.lowercased().contains("4K".lowercased()):
            self = .k4
        case url.absoluteString.contains("auto"):
            self = .auto
        default:
            self = .unknown
        }
    }

    public init?(quality: String?) {
        switch true {
        case quality?.contains("360"):
            self = .p360
        case quality?.contains("480"):
            self = .p480
        case quality?.contains("720"):
            self = .p720
        case quality?.contains("1080"):
            self = .p1080
        case quality?.lowercased().contains("4K".lowercased()):
            self = .k4
        case quality?.contains("auto"):
            self = .auto
        default:
            return nil
        }
    }
}
