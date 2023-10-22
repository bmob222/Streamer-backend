import Foundation
import SwiftSoup

struct TheMovieArchiveReslover: Resolver {
    let name = "TheMovieArchive"
    
    static let domains: [String] = ["prod.omega.themoviearchive.site"]
    
    enum TwoEmbedResolverError: Error {
        case capchaKeyNotFound
    }
    
    func getMediaURL(url: URL) async throws -> [Stream] {
        let data = try await Utilities.requestData(url: url)
        let embed = try JSONCoder.decoder.decode(Response.self, from: data)
        let subtitles = embed.subtitles.compactMap { s -> Subtitle? in
            guard let url = URL(string: s.url),
                  let language = s.language.components(separatedBy: "-").first? .trimmingCharacters(in: .whitespaces) else { return nil}
            return Subtitle(url: url, language: .init(rawValue: language) ?? .unknown)
        }
        return embed.sources.flatMap {
            $0.sources
        }
        .compactMap{
            guard let url = URL(string: $0.url) else { return nil}
            
            return Stream(
                Resolver: "TheMovieArchive",
                streamURL: url,
                quality: .init(quality: $0.quality),
                subtitles: subtitles
            )
        }
    }
    
    // MARK: - Response
    struct Response: Codable {
        let sources: [ResponseSource]
        let subtitles: [MSubtitle]
        
        enum CodingKeys: String, CodingKey {
            case sources = "sources"
            case subtitles = "subtitles"
        }
    }
    
    // MARK: - ResponseSource
    struct ResponseSource: Codable {
        let label: String
        let sources: [SourceSource]
        
        enum CodingKeys: String, CodingKey {
            case label = "label"
            case sources = "sources"
        }
    }
    
    // MARK: - SourceSource
    struct SourceSource: Codable {
        let quality: String
        let url: String
        
        enum CodingKeys: String, CodingKey {
            case quality = "quality"
            case url = "url"
        }
    }
    
    // MARK: - Subtitle
    struct MSubtitle: Codable {
        let language: String
        let url: String
    }
    
}
