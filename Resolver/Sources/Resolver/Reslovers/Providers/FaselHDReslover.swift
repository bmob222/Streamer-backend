import Foundation
import SwiftSoup

struct FaselHDResolver: Resolver {
    let name = "FaselHD"
    static let domains: [String] = ["faselhd.express", "www.faselhd.express"]

    func canHandle(url: URL) -> Bool {
        Self.domains.firstIndex(of: url.host!) != nil || url.host?.contains("faselhd") == true
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let playerPath = try document.select("iframe[name=\"player_iframe\"]").attr("src").replacingOccurrences(of: " ", with: "")
        let playerURL = try URL(playerPath)
        var playerContent = try await Utilities.downloadPage(url: playerURL)
        playerContent = playerContent.adilbo_deobfescate()
        let playerDocument = try SwiftSoup.parse(playerContent)
        return try playerDocument.select("div.quality_change button.hd_btn").array().map { row in
            let streamPath = try row.attr("data-url")
            let streamURL = try URL(streamPath)
            return Stream(Resolver: "FaselHD", streamURL: streamURL)
        }
    }

}
