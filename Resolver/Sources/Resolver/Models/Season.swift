import Foundation

public struct Season: Codable, Identifiable, Comparable {

    public var id: Int {
        return seasonNumber
    }
    public let seasonNumber: Int
    public let webURL: URL
    public var episodes: [Episode]?

    public init(seasonNumber: Int, webURL: URL, episodes: [Episode]? = nil) {
        self.seasonNumber = seasonNumber
        self.webURL = webURL
        self.episodes = episodes
    }

    public static func < (lhs: Season, rhs: Season) -> Bool {
        lhs.seasonNumber < rhs.seasonNumber
    }

    public static func == (lhs: Season, rhs: Season) -> Bool {
        lhs.seasonNumber == rhs.seasonNumber
    }
}
