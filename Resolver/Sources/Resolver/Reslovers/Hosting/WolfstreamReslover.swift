import Foundation
import SwiftSoup
// https://wolfstream.tv/embed-tkvcklrugq6d.html
struct WolfstreamResolver: Resolver {
    let name = "Wolfstream"
    static let domains: [String] = ["wolfstream.tv"]

    enum WolfstreamResolverError: Error {
        case videoNotFound
    }
    func canHandle(url: URL) -> Bool {
        Self.domains.firstIndex(of: url.host!) != nil || url.host?.contains("wolfstream") == true
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let pageContent = try await Utilities.downloadPage(url: url, extraHeaders: ["Sec-Fetch-Dest": "iframe", "Referer": "https://filmpalast.to/"])
        let pageDocument = try SwiftSoup.parse(pageContent)
        let script = try pageDocument.select("script").filter {
            try $0.html().contains("jwplayer(\"vplayer\").setup")
        }.first?.html() ?? ""
        guard let path = Utilities.extractURLs(content: script.replacingOccurrences(of: "'", with: " '")).filter({ $0.pathExtension == "m3u8"}).first else {
            throw WolfstreamResolverError.videoNotFound
        }
        return [.init(Resolver: "WolfStream", streamURL: path)]
    }

}
