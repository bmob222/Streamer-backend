import Foundation
import SwiftSoup

public struct Shahid4UReslover: Resolver {
    static var domains: [String] = ["shahee4u.cam"]
    
    var name: String = "Shahid4U"
    
    func getMediaURL(url: URL) async throws -> [Stream] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)

        let script = try document.select("script").filter {
            try $0.html().contains("let servers")
        }.first?.html() ?? ""

        let jsonString = script.replacingOccurrences(of: "let servers = JSON.parse('", with: "").replacingOccurrences(of: "');", with: "").components(separatedBy: "\n").first ?? ""
        let data = jsonString.data(using: .utf8)!
        let servers = try JSONDecoder().decode([ServerElement].self, from: data)    

        return try await servers.concurrentMap {
            return (try? await HostsResolver.resolveURL(url: $0.url)) ?? []
        }
        .flatMap{ $0 }
        
    }
    

    struct ServerElement: Codable {
        let id: Int
        let name: String
        let img: String
        let url: URL
        let rank: Int

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case img
            case url
            case rank
        }
    }

}
