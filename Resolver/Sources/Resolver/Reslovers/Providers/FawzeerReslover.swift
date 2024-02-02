import Foundation
import SwiftSoup

struct FawzeerResolver: Resolver {
    let name = "Fawzeer"
    static let domains: [String] = ["eldolary.com"]


    func getMediaURL(url: URL) async throws -> [Stream] {
        let content = try await Utilities.downloadPage(url: url)
        let url = try URL(content)
        return [Stream(Resolver: "Fawzeer", streamURL: url)]
    }

}
