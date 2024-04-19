import Foundation
import SwiftyPyString

struct MyCloudResolver: Resolver {
    let name = "Mcloud"

    static let domains: [String] = [
        "mcloud.to",
        "mcloud.bz"
    ]

    @EnviromentValue(key: "mycloud_keys_url", defaultValue: URL(staticString: "https://google.com"))
    var keysURL: URL

    func canHandle(url: URL) -> Bool {
        Self.domains.firstIndex(of: url.host!) != nil || url.host?.contains("vizcloud") == true
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        var url = url.removing("sub.info")
        let info = url.absoluteString
            .replacingOccurrences(of: "https://", with: "")
        let eURL = keysURL.appending("url", value: info.encodeURIComponent())
        let encodedPath = try await Utilities.downloadPage(url: eURL)
        let encodedURL = try URL(encodedPath)
        let headers = [
            "User-Agent": Constants.userAgent,
            "Referer": url.absoluteString,
            "origin": url.absoluteString,
            "content-type": "application/json",
            "X-Requested-With": "XMLHttpRequest",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Site": "same-origin"
        ]

        do {
            let data = try await Utilities.requestData(url: encodedURL, extraHeaders: headers)

            let content = try JSONDecoder().decode(Response.self, from: data)
            return content.result.sources.compactMap {
                Stream(Resolver: "VizCloud", streamURL: $0.file, quality: .unknown)
            }
        } catch {
            print(error)
            throw error
        }

    }
    struct Response: Codable {
        let status: Int
        let result: Media
    }

    // MARK: - Media
    struct Media: Codable {
        let sources: [Source]
    }

    // MARK: - Source
    struct Source: Codable {
        let file: URL
    }
}
