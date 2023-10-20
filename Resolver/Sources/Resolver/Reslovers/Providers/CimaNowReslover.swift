import Foundation
import SwiftSoup

struct CimaNowResolver: Resolver {
    let name = "CimaNow"

    static let domains: [String] = ["cimanow.cc"]
    private let directStreamDomains: [String] = ["cn.box.com", "cimanow.net", "uqload.co", "newcima.xyz"]

    func getMediaURL(url: URL) async throws -> [Stream] {

        let content = try await Utilities.requestCloudFlare(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select("#download > li > a")
        let headers = [
            "Accept": "*/*",
            "Accept-Language": "en-US,en;q=0.9,ar;q=0.8",
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "DNT": "1",
            "Pragma": "no-cache",
            "Range": "bytes=393216-",
            "Referer": url.absoluteString,
            "Sec-Fetch-Dest": "video",
            "Sec-Fetch-Mode": "no-cors",
            "Sec-Fetch-Site": "same-origin",
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36",
            "sec-ch-ua": "\"Not.A/Brand\";v=\"8\", \"Chromium\";v=\"114\", \"Google Chrome\";v=\"114\"",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": "\"macOS\""

        ]
        return rows.array().compactMap { row -> Stream? in
            if let path = try? row.attr("href"), let url = URL(string: path) {
                let quality =  (try? row.text())
                return Stream(Resolver: url.host ?? "CimaNow", streamURL: url, quality: Quality(quality: quality), headers: headers)
            } else {
                return nil
            }
        }
        .filter { stream in
            return directStreamDomains.reduce(false) { partialResult, host in
                stream.streamURL.absoluteString.contains(host) || partialResult
            }
        }
    }
}
