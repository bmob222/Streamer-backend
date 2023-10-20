import Foundation
import SwiftSoup

struct VoeResolver: Resolver {
    let name = "Voe"
    static let domains: [String] = ["voe.sx"]

    enum VoeResolverError: Error {
        case regxValueNotFound
        case urlNotValid

    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        // https://voe.sx/e/cresjbbehpjd
        // https://voe.sx/cresjbbehpjd
        var url = url
        if !url.absoluteString.contains("/e/") {
            url = URL(staticString: "https://voe.sx/e/").appendingPathComponent(url.lastPathComponent)
        }
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)
        let script = try pageDocument.select("script").filter {
            try $0.html().contains("'hls':")
        }.first?.html() ?? ""
        guard let path = Utilities.extractURLs(content: script).filter({ $0.pathExtension == "m3u8"}).first else {
            throw VoeResolverError.urlNotValid
        }
        return [.init(Resolver: "Voe", streamURL: path)]
    }

}
