import Foundation
import SwiftSoup

class VidsrcResolver: Resolver {
    let name = "VidSRC"
    static let domains: [String] = ["v2.vidsrc.me"]
    let baseURL: URL = URL(staticString: "https://v2.vidsrc.me/srcrcp/")

    var timer: Timer?
    var setPassURL: URL?

    enum VidsrcResolverrError: Error {
        case videoNotFound

    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)
        // load other sources
        let sources =  try? await pageDocument.select(".source").array().asyncMap { source -> [Stream] in
            let hash = try source.attr("data-hash")
            let hashURL = self.baseURL.appendingPathComponent(hash)
            let (data, response) = try await Utilities.requestResponse(url: hashURL, extraHeaders: ["Referer": "https://rcp.vidsrc.me/"])
            if let redirectURL = response.url, !redirectURL.absoluteString.contains("vidsrc.stream") {
                return (try? await HostsResolver.resolveURL(url: redirectURL)) ?? []
            } else {
                let pageContent = String(data: data, encoding: .utf8) ?? ""
                let pageDocument = try SwiftSoup.parse(pageContent)
                let script = try pageDocument.select("script").array().filter {
                    try $0.html().contains("hls.loadSource")
                }.first?.html() ?? ""

                let allURLs = Utilities.extractURLs(content: script.replacingOccurrences(of: "\"//", with: "\"https://").replacingOccurrences(of: "'", with: " '"))
                guard let path = allURLs.filter({ $0.pathExtension == "m3u8"}).first else {
                    throw VidsrcResolverrError.videoNotFound
                }
                guard let setPathURL = allURLs.filter({ $0.absoluteString.contains("set_pass.php")}).first else {
                    throw VidsrcResolverrError.videoNotFound
                }
                self.setPassURL = setPathURL

                let headers = [
                    "Host": path.host ?? "",
                    "Connection": "keep-alive",
                    "sec-ch-ua": "\"Google Chrome\";v=\"107\", \"Chromium\";v=\"107\", \"Not=A?Brand\";v=\"24\"",
                    "DNT": "1",
                    "sec-ch-ua-mobile": "?0",
                    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36",
                    "sec-ch-ua-platform": "\"macOS\"",
                    "Accept": "*/*",
                    "Origin": "https://vidsrc.stream",
                    "Sec-Fetch-Site": "cross-site",
                    "Sec-Fetch-Mode": "cors",
                    "Sec-Fetch-Dest": "empty",
                    "Referer": "https://vidsrc.stream/",
                    "Accept-Language": "en-US,en;q=0.9,ar;q=0.8",
                    "sec-fetch-dest": "empty",
                    "sec-fetch-mode": "cors"

                ]
                return [.init(Resolver: "Vidsrc", streamURL: path, headers: headers)]
            }
        }
        .flatMap { $0 }

        return sources ?? []

    }
}
