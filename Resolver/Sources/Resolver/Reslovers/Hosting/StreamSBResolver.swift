import Foundation

import SwiftSoup

struct StreamSBResolver: Resolver {
    let name = "StreamSB"
    static let domains: [String] = [
        "sbfull.com",
        "sbplay2.xyz",
        "sbplay1.com",
        "sbplay2.com",
        "sbplay3.com",
        "cloudemb.com",
        "sbplay.org",
        "embedsb.com",
        "pelistop.co",
        "streamsb.net",
        "sbplay.one",
        "sbplay2.xyz",
        "sbnet.one",
        "vidgomunimesb.xyz",
        "sbasian.pro",
        "sbnet.one",
        "keephealth.info",
        "sbspeed.com",
        "streamsss.net",
        "sbflix.xyz",
        "vidgomunime.xyz",
        "sbthe.com",
        "ssbstream.net",
        "sbfull.com",
        "sbplay1.com",
        "sbplay2.com",
        "sbplay3.com",
        "cloudemb.com",
        "sbplay.org",
        "embedsb.com",
        "pelistop.co",
        "streamsb.net",
        "sbplay.one",
        "sbplay2.xyz",
        "sbbrisk.com",
        "sblongvu.com"
    ]

    enum StreamSBResolverError: Error {
        case urlNotValid
    }

    private func fixUrl(url: URL) -> String {
        let host = url.host!
        let sbUrl = "https://\(host)/375664356a494546326c4b797c7c6e756577776778623171737"
        let id = url.absoluteString.components(separatedBy: host)
            .last!
            .components(separatedBy: "/e/")
            .last!
            .components(separatedBy: "/embed-")
            .last!
            .components(separatedBy: "?")
            .first!
            .components(separatedBy: ".html")
            .first!
            .components(separatedBy: "/")
            .last!

        let hexBytes = Data(id.utf8).map { String(format: "%x", $0 ) }.joined()

        return sbUrl + "/625a364258615242766475327c7c\(hexBytes)7c7c4761574550654f7461566d347c7c73747265616d7362"
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        guard let sourceURL = URL(string: fixUrl(url: url)) else {
            throw StreamSBResolverError.urlNotValid
        }
        let requestHeaders = [
            "Host": url.host ?? "",
            "Connection": "keep-alive",
            "sec-ch-ua": "\"Google Chrome\";v=\"113\", \"Chromium\";v=\"113\", \"Not-A.Brand\";v=\"24\"",
            "Accept": "application/json, text/plain, */*",
            "watchsb": "sbstream",
            "DNT": "1",
            "sec-ch-ua-mobile": "?0",
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
            "sec-ch-ua-platform": "\"macOS\"",
            "Sec-Fetch-Site": "same-origin",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Dest": "empty",
            "Referer": url.absoluteString,
            "Accept-Language": "en-US,en;q=0.9,ar;q=0.8"
        ]

        let data = try await Utilities.requestData(url: sourceURL, extraHeaders: requestHeaders)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let streamData = try decoder.decode(StreamSBAPIResponse.self, from: data).streamData
        let headers = [
            "Referer": "https://\(url.host ?? "")/",
            "Connection": "keep-alive",
            "sec-ch-ua": "\"Google Chrome\";v=\"113\", \"Chromium\";v=\"113\", \"Not-A.Brand\";v=\"24\"",
            "DNT": "1",
            "sec-ch-ua-mobile": "?0",
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
            "sec-ch-ua-platform": "\"macOS\"",
            "Accept": "*/*",
            "Origin": "https://\(url.host ?? "")/",
            "Sec-Fetch-Site": "cross-site",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Dest": "empty",
            "Accept-Language": "en-US,en;q=0.9,ar;q=0.8"
        ]
        var streams: [Stream] = []
        streamData.file.map { streams.append(.init(Resolver: "StreamSB", streamURL: $0, headers: headers))}
        streamData.backup.map { streams.append(.init(Resolver: "StreamSB Backup", streamURL: $0, headers: headers))}
        return streams
    }

    private struct StreamSBAPIResponse: Codable {
        let streamData: StreamData
    }

    private struct StreamData: Codable {
        let file: URL?
        let backup: URL?
    }
}
