import Foundation
import SwiftSoup

struct OkruReslover: Resolver {
    let name = "OK.ru"
    static let domains: [String] = ["ok.ru"]

    enum OKVideo: Error {
        case videoNotFound
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
      // parse OKVideo and get the video URL
        let extraHeaders = [
            "User-Agent": "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36",
            "Referer": url.absoluteString
        ]
        let html = try await Utilities.downloadPage(url: url, extraHeaders: extraHeaders).htmlUnescape()

        guard let hlsManifestPath = html.matches(for: #"\\"hlsManifestUrl\\":\\"([^\"]*)\\","#)
            .first?
            .replacingOccurrences(of: "\\", with: "")
            .replacingOccurrences(of: "u0026", with: "&"),
               let hlsManifestURL = URL(string: hlsManifestPath) else {
            throw OKVideo.videoNotFound
        }
        return [
            Stream(
                Resolver: self.name,
                streamURL: hlsManifestURL,
                quality: .auto
            )
        ]

    }
}
