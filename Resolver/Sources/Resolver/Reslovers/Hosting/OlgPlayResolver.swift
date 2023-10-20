import Foundation
import SwiftSoup

struct OlgPlayResolver: Resolver {
    let name = "Olgply"
    static let domains: [String] = ["olgply.xyz"]

    enum OlgPlayResolverError: Error {
        case regxValueNotFound
        case urlNotValid

    }

    var resolverURL: URL {
        if let path = UserDefaults.standard.string(forKey: "olgplay_Resolver_url"), let url = URL(string: path) {
            return url
        } else {
            return URL(staticString: "https://google.com")
        }
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let info = url.absoluteString.replacingOccurrences(of: "https://", with: "")
        let eURL = resolverURL.appending("url", value: info.encodeURIComponent())
        let encodedPath = try await Utilities.downloadPage(url: eURL)
        let encodedURL = try URL(encodedPath)
        return [.init(Resolver: "OlgPlay", streamURL: encodedURL)]
    }

}
