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
        "ds2play.com",
        "dooood.com",
        "doods.pro",
        "ds2video.com"
    ]

    enum DoodstreamResolverrError: Error {
        case regxValueNotFound
        case urlNotValid

    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        var url = url
        if url.absoluteString.contains("/d/"), let eurl = URL(string: url.absoluteString.replacingOccurrences(of: "/d/", with: "/e/")) {
            url = eurl
        }

        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let script = try document.select("script").array().filter {
            try $0.html().contains("pass_md5")
        }.first?.html() ?? ""
        guard let md5UrlString = script.matches(for: #"\$\.get\('(\/pass_md5[^']+)"#).first  else {
            throw DoodstreamResolverrError.regxValueNotFound
        }
        let host = url.host == "s2.protectlink.stream" ? "dood.to" :  url.host

        guard let md5URL = URL(string: "https://" + (host ?? "") + md5UrlString) else {
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
        return [.init(Resolver: "DoodStream", streamURL: directVideoURL)]
    }

}
