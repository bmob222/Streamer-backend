import Foundation
import SwiftSoup

struct EmpireResolver: Resolver {
    let name = "Empire"
    static let domains: [String] = ["empire-stream.net"]
    private let baseURL: URL = URL(string: "https://empire-stream.net/")!

    enum EmpireResolverError: Error {
        case urlNotValid
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let headers = [
            "Host": "empire-stream.net",
            "Sec-Fetch-Site": "same-origin",
            "Connection": "keep-alive",
            "Sec-Fetch-Mode": "navigate",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5.1 Safari/605.1.15",
            "Referer": url.absoluteString,
            "Sec-Fetch-Dest": "iframe"
        ]
        let content = try await Utilities.downloadPage(url: url, extraHeaders: headers)
        let document = try SwiftSoup.parse(content)

        let script = try document.select("script").filter {
            try $0.html().contains("window.location.href")
        }.first?.html() ?? ""

        guard var link = Utilities.extractURLs(content: script).first else {
            throw EmpireResolverError.urlNotValid
        }

        link = link.appending(["type": url.lastPathComponent])
        return try await HostsResolver.resolveURL(url: link)
    }
}
