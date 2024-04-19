import Foundation
import SwiftSoup
// https://sendvid.com/embed/fkl5fm0a
struct SendVidReslover: Resolver {
    let name = "SendVid"
    static let domains: [String] = ["sendvid.com"]

    enum SendVidResloverError: Error {
        case videoNotFound
    }
    func getMediaURL(url: URL) async throws -> [Stream] {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)
        let script = try pageDocument.select("script").filter {
            try $0.html().contains("video_source")
        }.first?.html() ?? ""
        guard let path = Utilities.extractURLs(content: script).filter({ $0.pathExtension == "mp4"}).first else {
            throw SendVidResloverError.videoNotFound
        }
        return [
            .init(
                Resolver: self.name,
                streamURL: path
            )
        ]
    }

}
