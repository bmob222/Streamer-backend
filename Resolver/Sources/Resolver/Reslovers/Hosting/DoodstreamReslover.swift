import Foundation
import SwiftSoup

struct DoodstreamResolver: Resolver {
    let name = "DoodStream"
    static let domains: [String] = [
        "doodstream.com",
        "dood.pm",
        "dood.ws",
        "dood.wf",
        "dood.cx",
        "dood.sh",
        "dood.watch",
        "dood.to",
        "dood.so",
        "dood.la",
        "dood.re",
        "dood.yt",
        "dooood.com",
        "doods.pro",
        "ds2video.com",
        "d0000d.com",
        "d0o0d.com",
        "do0od.com",
        "do0od.com",
        "dooood.com",
        "doods.pro",
        "ds2video.com",
        "doodstream.com",
        "dood.pm",
        "dood.ws",
        "dood.wf",
        "dood.cx",
        "dood.sh",
        "dood.watch",
        "dood.to",
        "dood.so",
        "dood.la",
        "dood.re",
        "dood.yt",
        "ds2play.com",
        "dooood.com",
        "doods.pro",
        "ds2video.com",
        "d0000d.com",
        "do0od.com",
        "d0ood.com",
        "dood.watch",
        "doodstream.com",
        "dood.to",
        "dood.so",
        "dood.cx",
        "dood.la",
        "dood.ws",
        "dood.sh",
        "doodstream.co",
        "d000d.com"
    ]

    enum DoodstreamResolverrError: Error {
        case regxValueNotFound
        case urlNotValid

    }
    func getMediaURL(url: URL) async throws -> [Stream] {
       try await getMediaURL(url: url, tryNumber: 0)
    }

    func getMediaURL(url: URL, tryNumber: Int = 0) async throws -> [Stream] {
        var url = url
        if url.absoluteString.contains("/d/"), let eurl = URL(string: url.absoluteString.replacingOccurrences(of: "/d/", with: "/e/")) {
            url = eurl
        }
        url = try await Utilities.getRedirect(url: url)
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)

        let script = try document.select("script").array().filter {
            try $0.html().contains("pass_md5")
        }.first?.html() ?? ""

        guard let md5UrlString = script.matches(for: #"\$\.get\('(\/pass_md5[^']+)"#).first  else {
            if content.contains("video you are looking for is not found") {
                throw DoodstreamResolverrError.urlNotValid
            } else {
                if tryNumber < 4 {
                    return try await getMediaURL(url: url, tryNumber: (tryNumber + 1) )
                } else {
                    throw DoodstreamResolverrError.regxValueNotFound
                }
            }
        }

        guard let md5URL = URL(string: "https://" + (url.host ?? "") + md5UrlString) else {
            throw DoodstreamResolverrError.urlNotValid
        }
        let md5Token = md5URL.lastPathComponent
        let responseContent = try await Utilities.downloadPage(url: md5URL)
        let randomLetters = randomString(length: 10)
        let dateString = String(Date().timeIntervalSince1970)
        let directVideoURLString = "\(responseContent + randomLetters)?token=\(md5Token)&expiry=\(dateString)"
        guard let directVideoURL = URL(string: directVideoURLString) else {
            throw DoodstreamResolverrError.urlNotValid
        }

        let headers = [
            "Host": directVideoURL.host ?? "",
            "Connection": "keep-alive",
            "sec-ch-ua": "\"Not_A Brand\";v=\"8\", \"Chromium\";v=\"120\", \"Google Chrome\";v=\"120\"",
            "DNT": "1",
            "sec-ch-ua-mobile": "?0",
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "sec-ch-ua-platform": "\"macOS\"",
            "Accept": "*/*",
            "Sec-Fetch-Site": "cross-site",
            "Sec-Fetch-Mode": "no-cors",
            "Sec-Fetch-Dest": "video",
            "Referer": "https://" + (url.host ?? "") + "/",
            "Accept-Language": "en-US,en;q=0.9,ar;q=0.8",
            "Pragma": "no-cache",
            "Cache-Control": "no-cache"
        ]

        return [.init(Resolver: "DoodStream", streamURL: directVideoURL, headers: headers)]
    }

}
