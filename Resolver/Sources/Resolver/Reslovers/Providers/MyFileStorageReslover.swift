import Foundation
import SwiftSoup
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct MyFileStorageResolver: Resolver {
    let name = "MyFileStorage"
    static let domains: [String] = ["myfilestorage.xyz"]
    func getMediaURL(url: URL) async throws -> [Stream] {
        // https://myfilestorage.xyz/453395.mp4

        let (_, response) = try await Utilities.requestResponse(url: url, httpMethod: "HEAD", extraHeaders: ["Referer": "https://2now.tv/"])
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard statusCode == 200 else {
            return []
        }
        return[
            Stream(
                Resolver: "2now.tv",
                streamURL: .init(staticString: "https://www.dropbox.com/scl/fi/t6gyvfxwjckdbypuncbqy/1.m3u8?rlkey=apjz7cx74240c1udwimn2ve9i&dl=1"),
                quality: .p1080,
                headers: [
                    "authority": "myfilestorage.xyz",
                    "accept": "*/*",
                    "accept-language": "en-US,en;q=0.9,ar;q=0.8",
                    "cache-control": "no-cache",
                    "dnt": "1",
                    "pragma": "no-cache",
                    "referer": "https://2now.tv/",
                    "sec-ch-ua": "\"Not.A/Brand\";v=\"8\", \"Chromium\";v=\"114\", \"Google Chrome\";v=\"114\"",
                    "sec-ch-ua-mobile": "?0",
                    "sec-ch-ua-platform": "\"macOS\"",
                    "sec-fetch-dest": "video",
                    "sec-fetch-mode": "no-cors",
                    "sec-fetch-site": "cross-site",
                    "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"

                ]
            )
        ]

    }
}
