import Foundation
import SwiftSoup

struct StremifyReslover: Resolver {
    let name = "Stremify"
    static let domains: [String] = ["stremify.app"]
    
    func getMediaURL(url: URL) async throws -> [Stream] {
        
        let data = try await Utilities.requestData(url: url)
        let response = try JSONDecoder().decode(Superflix.self, from: data)
        
        return try await response.streams.concurrentMap { stream -> [Stream] in
            if stream.resolved == true {
                return [
                    Stream(
                        Resolver: stream.name,
                        description: stream.title,
                        streamURL: stream.url,
                        quality: Quality(quality: stream.title)
                    )
                ]
            }
            guard let resloved = try? await HostsResolver.resolveURL(url: stream.url) else {
                return []
            }
            return resloved.map {
                return  Stream(
                    Resolver: stream.name,
                    description: stream.title,
                    streamURL: $0.streamURL,
                    quality: $0.quality
                )
            }
            
        }
        .compactMap{ $0 }
        .flatMap { $0 }
    }
    
    // MARK: - Superflix
    struct Superflix: Decodable {
        @FailableDecodableArray var streams: [SuperFlixStream]
        
        enum CodingKeys: String, CodingKey {
            case streams
        }
    }
    
    // MARK: - Stream
    struct SuperFlixStream: Codable {
        let name: String
        let url: URL
        let title: String
        let resolved: Bool?
        
        enum CodingKeys: String, CodingKey {
            case name
            case url
            case title
            case resolved
        }
    }
}
