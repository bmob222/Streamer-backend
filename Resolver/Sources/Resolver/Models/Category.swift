import Foundation

public struct Category: Codable, Comparable, Identifiable, Hashable {
    public var id: Int
    public let name: String
    public let poster: URL?
    public let url: URL?

    public init(id: Int, name: String, poster: URL? = nil, url: URL? = nil) {
        self.id = id
        self.name = name
        self.poster = poster
        self.url = url
    }

    public static func < (lhs: Category, rhs: Category) -> Bool {
        lhs.id < rhs.id
    }

}
