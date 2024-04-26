import Foundation
import SwiftyPyString
 
struct VidPlayReslover: Resolver {
    let name = "VidPlayer"

    static let domains: [String] = [
        "vidplay.online",
        "vidplay.site",
        "mwvn.vizcloud.info",
        "vidstream.pro",
        "vidstreamz.online",
        "vizcloud.cloud",
        "vizcloud.digital",
        "vizcloud.info",
        "vizcloud.live",
        "vizcloud.online",
        "vizcloud.xyz",
        "vizcloud2.online",
        "vizcloud2.ru",
        "vid41c.site",
        "vidstream.pro",
        "vidstreamz.online",
        "vizcloud.ru",
        "vizcloud2.ru",
        "vizcloud2.online",
        "vizcloud.online",
        "vizstream.ru",
        "vizcloud.xyz",
        "vizcloud.live",
        "vizcloud.digital",
        "vizcloud.cloud",
        "vizcloud.store",
        "vizcloud.site",
        "vizcloud.co",
        "vidplay.site",
        "vidplay.lol",
        "vidplay.online",
        "a9bfed0818.nl",
        "vid142.site"
    ]

    @EnviromentValue(key: "mycloud_keys_url", defaultValue: URL(staticString: "https://google.com"))
    var keysURL: URL

    func canHandle(url: URL) -> Bool {
        Self.domains.firstIndex(of: url.host!) != nil || url.host?.contains("vidplay") == true
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let url = url.removing("sub.info")
        let info = url.absoluteString.replacingOccurrences(of: "https://", with: "")
        let eURL = keysURL.appendingPathComponent("vidplay").appending("url", value: info.encodeURIComponent())

        do {

            let data = try await Utilities.requestData(url: eURL)
            let content = try JSONDecoder().decode(Response.self, from: data)
            return [
                Stream(Resolver: "VidPlayer", streamURL: content.source)
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
