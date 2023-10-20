import Foundation
import SwiftSoup

struct PutlockerResolver: Resolver {
    let name = "PutLocker"

    static let domains: [String] = ["putlocker.vip"]
    private let baseURL: URL = URL(staticString: "https://ww7.putlocker.vip/")

    enum PutlockerResolverError: Error {
        case urlNotValid
    }
    func canHandle(url: URL) -> Bool {
        Self.domains.firstIndex(of: url.host!) != nil || url.host?.contains("putlocker") == true
    }

    let headers = [
        "Host": "ww7.putlocker.vip",
        "Connection": "keep-alive",
        "sec-ch-ua": "\"Not.A/Brand\";v=\"8\", \"Chromium\";v=\"114\", \"Google Chrome\";v=\"114\"",
        "Accept": "application/json, text/javascript, */*; q=0.01",
        "DNT": "1",
        "X-Requested-With": "XMLHttpRequest",
        "sec-ch-ua-mobile": "?0",
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36",
        "sec-ch-ua-platform": "\"macOS\"",
        "Sec-Fetch-Site": "same-origin",
        "Sec-Fetch-Mode": "cors",
        "Sec-Fetch-Dest": "empty",
        "Referer": "https://ww7.putlocker.vip/film/wham-98023/watching.html",
        "Accept-Language": "en-US,en;q=0.9,ar;q=0.8",
        "Cookie": "subscribe=1"
    ]
    func getMediaURL(url: URL) async throws -> [Stream] {
        // https://ww7.putlocker.vip/ajax/movie/episode/server/sources/317266515359462f5467784579326b7964746d71585a344c5456425a35692b347536415872645350456c464c4c35576d6f6b73756c496671556b454c423038564c36544e376f494f4530564d4b416455323056666c673d3d407c4035303035355f305f31

        if url.absoluteString.contains("/season/episodes") {
            let movieEpisodesURL = baseURL.appendingPathComponent("ajax/movie/episode/servers").appendingPathComponent(url.lastPathComponent)
            let data = try await Utilities.requestData(url: movieEpisodesURL)
            let serversContent = try JSONDecoder().decode(HTMLResponse.self, from: data)

            let serversDocument = try SwiftSoup.parse(serversContent.html)
            let rows: Elements = try serversDocument.select(".nav-item a")
            return try await rows.array().map { row -> URL in
                let eposideNumber: String = try row.attr("data-id")
                // https://ww7.putlocker.vip/ajax/movie/episode/server/sources/304a594956677552656b7a744b447342434866727649575671764b6632663851424167377354624d6167383d_1
                let sourceURL = baseURL.appendingPathComponent("ajax/movie/episode/server/sources").appendingPathComponent(eposideNumber + "_1")
                return sourceURL
            }
            .concurrentMap {
                return try? await HostsResolver.resolveURL(url: $0)
            }
            .compactMap { $0 }
            .flatMap { $0 }

        } else {
            let data = try await Utilities.requestData(url: url, extraHeaders: headers)
            let content = try JSONDecoder().decode(Response.self, from: data)
            return try await HostsResolver.resolveURL(url: content.src)
        }
    }

    struct Response: Codable {
        let status: Bool
        let src: URL
    }

    struct HTMLResponse: Codable {
        let status: Bool
        let html: String
    }

}
