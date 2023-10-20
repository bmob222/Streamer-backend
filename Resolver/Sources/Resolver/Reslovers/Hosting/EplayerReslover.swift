import Foundation
import SwiftSoup

struct EplayerResolver: Resolver {
    let name = "Eplayer"
    static let domains: [String] = ["e-player-stream.app"]
    private let baseURL: URL = URL(staticString: "https://e-player-stream.app")

    enum AnimetvStreamResolverError: Error {
        case idNotFound
    }
    func getMediaURL(url: URL) async throws -> [Stream] {

        let type = url.queryParameters?["type"] ?? ""
        let id = url.lastPathComponent
        let playerURL = baseURL.appendingPathComponent("player").appendingPathComponent("index.php").appending([
            "data": id,
            "do": "getVideo"
        ])

        let headers = [
            "Host": "e-player-stream.app",
            "Connection": "keep-alive",
            "sec-ch-ua": "\"Not/A)Brand\";v=\"99\", \"Google Chrome\";v=\"115\", \"Chromium\";v=\"115\"",
            "DNT": "1",
            "sec-ch-ua-mobile": "?0",
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36",
            "Accept": "*/*",
            "sec-ch-ua-platform": "\"macOS\"",
            "Sec-Fetch-Site": "same-origin",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Dest": "empty",
            "Accept-Language": "en-US,en;q=0.9",
            "X-Requested-With": "XMLHttpRequest",
            "Origin": baseURL.absoluteString,
            "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
            "Referer": "",
            "authority": "",
            "Cookie": ""

        ]

        let data = "hash=\(id)&r=https%3A%2F%2Fempire-streaming.app%2F".data(using: .utf8)
        let videoData = try await Utilities.requestData(url: playerURL, httpMethod: "POST", data: data, extraHeaders: headers)
        let response = try JSONDecoder().decode(Response.self, from: videoData)

        return [
            .init(
                Resolver: "E-Player \(type)",
                streamURL: response.videoSource ?? response.securedLink ?? baseURL,
                headers: [
                    "Origin": baseURL.absoluteString,
                    "X-Requested-With": "XMLHttpRequest",
                    "Referer": baseURL.absoluteString
                ]
            )
        ]
    }

    struct Response: Decodable {
        let videoSource: URL?
        let securedLink: URL?
    }

}
