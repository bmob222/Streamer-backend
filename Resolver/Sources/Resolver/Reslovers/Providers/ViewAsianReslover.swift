import Foundation
import SwiftSoup

struct DramaCoolResolver: Resolver {
    let name = "DramaCool"
    static let domains: [String] = ["asianc.to", "dramacool.com.pa"]
    
    @EnviromentValue(key: "consumet_url", defaultValue: URL(staticString: "https://api.consumet.org"))
    private var consumetURL: URL
    
    enum FlixHQResolverError: Error {
        case idNotFound
    }
    func getMediaURL(url: URL) async throws -> [Stream] {
        
        guard let mediaId = url.queryParameters?["mediaId"], let episodeId = url.queryParameters?["episodeId"]  else {
            throw FlixHQResolverError.idNotFound
        }
        
        let watchURL = consumetURL.appendingPathComponent("movies/dramacool/watch")
            .appending("episodeId", value: episodeId)
            .appending("mediaId", value: mediaId)
        
        let data = try await Utilities.requestData(url: watchURL)
        let response = try JSONDecoder().decode(WatchResponse.self, from: data)
        
        return response.sources.map {
            Stream(
                Resolver: "DramaCool",
                streamURL: $0.url
            )
        }
    }
    
    // MARK: - WatchResponse
    struct WatchResponse: Codable, Equatable {
        let sources: [ConsumetSource]
    }
    
    // MARK: - Source
    struct ConsumetSource: Codable, Equatable {
        let url: URL
        let isM3U8: Bool
    }
    
}
