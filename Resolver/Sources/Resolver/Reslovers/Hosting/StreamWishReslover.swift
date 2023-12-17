import Foundation
import SwiftSoup
// https://mwish.pro/e/etv05g2bjdyr?caption_1=https://sub.membed.net/sub/star-wars-episode-v-the-empire-strikes-back-stj/star-wars-episode-v-the-empire-strikes-back-stj.vtt&sub_1=English
struct StreamWishResolver: Resolver {
    let name = "StreamWish"
    static let domains: [String] = [
        "awish.pro",
        "streamwish.to",
        "mwish.pro",
        "ahvsh.com",
        "moviesm4u.com",
        "guccihide.com",
        "streamhide.to",
        "movhide.pro",
        "ztreamhub.com",
        "streamwish.com",
        "streamwish.to",
        "khadhnayad.sbs",
        "yadmalik.sbs",
        "hayaatieadhab.sbs",
        "kharabnahs.sbs",
        "atabkhha.sbs",
        "atabknha.sbs",
        "atabknhk.sbs",
        "atabknhs.sbs",
        "abkrzkr.sbs",
        "abkrzkz.sbs",
        "wishembed.pro",
        "mwish.pro",
        "strmwis.xyz",
        "dwish.pro",
        "vidmoviesb.xyz",
        "embedwish.com",
        "cilootv.store",
        "tuktukcinema.store",
        "doodporn.xyz",
        "ankrzkz.sbs",
        "volvovideo.top",
        "streamwish.site",
        "wishfast.top",
        "ankrznm.sbs",
        "sfastwish.com",
        "eghjrutf.sbs",
        "eghzrutw.sbs",
        "playembed.online",
        "egsyxurh.sbs",
        "egtpgrvh.sbs"
    ]

    enum WolfstreamResolverError: Error {
        case videoNotFound
    }
    func getMediaURL(url: URL) async throws -> [Stream] {

        var subtitles: [Subtitle] = []
        if let caption_1 = url.queryParameters?["caption_1"],
           let subtitleURL = URL(string: caption_1),
           let sub_1 = url.queryParameters?["sub_1"] {
            subtitles.append(Subtitle(url: subtitleURL, language: .init(rawValue: sub_1) ?? .unknown))
        }
        // caption_1=https://sub.membed.net/sub/star-wars-episode-v-the-empire-strikes-back-stj/star-wars-episode-v-the-empire-strikes-back-stj.vtt&sub_1=English
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)

        let script = try pageDocument.select("script").filter {
            try $0.html().contains("sources:")
        }.first?.html() ?? ""
        guard let path = Utilities.extractURLs(content: script.replacingOccurrences(of: "'", with: " '")).filter({ $0.pathExtension == "m3u8"}).first else {
            throw WolfstreamResolverError.videoNotFound
        }
        return [
            .init(
                Resolver: "StreamWish",
                streamURL: path,
                headers: ["Origin": "https://awish.pro", "Referer": "https://awish.pro/"],
                subtitles: subtitles
            )
        ]
    }

}
