import Foundation
import SwiftyPyString

struct MyCloudResolver: Resolver {
    let name = "Mcloud"

    static let domains: [String] = [
        "mcloud.to",
        "mcloud.bz",
        "mcloud2.to",
        "mzcloud.life"
    ]

    @EnviromentValue(key: "mycloud_keys_url", defaultValue: URL(staticString: "https://google.com"))
    var keysURL: URL

    func canHandle(url: URL) -> Bool {
        Self.domains.firstIndex(of: url.host!) != nil || url.host?.contains("vizcloud") == true
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let url = url.removing("sub.info")
        let info = url.absoluteString.replacingOccurrences(of: "https://", with: "")
        let eURL = keysURL.appendingPathComponent("mcloud").appending("url", value: info.encodeURIComponent())

        do {

            let data = try await Utilities.requestData(url: eURL)
            let content = try JSONDecoder().decode(Response.self, from: data)
            return [
                Stream(Resolver: "Mcloud", streamURL: content.source)
            ]
        } catch {
            print(error)
            throw error
        }

    }
    struct Response: Codable {
        let source: URL
    }
}
