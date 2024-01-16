import Foundation
import SwiftSoup

struct CimaNowResolver: Resolver {
    let name = "CimaNow"

    static let domains: [String] = ["cimanow.cc"]
    private let directStreamDomains: [String] = ["cn.box.com", "cimanow.net", "uqload.co", "newcima.xyz", "cimanowtv.com"]

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

        let dstreams = rows.array().compactMap { row -> Stream? in
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

        do {
            let rrows: Elements = try document.select("#watch > li")
            let streams = try await rrows.array().concurrentMap { row -> [Stream] in
                guard let dataIndex = try? row.attr("data-index"), let dataId = try? row.attr("data-id") else { return [] }
                let aurl = try URL("https://cimanow.cc/wp-content/themes/Cima%20Now%20New/core.php?action=switch&index=\(dataIndex)&id=\(dataId)")
                let headers = [
                    "Host": "cimanow.cc",
                    "Connection": "keep-alive",
                    "sec-ch-ua": "\"Not_A Brand\";v=\"8\", \"Chromium\";v=\"120\", \"Google Chrome\";v=\"120\"",
                    "Accept": "*/*",
                    "DNT": "1",
                    "X-Requested-With": "XMLHttpRequest",
                    "sec-ch-ua-mobile": "?0",
                    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                    "sec-ch-ua-platform": "\"macOS\"",
                    "Sec-Fetch-Site": "same-origin",
                    "Sec-Fetch-Mode": "cors",
                    "Sec-Fetch-Dest": "empty",
                    "Referer": "\(url.absoluteString)",
                    "Accept-Language": "en-US,en;q=0.9,ar;q=0.8",
                    "Pragma": "no-cache",
                    "Cache-Control": "no-cache"
                ]

                let content = try await Utilities.downloadPage(url: aurl, extraHeaders: headers)
                let document = try SwiftSoup.parse(content)
                var streamPath = try document.select("iframe").attr("src")
                if !streamPath.contains("https:") {
                    streamPath = "https:" + streamPath
                }
                guard let streamURL = try? URL(streamPath) else { return [] }
                return (try? await HostsResolver.resolveURL(url: streamURL)) ?? []
            }.flatMap { $0 }

            return dstreams + streams
        } catch {
            return dstreams
        }
    }
}
