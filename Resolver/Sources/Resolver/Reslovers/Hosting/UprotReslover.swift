import Foundation
import SwiftSoup

struct UprotReslover: Resolver {
    let name = "Maxstream"
    static let domains: [String] = ["maxstream.video", "uprot.net"]

    enum UprotResloverError: Error {
        case videoNotFound
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)
        let path = try pageDocument.select("a").array().map { try $0.attr("href")}.filter { $0.contains("maxstream")}.first ?? ""
        let orgStreamUrl = try URL(path)

        let maxStreamUrl = try await Utilities.getRedirect(url: orgStreamUrl)

        let streamContent = try await Utilities.downloadPage(url: maxStreamUrl)
        let streamDocument = try SwiftSoup.parse(streamContent)

        let script = try streamDocument.select("script").array().filter {
            try $0.html().contains("videojs")
        }.first?.html() ?? ""
        guard let path = Utilities.extractURLs(content: script).filter({ $0.pathExtension == "m3u8"}).first else {
            throw UprotResloverError.videoNotFound
        }
        return [.init(Resolver: "Maxstream", streamURL: path)]
    }

}
