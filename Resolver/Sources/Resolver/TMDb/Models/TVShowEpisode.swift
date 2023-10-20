import Foundation

/// A TV show episode.
public struct TVShowEpisode: Identifiable, Decodable, Equatable, Hashable, StillURLProviding {

    /// TV show episode identifier.
    public let id: Int
    /// TV show episode name.
    public let name: String
    /// TV show episode number.
    public let episodeNumber: Int
    /// TV show episode season number.
    public let seasonNumber: Int
    /// TV show episode overview.
    public let overview: String?
    /// TV show episode production code.
    public let productionCode: String?
    /// TV show episode still image path.
    public let stillPath: URL?
    /// TV show episode crew.
    public let crew: [CrewMember]?
    /// TV show episode guest cast members.
    public let guestStars: [CastMember]?
    /// Average vote score.
    public let voteAverage: Double?
    /// Number of votes.
    public let voteCount: Int?

    public let airDateString: String?

    public var airDate: Date? {
        guard let airDateString = airDateString else {
            return nil
        }

        return DateFormatter.theMovieDatabase.date(from: airDateString)
    }

    /// Creates a new `TVShowEpisode`.
    ///
    /// - Parameters:
    ///    - id: TV show episode identifier.
    ///    - name: TV show episode name.
    ///    - episodeNumber: TV show episode number.
    ///    - seasonNumber: TV show episode season number.
    ///    - overview: TV show episode overview.
    ///    - airDate: TV show episode air date.
    ///    - productionCode: TV show episode production code.
    ///    - stillPath: TV show episode still image path.
    ///    - crew: TV show episode crew.
    ///    - guestStars: TV show episode guest cast members.
    ///    - voteAverage: Average vote score.
    ///    - voteCount: Number of votes.
    public init(id: Int, name: String, episodeNumber: Int, seasonNumber: Int, overview: String? = nil,
                productionCode: String? = nil, stillPath: URL? = nil,
                crew: [CrewMember]? = nil, guestStars: [CastMember]? = nil, voteAverage: Double? = nil,
                voteCount: Int? = nil, airdate: String? = nil) {
        self.id = id
        self.name = name
        self.episodeNumber = episodeNumber
        self.seasonNumber = seasonNumber
        self.overview = overview
        self.productionCode = productionCode
        self.stillPath = stillPath
        self.crew = crew
        self.guestStars = guestStars
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.airDateString = airdate
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case episodeNumber
        case seasonNumber
        case overview
        case productionCode
        case stillPath
        case crew
        case guestStars
        case voteAverage
        case voteCount
        case airDateString = "airDate"
    }

    public init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<TVShowEpisode.CodingKeys> = try decoder.container(keyedBy: TVShowEpisode.CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: TVShowEpisode.CodingKeys.id)
        self.name = try container.decode(String.self, forKey: TVShowEpisode.CodingKeys.name)
        self.episodeNumber = try container.decode(Int.self, forKey: TVShowEpisode.CodingKeys.episodeNumber)
        self.seasonNumber = try container.decode(Int.self, forKey: TVShowEpisode.CodingKeys.seasonNumber)
        self.overview = try container.decodeIfPresent(String.self, forKey: TVShowEpisode.CodingKeys.overview)
        self.productionCode = try container.decodeIfPresent(String.self, forKey: TVShowEpisode.CodingKeys.productionCode)
        self.stillPath = try container.decodeIfPresent(URL.self, forKey: TVShowEpisode.CodingKeys.stillPath)
        self.crew = try container.decodeIfPresent([CrewMember].self, forKey: TVShowEpisode.CodingKeys.crew)
        self.guestStars = try container.decodeIfPresent([CastMember].self, forKey: TVShowEpisode.CodingKeys.guestStars)
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: TVShowEpisode.CodingKeys.voteAverage)
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: TVShowEpisode.CodingKeys.voteCount)
        self.airDateString = try container.decodeIfPresent(String.self, forKey: TVShowEpisode.CodingKeys.airDateString)

    }

}
