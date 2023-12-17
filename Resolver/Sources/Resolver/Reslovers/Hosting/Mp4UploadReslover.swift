import Foundation
import SwiftSoup
// https://mwish.pro/e/etv05g2bjdyr?caption_1=https://sub.membed.net/sub/star-wars-episode-v-the-empire-strikes-back-stj/star-wars-episode-v-the-empire-strikes-back-stj.vtt&sub_1=English
struct Mp4UploadReslover: Resolver {
    let name = "StreamWish"
    static let domains: [String] = [
        "mp4upload.com",
        "www.mp4upload.com"
    ]

    enum WolfstreamResolverError: Error {
        case videoNotFound
    }
    func getMediaURL(url: URL) async throws -> [Stream] {

        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)

        let script = try pageDocument.select("script").filter {
            try $0.html().contains("player.src")
        }.first?.html() ?? ""
        guard let path = Utilities.extractURLs(content: script.replacingOccurrences(of: "'", with: " '")).filter({ $0.pathExtension == "mp4"}).first else {
            throw WolfstreamResolverError.videoNotFound
        }
        return [
            .init(
                Resolver: "MP4upload",
                streamURL: path,
                headers: ["Origin": "https://www.mp4upload.com/", "Referer": "https://www.mp4upload.com/"]
            )
        ]
    }

}
